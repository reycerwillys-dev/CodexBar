import Foundation
import Testing
@testable import CodexBar

@MainActor
struct LaunchAtLoginManagerTests {
    @Test
    func `legacy launch agent opens the app bundle in an Aqua session`() throws {
        let data = try LaunchAtLoginManager.legacyLaunchAgentData(bundleIdentifier: "com.example.CodexBar")
        let propertyList = try #require(
            PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String: Any])

        #expect(propertyList["Label"] as? String == "com.steipete.codexbar.launch-at-login")
        #expect(propertyList["LimitLoadToSessionType"] as? String == "Aqua")
        #expect(propertyList["ProcessType"] as? String == "Interactive")
        #expect(propertyList["RunAtLoad"] as? Bool == true)
        #expect(
            propertyList["ProgramArguments"] as? [String] ==
                ["/usr/bin/open", "-g", "-b", "com.example.CodexBar"])
    }

    @Test
    func `set enabled skips registration when service is already enabled`() {
        var registerCalls = 0
        var unregisterCalls = 0

        LaunchAtLoginManager.setEnabled(
            true,
            status: { .enabled },
            register: { registerCalls += 1 },
            unregister: { unregisterCalls += 1 })

        #expect(registerCalls == 0)
        #expect(unregisterCalls == 0)
    }

    @Test
    func `set enabled registers when service is not registered`() {
        var registerCalls = 0
        var unregisterCalls = 0

        LaunchAtLoginManager.setEnabled(
            true,
            status: { .notRegistered },
            register: { registerCalls += 1 },
            unregister: { unregisterCalls += 1 })

        #expect(registerCalls == 1)
        #expect(unregisterCalls == 0)
    }

    @Test
    func `set enabled skips registration when service requires approval`() {
        var registerCalls = 0
        var unregisterCalls = 0

        LaunchAtLoginManager.setEnabled(
            true,
            status: { .requiresApproval },
            register: { registerCalls += 1 },
            unregister: { unregisterCalls += 1 })

        #expect(registerCalls == 0)
        #expect(unregisterCalls == 0)
    }

    @Test
    func `set enabled registers when service is not found`() {
        var registerCalls = 0
        var unregisterCalls = 0

        LaunchAtLoginManager.setEnabled(
            true,
            status: { .notFound },
            register: { registerCalls += 1 },
            unregister: { unregisterCalls += 1 })

        #expect(registerCalls == 1)
        #expect(unregisterCalls == 0)
    }

    @Test
    func `set disabled unregisters when service is enabled`() {
        var registerCalls = 0
        var unregisterCalls = 0

        LaunchAtLoginManager.setEnabled(
            false,
            status: { .enabled },
            register: { registerCalls += 1 },
            unregister: { unregisterCalls += 1 })

        #expect(registerCalls == 0)
        #expect(unregisterCalls == 1)
    }

    @Test
    func `set disabled unregisters when service requires approval`() {
        var registerCalls = 0
        var unregisterCalls = 0

        LaunchAtLoginManager.setEnabled(
            false,
            status: { .requiresApproval },
            register: { registerCalls += 1 },
            unregister: { unregisterCalls += 1 })

        #expect(registerCalls == 0)
        #expect(unregisterCalls == 1)
    }

    @Test
    func `set disabled skips unregister when service is not registered`() {
        var registerCalls = 0
        var unregisterCalls = 0

        LaunchAtLoginManager.setEnabled(
            false,
            status: { .notRegistered },
            register: { registerCalls += 1 },
            unregister: { unregisterCalls += 1 })

        #expect(registerCalls == 0)
        #expect(unregisterCalls == 0)
    }

    @Test
    func `set disabled skips unregister when service is not found`() {
        var registerCalls = 0
        var unregisterCalls = 0

        LaunchAtLoginManager.setEnabled(
            false,
            status: { .notFound },
            register: { registerCalls += 1 },
            unregister: { unregisterCalls += 1 })

        #expect(registerCalls == 0)
        #expect(unregisterCalls == 0)
    }
}
