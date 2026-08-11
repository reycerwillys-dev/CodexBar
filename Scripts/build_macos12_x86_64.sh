#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
ROOT=$(cd "${SCRIPT_DIR}/.." && pwd)

CONFIGURATION=release
PRODUCT=CodexBar
TARGET_ARCH=x86_64
DEPLOYMENT_TARGET=12.0
BUILD_PATH="${ROOT}/.build/macos12"
OUTPUT_DIR="${ROOT}/.build/macos12-artifacts"
PACKAGE_APP=0
VERIFY_ONLY=

usage() {
  cat <<'EOF'
Usage: build_macos12_x86_64.sh [options]

Build and verify a credential-free x86_64 artifact with a macOS 12.0 minimum.

Options:
  --configuration <debug|release>  SwiftPM configuration (default: release)
  --product <name>                 SwiftPM executable product (default: CodexBar)
  --build-path <path>              Dedicated SwiftPM build path
  --output-dir <path>              Verified artifact destination
  --package-app                    Build CodexBar.app through the existing ad-hoc packager
  --verify-only <path>             Verify an existing Mach-O binary or .app without building
  --self-test                      Exercise version, architecture, and minimum-OS checks
  -h, --help                       Show this help

Examples:
  ./Scripts/build_macos12_x86_64.sh
  ./Scripts/build_macos12_x86_64.sh --package-app --output-dir /tmp/codexbar-macos12
  ./Scripts/build_macos12_x86_64.sh --verify-only CodexBar.app
EOF
}

fail() {
  echo "ERROR: $*" >&2
  exit 1
}

require_command() {
  command -v "$1" >/dev/null 2>&1 || fail "Required command not found: $1"
}

version_at_least() {
  local actual="$1"
  local required="$2"
  awk -v actual="$actual" -v required="$required" '
    BEGIN {
      actual_count = split(actual, actual_parts, ".")
      required_count = split(required, required_parts, ".")
      count = actual_count > required_count ? actual_count : required_count
      for (part = 1; part <= count; part++) {
        actual_value = part <= actual_count ? actual_parts[part] + 0 : 0
        required_value = part <= required_count ? required_parts[part] + 0 : 0
        if (actual_value > required_value) exit 0
        if (actual_value < required_value) exit 1
      }
      exit 0
    }
  '
}

version_at_most() {
  version_at_least "$2" "$1"
}

extract_swift_version() {
  sed -nE 's/.*Swift version ([0-9]+([.][0-9]+)+).*/\1/p' | head -n 1
}

credential_free() {
  env \
    CODEXBAR_ALLOW_TEST_KEYCHAIN_ACCESS=0 \
    CODEXBAR_ALLOW_TEST_BROWSER_COOKIE_ACCESS=0 \
    CODEXBAR_DISABLE_KEYCHAIN_ACCESS=1 \
    CODEXBAR_SUPPRESS_TEST_KEYCHAIN_ACCESS=1 \
    LIVE_TEST=0 \
    QWEN_CLOUD_LIVE_TEST=0 \
    LIVE_CLAUDE_KEYCHAIN_PROOF=0 \
    "$@"
}

macho_build_info() {
  local binary="$1"
  local arch="$2"
  local output

  if command -v vtool >/dev/null 2>&1; then
    if output=$(vtool -arch "$arch" -show-build "$binary" 2>/dev/null); then
      printf '%s\n' "$output"
      return 0
    fi
  fi

  require_command otool
  otool -arch "$arch" -l "$binary"
}

extract_minimum_macos() {
  awk '
    $1 == "minos" { print $2; exit }
    $1 == "cmd" && $2 == "LC_VERSION_MIN_MACOSX" { legacy = 1; next }
    legacy && $1 == "version" { print $2; exit }
  '
}

