import CodexBarCore
import Foundation
import ServiceManagement

enum LaunchAtLoginManager {
    enum Status {
        case enabled
        case requiresApproval
        case notRegistered
        case notFound
        case unknown
    }

    typealias StatusProvider = () -> Status
    typealias RegistrationAction = () throws -> Void

    private static let legacyLaunchAgentLabel = "com.steipete.codexbar.launch-at-login"
    private static let fallbackBundleIdentifier = "com.steipete.codexbar"

    private static let isRunningTests: Bool = {
        let env = ProcessInfo.processInfo.environment
        if env["XCTestConfigurationFilePath"] != nil { return true }
        if env["TESTING_LIBRARY_VERSION"] != nil { return true }
        if env["SWIFT_TESTING"] != nil { return true }
        return NSClassFromString("XCTestCase") != nil
    }()

    static func setEnabled(_ enabled: Bool) {
        if self.isRunningTests { return }

        if #available(macOS 13, *) {
            self.setModernEnabled(enabled)
            return
        }

        do {
            try self.setLegacyEnabled(enabled)
        } catch {
            CodexBarLog.logger(LogCategories.launchAtLogin).error("Failed to update login item: \(error)")
        }
    }

    @available(macOS 13, *)
    private static func setModernEnabled(_ enabled: Bool) {
        let service = SMAppService.mainApp
        self.setEnabled(
            enabled,
            status: { self.status(for: service.status) },
            register: { try service.register() },
            unregister: { try service.unregister() })
    }

    @available(macOS 13, *)
    private static func status(for status: SMAppService.Status) -> Status {
        switch status {
        case .enabled: .enabled
        case .requiresApproval: .requiresApproval
        case .notRegistered: .notRegistered
        case .notFound: .notFound
        @unknown default: .unknown
        }
    }

    static func setEnabled(
        _ enabled: Bool,
        status: StatusProvider,
        register: RegistrationAction,
        unregister: RegistrationAction)
    {
        do {
            if enabled {
                switch status() {
                case .enabled, .requiresApproval:
                    return
                case .notRegistered, .notFound:
                    try register()
                case .unknown:
                    try register()
                }
            } else {
                switch status() {
                case .enabled, .requiresApproval:
                    try unregister()
                case .notRegistered, .notFound:
                    return
                case .unknown:
                    try unregister()
                }
            }
        } catch {
            CodexBarLog.logger(LogCategories.launchAtLogin).error("Failed to update login item: \(error)")
        }
    }

    static func legacyLaunchAgentData(bundleIdentifier: String) throws -> Data {
        let propertyList: [String: Any] = [
            "Label": self.legacyLaunchAgentLabel,
            "LimitLoadToSessionType": "Aqua",
            "ProcessType": "Interactive",
            "ProgramArguments": ["/usr/bin/open", "-g", "-b", bundleIdentifier],
            "RunAtLoad": true,
        ]
        return try PropertyListSerialization.data(
            fromPropertyList: propertyList,
            format: .xml,
            options: 0)
    }

    private static func setLegacyEnabled(_ enabled: Bool) throws {
        let fileManager = FileManager.default
        let launchAgentsDirectory = fileManager.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/LaunchAgents", isDirectory: true)
        let launchAgentURL = launchAgentsDirectory
            .appendingPathComponent("\(self.legacyLaunchAgentLabel).plist", isDirectory: false)

        if enabled {
            try fileManager.createDirectory(
                at: launchAgentsDirectory,
                withIntermediateDirectories: true,
                attributes: nil)
            let bundleIdentifier = Bundle.main.bundleIdentifier ?? self.fallbackBundleIdentifier
            try self.legacyLaunchAgentData(bundleIdentifier: bundleIdentifier).write(
                to: launchAgentURL,
                options: .atomic)
        } else if fileManager.fileExists(atPath: launchAgentURL.path) {
            try fileManager.removeItem(at: launchAgentURL)
        }
    }
}
