#!/usr/bin/env python3
"""Targeted static guards for the CodexBar macOS 12 compatibility lane.

The deployment-target build remains the authoritative availability check. This
scanner catches common regressions earlier and gives a focused diagnostic before
SwiftPM has to resolve or compile the full package.
"""

from __future__ import annotations

import argparse
import bisect
import re
import sys
import tempfile
from dataclasses import dataclass
from pathlib import Path
from typing import Iterable


MINIMUM_SWIFT_TOOLS = (6, 2)
EXPECTED_MACOS_PLATFORM = ".macOS(.v12)"
SOURCE_ROOTS = ("Sources", "Tests", "WidgetExtension")
SOURCE_PREFILTER_MARKERS = (
    "Observation",
    "@Observable",
    "@Bindable",
    "@Entry",
    "Chart",
    "ViewThatFits",
    "Grid",
    "LabeledContent",
    "scrollContentBackground",
    "scrollIndicators",
    "formStyle",
    "draggable",
    "dropDestination",
    "defaultSize",
    "ContentUnavailableView",
    "SettingsLink",
    "openSettings",
    "containerBackground",
    "onKeyPress",
    "OSAllocatedUnfairLock",
    "ExecutorJob",
    ".gmt",
    "trimmingPrefix(",
    "trimmingSuffix(",
    "split(separator:",
    "appending(path:",
    "append(path:",
    "filePath:",
    "directoryHint:",
    "path(percentEncoded:",
    "host(percentEncoded:",
    "appending(queryItems:",
    "append(queryItems:",
    "matches(of:",
    "firstMatch(of:",
    "Regex(",
)


@dataclass(frozen=True)
class Rule:
    name: str
    pattern: re.Pattern[str]
    message: str
    minimum_macos: int | None = None


@dataclass(frozen=True)
class Finding:
    path: Path
    line: int
    column: int
    rule: str
    message: str


FORBIDDEN_RULES = (
    Rule(
        "native-observation-import",
        re.compile(r"(?m)^\s*import\s+Observation\b"),
        "use swift-perception instead of importing Observation in the macOS 12 lane",
    ),
    Rule(
        "native-observable-macro",
        re.compile(r"(?<![\w.])@Observable\b"),
        "use @Perceptible so the model remains observable on macOS 12",
    ),
    Rule(
        "native-bindable-macro",
        re.compile(r"(?<![\w.])@Bindable\b"),
        "use @Perception.Bindable for macOS 12-compatible bindings",
    ),
    Rule(
        "swiftui-entry-macro",
        re.compile(r"(?<![\w.])@Entry\b"),
        "declare an explicit EnvironmentKey instead of using the newer @Entry macro",
    ),
    Rule(
        "os-allocated-unfair-lock",
        re.compile(r"\bOSAllocatedUnfairLock\b|^\s*import\s+os[.]lock\b", re.MULTILINE),
        "use the Monterey-compatible StateLock instead of the macOS 13 lock API",
    ),
    Rule(
        "modern-executor-job",
        re.compile(r"\bExecutorJob\b"),
        "implement SerialExecutor.enqueue with UnownedJob for the macOS 12 concurrency runtime",
    ),
    Rule(
        "time-zone-gmt",
        re.compile(r"(?<![A-Za-z0-9_])[.]gmt\b|\bTimeZone[.]gmt\b"),
        "construct GMT with TimeZone(secondsFromGMT:) for macOS 12",
    ),
    Rule(
        "string-trimming-affix",
        re.compile(r"[.]trimming(?:Prefix|Suffix)\s*\("),
        "use hasPrefix/hasSuffix with dropFirst/dropLast for macOS 12",
    ),
    Rule(
        "modern-url-path-api",
        re.compile(
            r"[.]append(?:ing)?\s*\(\s*(?:path|component)\s*:|"
            r"\bURL\s*\(\s*filePath\s*:|\bdirectoryHint\s*:|"
            r"[.](?:path|host)\s*\(\s*percentEncoded\s*:|"
            r"[.]append(?:ing)?\s*\(\s*queryItems\s*:(?!(?s:.{0,256}\bpathComponents\s*:))"
        ),
        "use the pre-macOS 13 URL and URLComponents APIs",
    ),
    Rule(
        "modern-url-directory-api",
        re.compile(
            r"\bURL[.](?:applicationSupportDirectory|cachesDirectory|desktopDirectory|"
            r"documentsDirectory|downloadsDirectory|homeDirectory|temporaryDirectory)\b"
        ),
        "resolve directories through FileManager for macOS 12",
    ),
    Rule(
        "swift-regex-runtime",
        re.compile(r"[.](?:matches|firstMatch)\s*\(\s*of\s*:|(?<![A-Za-z0-9_])Regex\s*\("),
        "use NSRegularExpression/TextParsing to avoid the macOS 13 Swift Regex runtime",
    ),
)