verify_macho() {
  local binary="$1"
  local expected_arch="${2:-$TARGET_ARCH}"
  local maximum_macos="${3:-$DEPLOYMENT_TARGET}"
  local file_description architectures build_info minimum_macos

  [[ -f "$binary" ]] || fail "Mach-O file not found: $binary"
  file_description=$(file -b "$binary")
  [[ "$file_description" == *"Mach-O"* ]] || fail "Not a Mach-O artifact: $binary ($file_description)"

  architectures=$(lipo -archs "$binary")
  if ! tr ' ' '\n' <<<"$architectures" | grep -qx "$expected_arch"; then
    fail "$binary does not contain $expected_arch (found: $architectures)"
  fi

  build_info=$(macho_build_info "$binary" "$expected_arch")
  if [[ "$build_info" != *"platform MACOS"* && "$build_info" != *"LC_VERSION_MIN_MACOSX"* ]]; then
    fail "$binary does not contain a macOS build-version load command"
  fi
  minimum_macos=$(printf '%s\n' "$build_info" | extract_minimum_macos)
  [[ -n "$minimum_macos" ]] || fail "Unable to read the minimum macOS version from $binary"
  if ! version_at_most "$minimum_macos" "$maximum_macos"; then
    fail "$binary requires macOS $minimum_macos; expected no newer than $maximum_macos"
  fi

  printf 'verified Mach-O: %s (architectures=%s, minimum-macOS=%s)\n' \
    "$binary" "$architectures" "$minimum_macos"
}

read_plist_value() {
  local plist="$1"
  local key="$2"
  /usr/libexec/PlistBuddy -c "Print :${key}" "$plist" 2>/dev/null
}

verify_app_bundle() {
  local bundle="$1"
  local plist="$bundle/Contents/Info.plist"
  local executable minimum_macos candidate description macho_count=0

  [[ -d "$bundle" ]] || fail "App bundle not found: $bundle"
  [[ -f "$plist" ]] || fail "Info.plist not found: $plist"
  executable=$(read_plist_value "$plist" CFBundleExecutable)
  minimum_macos=$(read_plist_value "$plist" LSMinimumSystemVersion)
  [[ -n "$executable" ]] || fail "CFBundleExecutable is missing from $plist"
  [[ -n "$minimum_macos" ]] || fail "LSMinimumSystemVersion is missing from $plist"
  if ! version_at_most "$minimum_macos" "$DEPLOYMENT_TARGET"; then
    fail "$bundle declares LSMinimumSystemVersion=$minimum_macos; expected no newer than $DEPLOYMENT_TARGET"
  fi
  [[ -f "$bundle/Contents/MacOS/$executable" ]] || fail "Main executable is missing from $bundle"

  while IFS= read -r -d '' candidate; do
    description=$(file -b "$candidate" 2>/dev/null || true)
    [[ "$description" == *"Mach-O"* ]] || continue
    verify_macho "$candidate"
    macho_count=$((macho_count + 1))
  done < <(find "$bundle/Contents" -type f -print0)

  ((macho_count > 0)) || fail "No Mach-O files found in $bundle"
  require_command codesign
  codesign --verify --deep --strict --verbose=2 "$bundle"
  printf 'verified app bundle: %s (Mach-O files=%d, LSMinimumSystemVersion=%s)\n' \
    "$bundle" "$macho_count" "$minimum_macos"
}

verify_artifact() {
  local artifact="$1"
  if [[ -d "$artifact" && "$artifact" == *.app ]]; then
    verify_app_bundle "$artifact"
  else
    verify_macho "$artifact"
  fi
}

patch_and_resign_app() {
  local bundle="$1"
  local plist="$bundle/Contents/Info.plist"
  local current entitlements

  current=$(read_plist_value "$plist" LSMinimumSystemVersion)
  if [[ "$current" != "$DEPLOYMENT_TARGET" ]]; then
    /usr/libexec/PlistBuddy -c "Set :LSMinimumSystemVersion ${DEPLOYMENT_TARGET}" "$plist"
  fi

  entitlements="${ROOT}/.build/entitlements/CodexBar.entitlements"
  if [[ -f "$entitlements" ]]; then
    codesign --force --sign - --entitlements "$entitlements" "$bundle"
  else
    codesign --force --sign - "$bundle"
  fi
}

