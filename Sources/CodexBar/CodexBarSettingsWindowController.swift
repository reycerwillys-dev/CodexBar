import AppKit
import Perception
import SwiftUI

/// AppKit-hosted settings window used on every supported OS.
///
/// SwiftUI's native `Settings` scene was introduced after Monterey. Hosting the
/// existing settings view ourselves keeps the same UI and routing while allowing
/// the menu-bar app to launch on macOS 12.
@MainActor
final class CodexBarSettingsWindowController: NSWindowController {
    init(
        settings: SettingsStore,
        store: UsageStore,
        cloudSyncState: CloudSyncState,
        updater: UpdaterProviding,
        selection: PreferencesSelection,
        managedCodexAccountCoordinator: ManagedCodexAccountCoordinator,
        codexAccountPromotionCoordinator: CodexAccountPromotionCoordinator,
        runProviderLoginFlow: @escaping @MainActor (UsageProvider) async -> Void)
    {
        let rootView = PreferencesView(
            settings: settings,
            store: store,
            cloudSyncState: cloudSyncState,
            updater: updater,
            selection: selection,
            managedCodexAccountCoordinator: managedCodexAccountCoordinator,
            codexAccountPromotionCoordinator: codexAccountPromotionCoordinator,
            runProviderLoginFlow: runProviderLoginFlow)
        let hostingController = NSHostingController(rootView: rootView)
        let window = NSWindow(contentViewController: hostingController)
        super.init(window: window)

        window.title = "CodexBar Settings"
        window.styleMask = [.titled, .closable, .miniaturizable, .resizable]
        window.isReleasedWhenClosed = false
        window.setContentSize(NSSize(width: SettingsPane.windowWidth, height: SettingsPane.windowHeight))
        window.minSize = NSSize(width: SettingsPane.windowMinWidth, height: SettingsPane.windowMinHeight)
        window.center()
        SettingsWindowAppearance.refresh(window)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is unavailable")
    }

    override func showWindow(_ sender: Any?) {
        super.showWindow(sender)
        self.window?.makeKeyAndOrderFront(sender)
        self.window?.orderFrontRegardless()
        NSApp.activate(ignoringOtherApps: true)
        if let window = self.window {
            SettingsWindowSizing.enforceMinimumSize(window)
        }
    }
}