# These rules need to inspect a literal's contents. Matches are still required to
# begin in unmasked code, so comments and string contents cannot trigger them.
RAW_LITERAL_RULES = (
    Rule(
        "string-multicharacter-split",
        re.compile(r"[.]split\s*\(\s*separator\s*:\s*\"(?:\\.|[^\"\\]){2,}\""),
        "use components(separatedBy:) when splitting on a multi-character String on macOS 12",
    ),
)


GUARDED_RULES = (
    Rule(
        "charts-view",
        re.compile(r"\bChart\s*\("),
        "Charts views require a macOS 13 availability boundary",
        13,
    ),
    Rule(
        "charts-type",
        re.compile(r"\b(?:ChartProxy|ChartContent|AxisMarks|AxisValueLabel)\b|@ChartContentBuilder\b"),
        "Charts types require a macOS 13 availability boundary",
        13,
    ),
    Rule(
        "charts-mark",
        re.compile(r"\b(?:AreaMark|BarMark|LineMark|PointMark|RectangleMark|RuleMark|SectorMark)\s*\("),
        "Charts marks require a macOS 13 availability boundary",
        13,
    ),
    Rule(
        "charts-modifier",
        re.compile(
            r"\.chart(?:AngleSelection|Background|ForegroundStyleScale|Legend|Overlay|PlotStyle|"
            r"ScrollableAxes|ScrollPosition|SymbolScale|XAxis|XScale|XSelection|YAxis|YScale|YSelection)\s*\("
        ),
        "Charts modifiers require a macOS 13 availability boundary",
        13,
    ),
    Rule(
        "view-that-fits",
        re.compile(r"\bViewThatFits\s*(?:\(|\{)"),
        "ViewThatFits requires a macOS 13 availability boundary",
        13,
    ),
    Rule(
        "grid",
        re.compile(r"(?<![A-Za-z0-9_])Grid\s*\("),
        "SwiftUI Grid requires a macOS 13 availability boundary or a Monterey fallback",
        13,
    ),
    Rule(
        "labeled-content",
        re.compile(r"(?<![A-Za-z0-9_])LabeledContent\s*(?:<|\()"),
        "SwiftUI LabeledContent requires a macOS 13 availability boundary or a compatibility view",
        13,
    ),
    Rule(
        "scroll-content-background",
        re.compile(r"\.scrollContentBackground\s*\("),
        "scrollContentBackground requires a macOS 13 availability boundary",
        13,
    ),
    Rule(
        "scroll-indicators",
        re.compile(r"\.scrollIndicators\s*\("),
        "scrollIndicators requires a macOS 13 availability boundary",
        13,
    ),
    Rule(
        "form-style",
        re.compile(r"\.formStyle\s*\("),
        "the selected formStyle requires a macOS 13 availability boundary",
        13,
    ),
    Rule(
        "transferable-drag",
        re.compile(r"\.(?:draggable|dropDestination)\s*\("),
        "Transferable drag and drop requires a macOS 13 availability boundary",
        13,
    ),
    Rule(
        "default-window-size",
        re.compile(r"\.defaultSize\s*\("),
        "the SwiftUI scene defaultSize modifier requires a macOS 13 availability boundary",
        13,
    ),
    Rule(
        "content-unavailable-view",
        re.compile(r"(?<![A-Za-z0-9_])ContentUnavailableView\s*(?:<|\(|\{)"),
        "ContentUnavailableView requires a macOS 14 boundary or CodexBarContentUnavailableView",
        14,
    ),
    Rule(
        "settings-link",
        re.compile(r"(?<![A-Za-z0-9_])SettingsLink\s*(?:\(|\{)"),
        "SettingsLink requires a macOS 14 availability boundary",
        14,
    ),
    Rule(
        "open-settings-environment",
        re.compile(r"@Environment\s*\(\s*\\\.openSettings\s*\)"),
        "the SwiftUI openSettings environment value requires a macOS 14 availability boundary",
        14,
    ),
    Rule(
        "container-background",
        re.compile(r"\.containerBackground\s*\("),
        "containerBackground requires a macOS 14 availability boundary",
        14,
    ),
    Rule(
        "key-press",
        re.compile(r"\.onKeyPress\s*\("),
        "onKeyPress requires a macOS 14 availability boundary",
        14,
    ),
)