record_artifact() {
  local artifact="$1"
  local metadata_name="$2"
  local checksum artifact_name swift_line xcode_line sdk_version git_sha

  mkdir -p "$OUTPUT_DIR"
  artifact_name=$(basename "$artifact")
  checksum=$(shasum -a 256 "$artifact" | awk '{print $1}')
  printf '%s  %s\n' "$checksum" "$artifact_name" >"${OUTPUT_DIR}/${artifact_name}.sha256"

  swift_line=$(swift --version 2>/dev/null | tr '\n' ';' || true)
  xcode_line=$(xcodebuild -version 2>/dev/null | tr '\n' ';' || true)
  sdk_version=$(xcrun --sdk macosx --show-sdk-version 2>/dev/null || true)
  git_sha=$(git -C "$ROOT" rev-parse HEAD 2>/dev/null || echo unknown)
  cat >"${OUTPUT_DIR}/${metadata_name}" <<EOF
git_sha=${git_sha}
architecture=${TARGET_ARCH}
deployment_target=${DEPLOYMENT_TARGET}
configuration=${CONFIGURATION}
swift=${swift_line:-unknown}
xcode=${xcode_line:-unknown}
macos_sdk=${sdk_version:-unknown}
artifact=${artifact_name}
sha256=${checksum}
signing=ad-hoc only; no identity or notarization
EOF

  printf 'artifact: %s\nsha256: %s\nmetadata: %s\n' \
    "$artifact" "$checksum" "${OUTPUT_DIR}/${metadata_name}"
}

check_build_toolchain() {
  local swift_output swift_version
  require_command swift
  require_command xcrun
  swift_output=$(swift --version)
  swift_version=$(printf '%s\n' "$swift_output" | extract_swift_version)
  [[ -n "$swift_version" ]] || fail "Unable to determine the active Swift version: $swift_output"
  if ! version_at_least "$swift_version" 6.2; then
    fail "Swift 6.2+ is required by Package.swift; active toolchain is Swift $swift_version"
  fi

  printf '%s\n' "$swift_output"
  xcodebuild -version 2>/dev/null || true
  printf 'macOS SDK: %s (%s)\n' \
    "$(xcrun --sdk macosx --show-sdk-version)" "$(xcrun --sdk macosx --show-sdk-path)"
}

run_self_test() {
  local temporary good_binary too_new_binary failure_log
  require_command awk
  require_command file
  require_command grep
  require_command lipo
  require_command xcrun

  version_at_least 6.2 6.2 || fail "version comparison rejected equality"
  version_at_least 6.2.1 6.2 || fail "version comparison rejected a newer patch"
  if version_at_least 6.1.9 6.2; then
    fail "version comparison accepted an older compiler"
  fi
  version_at_most 12.0 12.0 || fail "minimum-OS comparison rejected equality"
  if version_at_most 13.0 12.0; then
    fail "minimum-OS comparison accepted macOS 13"
  fi

  temporary=$(mktemp -d "${TMPDIR:-/tmp}/codexbar-macos12-self-test.XXXXXX")
  good_binary="${temporary}/minimum-12"
  too_new_binary="${temporary}/minimum-13"
  failure_log="${temporary}/expected-failure.log"
  printf 'int main(void) { return 0; }\n' >"${temporary}/main.c"
  xcrun clang -arch x86_64 -mmacosx-version-min=12.0 "${temporary}/main.c" -o "$good_binary"
  xcrun clang -arch x86_64 -mmacosx-version-min=13.0 "${temporary}/main.c" -o "$too_new_binary"

  verify_macho "$good_binary" x86_64 12.0
  if (verify_macho "$too_new_binary" x86_64 12.0) >"$failure_log" 2>&1; then
    fail "artifact verification accepted a macOS 13 minimum"
  fi
  grep -Fq "requires macOS 13.0" "$failure_log" || fail "minimum-OS failure did not explain the mismatch"
  if (verify_macho "$good_binary" arm64 12.0) >"$failure_log" 2>&1; then
    fail "artifact verification accepted a missing arm64 slice"
  fi
  grep -Fq "does not contain arm64" "$failure_log" || fail "architecture failure did not explain the mismatch"

  rm -rf "$temporary"
  echo "macOS 12 build automation self-tests passed"
}

