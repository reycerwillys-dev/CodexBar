import Foundation
import Testing

@Suite("macOS 12 build automation policy")
struct MacOS12BuildPolicyTests {
    private static let repositoryRoot = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .deletingLastPathComponent()

    @Test
    func `package manifest keeps the Monterey deployment target`() throws {
        let manifest = try Self.contents(of: "Package.swift")

        #expect(manifest.contains("// swift-tools-version: 6.2"))
        #expect(manifest.contains(".macOS(.v12)"))
    }

    @Test
    func `build automation fixes architecture, deployment target, and credential isolation`() throws {
        let script = try Self.contents(of: "Scripts/build_macos12_x86_64.sh")

        #expect(script.contains("TARGET_ARCH=x86_64"))
        #expect(script.contains("DEPLOYMENT_TARGET=12.0"))
        #expect(script.contains("MACOSX_DEPLOYMENT_TARGET=\"$DEPLOYMENT_TARGET\""))
        #expect(script.contains("CODEXBAR_DISABLE_KEYCHAIN_ACCESS=1"))
        #expect(script.contains("CODEXBAR_ALLOW_TEST_KEYCHAIN_ACCESS=0"))
        #expect(!script.contains("CODEXBAR_ALLOW_TEST_KEYCHAIN_ACCESS=1"))
        for tool in ["file", "lipo", "vtool", "otool"] {
            #expect(script.contains(tool))
        }
    }

    @Test
    func `workflow reuses the verified Intel and Xcode selection pattern`() throws {
        let workflow = try Self.contents(of: ".github/workflows/macos12-compat.yml")

        #expect(workflow.contains("runs-on: macos-15-intel"))
        #expect(workflow.contains("/Applications/Xcode_26.3.app"))
        #expect(workflow.contains("/Applications/Xcode_26.2.app"))
        #expect(workflow.contains("uname -m"))
        #expect(workflow.contains("./Scripts/check_macos12_compat.py"))
        #expect(workflow.contains("./Scripts/build_macos12_x86_64.sh"))
        #expect(workflow.contains("MACOSX_DEPLOYMENT_TARGET: \"12.0\""))
    }

    private static func contents(of relativePath: String) throws -> String {
        try String(
            contentsOf: self.repositoryRoot.appendingPathComponent(relativePath),
            encoding: .utf8)
    }
}