AVAILABILITY_PATTERN = re.compile(r"if\s+#available\s*\([^)]*macOS\s+(\d+)(?:\.\d+)?")
DECLARATION_AVAILABILITY_PATTERN = re.compile(r"@available\s*\([^)]*macOS\s+(\d+)(?:\.\d+)?")


def mask_non_code(source: str) -> str:
    """Replace comments and string contents with spaces while preserving offsets."""

    output = list(source)
    index = 0
    block_depth = 0
    state = "code"
    escaped = False

    def blank(position: int) -> None:
        if output[position] != "\n":
            output[position] = " "

    while index < len(source):
        if state == "line-comment":
            if source[index] == "\n":
                state = "code"
            else:
                blank(index)
            index += 1
            continue

        if state == "block-comment":
            if source.startswith("/*", index):
                blank(index)
                if index + 1 < len(source):
                    blank(index + 1)
                block_depth += 1
                index += 2
            elif source.startswith("*/", index):
                blank(index)
                if index + 1 < len(source):
                    blank(index + 1)
                block_depth -= 1
                index += 2
                if block_depth == 0:
                    state = "code"
            else:
                blank(index)
                index += 1
            continue

        if state == "string":
            blank(index)
            character = source[index]
            if escaped:
                escaped = False
            elif character == "\\":
                escaped = True
            elif character == '"':
                state = "code"
            index += 1
            continue

        if state == "multiline-string":
            if source.startswith('"""', index):
                for offset in range(3):
                    blank(index + offset)
                index += 3
                state = "code"
            else:
                blank(index)
                index += 1
            continue

        if source.startswith("//", index):
            blank(index)
            blank(index + 1)
            index += 2
            state = "line-comment"
        elif source.startswith("/*", index):
            blank(index)
            blank(index + 1)
            index += 2
            block_depth = 1
            state = "block-comment"
        elif source.startswith('"""', index):
            for offset in range(3):
                blank(index + offset)
            index += 3
            state = "multiline-string"
        elif source[index] == '"':
            blank(index)
            index += 1
            state = "string"
            escaped = False
        else:
            index += 1

    return "".join(output)


def max_version(*versions: int | None) -> int | None:
    concrete = [version for version in versions if version is not None]
    return max(concrete) if concrete else None


def line_and_column(newlines: list[int], offset: int) -> tuple[int, int]:
    line_index = bisect.bisect_right(newlines, offset)
    previous_newline = newlines[line_index - 1] if line_index else -1
    return line_index + 1, offset - previous_newline