while (($# > 0)); do
  case "$1" in
    --configuration)
      (($# >= 2)) || fail "--configuration requires a value"
      CONFIGURATION="$2"
      shift 2
      ;;
    --product)
      (($# >= 2)) || fail "--product requires a value"
      PRODUCT="$2"
      shift 2
      ;;
    --build-path)
      (($# >= 2)) || fail "--build-path requires a value"
      BUILD_PATH="$2"
      shift 2
      ;;
    --output-dir)
      (($# >= 2)) || fail "--output-dir requires a value"
      OUTPUT_DIR="$2"
      shift 2
      ;;
    --package-app)
      PACKAGE_APP=1
      shift
      ;;
    --verify-only)
      (($# >= 2)) || fail "--verify-only requires a path"
      VERIFY_ONLY="$2"
      shift 2
      ;;
    --self-test)
      run_self_test
      exit 0
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      usage >&2
      fail "Unknown option: $1"
      ;;
  esac
done

case "$CONFIGURATION" in
  debug|release) ;;
  *) fail "Unsupported configuration: $CONFIGURATION" ;;
esac

require_command awk
require_command file
require_command grep
require_command lipo
require_command shasum

if [[ -n "$VERIFY_ONLY" ]]; then
  verify_artifact "$VERIFY_ONLY"
  exit 0
fi

cd "$ROOT"
"${SCRIPT_DIR}/check_macos12_compat.py"
check_build_toolchain
mkdir -p "$OUTPUT_DIR"

if ((PACKAGE_APP == 1)); then
  [[ "$PRODUCT" == CodexBar ]] || fail "--package-app only supports the CodexBar product"
  require_command codesign
  require_command ditto
  credential_free env \
    ARCHES="$TARGET_ARCH" \
    CODEXBAR_SIGNING=adhoc \
    MACOSX_DEPLOYMENT_TARGET="$DEPLOYMENT_TARGET" \
    "${SCRIPT_DIR}/package_app.sh" "$CONFIGURATION"

  app="${ROOT}/CodexBar.app"
  patch_and_resign_app "$app"
  verify_app_bundle "$app"
  archive="${OUTPUT_DIR}/CodexBar-macos12-${TARGET_ARCH}-${CONFIGURATION}.zip"
  rm -f "$archive"
  ditto -c -k --sequesterRsrc --keepParent "$app" "$archive"
  record_artifact "$archive" "CodexBar-macos12-${TARGET_ARCH}-${CONFIGURATION}-build.txt"
else
  swift_flags=(--configuration "$CONFIGURATION" --arch "$TARGET_ARCH" --build-path "$BUILD_PATH")
  credential_free env MACOSX_DEPLOYMENT_TARGET="$DEPLOYMENT_TARGET" \
    swift build "${swift_flags[@]}" --product "$PRODUCT"
  bin_dir=$(credential_free env MACOSX_DEPLOYMENT_TARGET="$DEPLOYMENT_TARGET" \
    swift build "${swift_flags[@]}" --show-bin-path)
  binary="${bin_dir}/${PRODUCT}"
  verify_macho "$binary"
  output_binary="${OUTPUT_DIR}/${PRODUCT}-macos12-${TARGET_ARCH}-${CONFIGURATION}"
  cp "$binary" "$output_binary"
  verify_macho "$output_binary"
  record_artifact "$output_binary" "${PRODUCT}-macos12-${TARGET_ARCH}-${CONFIGURATION}-build.txt"
fi