def scan_source(path: Path, display_path: Path | None = None) -> list[Finding]:
    source = path.read_text(encoding="utf-8")
    if not any(marker in source for marker in SOURCE_PREFILTER_MARKERS):
        return []
    masked = mask_non_code(source)
    newlines = [index for index, character in enumerate(masked) if character == "\n"]
    findings: list[Finding] = []
    reported_path = display_path or path

    for rule in FORBIDDEN_RULES:
        for match in rule.pattern.finditer(masked):
            line, column = line_and_column(newlines, match.start())
            findings.append(Finding(reported_path, line, column, rule.name, rule.message))

    for rule in RAW_LITERAL_RULES:
        for match in rule.pattern.finditer(source):
            if masked[match.start()] != ".":
                continue
            line, column = line_and_column(newlines, match.start())
            findings.append(Finding(reported_path, line, column, rule.name, rule.message))

    guarded_matches: dict[int, list[tuple[Rule, re.Match[str]]]] = {}
    imports_charts = re.search(r"(?m)^\s*import\s+Charts\b", masked) is not None
    for rule in GUARDED_RULES:
        if rule.name.startswith("charts-") and not imports_charts:
            continue
        for match in rule.pattern.finditer(masked):
            guarded_matches.setdefault(match.start(), []).append((rule, match))

    events: list[tuple[int, int, str, object]] = []
    for match in AVAILABILITY_PATTERN.finditer(masked):
        events.append((match.start(), 0, "conditional-availability", int(match.group(1))))
    for match in DECLARATION_AVAILABILITY_PATTERN.finditer(masked):
        events.append((match.start(), 0, "declaration-availability", int(match.group(1))))
    for offset, character in enumerate(masked):
        if character == "{":
            events.append((offset, 1, "open-brace", character))
        elif character == "}":
            events.append((offset, 1, "close-brace", character))
    for offset, matches in guarded_matches.items():
        for rule, match in matches:
            events.append((offset, 2, "guarded-rule", (rule, match)))
    events.sort(key=lambda event: (event[0], event[1]))

    availability_stack: list[int | None] = [None]
    pending_conditional: int | None = None
    pending_declaration: int | None = None

    for _, _, event_type, value in events:
        if event_type == "conditional-availability":
            pending_conditional = int(value)
        elif event_type == "declaration-availability":
            pending_declaration = int(value)
        elif event_type == "open-brace":
            inherited = availability_stack[-1]
            if pending_conditional is not None:
                availability_stack.append(max_version(inherited, pending_conditional))
                pending_conditional = None
            elif pending_declaration is not None:
                availability_stack.append(max_version(inherited, pending_declaration))
                pending_declaration = None
            else:
                availability_stack.append(inherited)
        elif event_type == "close-brace":
            if len(availability_stack) > 1:
                availability_stack.pop()
        elif event_type == "guarded-rule":
            rule, match = value  # type: ignore[misc]
            effective = max_version(availability_stack[-1], pending_declaration)
            if effective is None or effective < rule.minimum_macos:
                line, column = line_and_column(newlines, match.start())
                findings.append(Finding(reported_path, line, column, rule.name, rule.message))

    return findings


def parse_version(value: str) -> tuple[int, ...]:
    return tuple(int(component) for component in value.split("."))


def scan_manifest(root: Path) -> list[Finding]:
    manifest = root / "Package.swift"
    if not manifest.is_file():
        return [Finding(Path("Package.swift"), 1, 1, "missing-manifest", "Package.swift was not found")]

    text = manifest.read_text(encoding="utf-8")
    findings: list[Finding] = []
    tools_match = re.search(r"swift-tools-version:\s*([0-9]+(?:\.[0-9]+)+)", text[:512])
    if tools_match is None:
        findings.append(
            Finding(Path("Package.swift"), 1, 1, "swift-tools-version", "swift-tools-version is missing")
        )
    elif parse_version(tools_match.group(1)) < MINIMUM_SWIFT_TOOLS:
        findings.append(
            Finding(
                Path("Package.swift"),
                1,
                1,
                "swift-tools-version",
                "the compatibility build requires Swift tools 6.2 or newer",
            )
        )

    if EXPECTED_MACOS_PLATFORM not in mask_non_code(text):
        findings.append(
            Finding(
                Path("Package.swift"),
                1,
                1,
                "deployment-target",
                f"Package.swift must declare {EXPECTED_MACOS_PLATFORM}",
            )
        )
    return findings


def swift_files(root: Path) -> Iterable[Path]:
    for source_root in SOURCE_ROOTS:
        directory = root / source_root
        if not directory.is_dir():
            continue
        yield from sorted(directory.rglob("*.swift"))


def scan_repository(root: Path) -> list[Finding]:
    findings = scan_manifest(root)
    for path in swift_files(root):
        findings.extend(scan_source(path, path.relative_to(root)))
    return sorted(findings, key=lambda finding: (str(finding.path), finding.line, finding.column, finding.rule))


def run_self_tests() -> None:
    fixtures = (
        ("safe fallback name", "CodexBarContentUnavailableView { Text(\"empty\") }", 0),
        ("comments are ignored", "// ViewThatFits(in: .horizontal) { }", 0),
        ("strings are ignored", 'let text = "@Observable ViewThatFits()"', 0),
        ("unguarded API", "var body: some View { ViewThatFits { Text(\"x\") } }", 1),
        (
            "conditional guard",
            "var body: some View { if #available(macOS 13, *) { ViewThatFits { Text(\"x\") } } }",
            0,
        ),
        (
            "declaration guard",
            "@available(macOS 13, *)\nprivate var body: some View { ViewThatFits { Text(\"x\") } }",
            0,
        ),
        (
            "else branch is not guarded",
            "if #available(macOS 13, *) { Text(\"new\") } else { ViewThatFits { Text(\"bad\") } }",
            1,
        ),
        (
            "insufficient guard",
            "if #available(macOS 13, *) { Text(\"x\").containerBackground(.fill.tertiary) }",
            1,
        ),
        (
            "matching guard",
            "if #available(macOS 14, *) { Text(\"x\").containerBackground(.fill.tertiary) }",
            0,
        ),
        ("native Observation is forbidden", "import Observation\n@Observable final class Store {}", 2),
        (
            "modern URL APIs are forbidden",
            "let root = URL(filePath: path, directoryHint: .isDirectory)\n"
            "let child = root.appending(path: \"child\")\n"
            "let decoded = child.path(percentEncoded: false)",
            4,
        ),
        (
            "Swift Regex runtime is forbidden",
            "let regex = try Regex(pattern)\nlet match = text.firstMatch(of: regex)",
            2,
        ),
        (
            "Monterey lock is required",
            "import os.lock\nlet lock = OSAllocatedUnfairLock(initialState: 0)",
            2,
        ),
        (
            "Monterey executor job is required",
            "func enqueue(_ job: consuming ExecutorJob) {}",
            1,
        ),
        (
            "Monterey Foundation conveniences are required",
            'calendar.timeZone = .gmt\nlet value = text.trimmingPrefix(".")\n'
            'let parts = text.split(separator: "::")',
            3,
        ),
    )

    for name, source, expected_count in fixtures:
        fixture = Path(f"{name.replace(' ', '-')}.swift")
        temporary = Path.cwd() / ".build" / "macos12-scanner-self-test" / fixture
        temporary.parent.mkdir(parents=True, exist_ok=True)
        temporary.write_text(source, encoding="utf-8")
        try:
            actual = scan_source(temporary, fixture)
        finally:
            temporary.unlink(missing_ok=True)
        if len(actual) != expected_count:
            rendered = ", ".join(finding.rule for finding in actual) or "no findings"
            raise AssertionError(f"{name}: expected {expected_count} finding(s), got {rendered}")

    with tempfile.TemporaryDirectory(prefix="codexbar-macos12-manifest-") as directory:
        root = Path(directory)
        manifest = root / "Package.swift"
        manifest.write_text(
            "// swift-tools-version: 6.2\n"
            "import PackageDescription\n"
            "let package = Package(name: \"Fixture\", platforms: [.macOS(.v12)])\n",
            encoding="utf-8",
        )
        if scan_manifest(root):
            raise AssertionError("valid Swift 6.2/macOS 12 manifest was rejected")
        manifest.write_text(
            "// swift-tools-version: 5.7\n"
            "import PackageDescription\n"
            "let package = Package(name: \"Fixture\", platforms: [.macOS(.v14)])\n",
            encoding="utf-8",
        )
        manifest_rules = {finding.rule for finding in scan_manifest(root)}
        if manifest_rules != {"swift-tools-version", "deployment-target"}:
            raise AssertionError(f"invalid manifest produced unexpected findings: {sorted(manifest_rules)}")

    print(f"macOS 12 compatibility scanner self-tests passed: {len(fixtures)} source fixtures + manifest")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", type=Path, default=Path(__file__).resolve().parent.parent)
    parser.add_argument("--self-test", action="store_true", help="run scanner fixtures instead of scanning the repo")
    parser.add_argument("--list-rules", action="store_true", help="print the active policy names")
    args = parser.parse_args()

    if args.list_rules:
        for rule in (*FORBIDDEN_RULES, *RAW_LITERAL_RULES, *GUARDED_RULES):
            requirement = "forbidden" if rule.minimum_macos is None else f"guard macOS {rule.minimum_macos}+"
            print(f"{rule.name}: {requirement}")
        return 0

    if args.self_test:
        run_self_tests()
        return 0

    root = args.root.resolve()
    findings = scan_repository(root)
    if findings:
        for finding in findings:
            print(
                f"{finding.path}:{finding.line}:{finding.column}: error: "
                f"[{finding.rule}] {finding.message}",
                file=sys.stderr,
            )
        print(f"macOS 12 compatibility scan failed: {len(findings)} finding(s)", file=sys.stderr)
        return 1

    file_count = sum(1 for _ in swift_files(root))
    print(f"macOS 12 compatibility scan passed: {file_count} Swift files")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (OSError, UnicodeError, AssertionError) as error:
        print(f"macOS 12 compatibility scan error: {error}", file=sys.stderr)
        raise SystemExit(2) from error
