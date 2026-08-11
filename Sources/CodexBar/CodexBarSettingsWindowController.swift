import AppKit
import CodexBarCore
import Perception
import SwiftUI

/// AppKit-hosted settings window used on every supported OS.
///
/// Hosting the existing settings view ourselves keeps the same UI and routing
/// without relying on newer SwiftUI settings-opening and window-management APIs.
@MainActor
final class CodexBarSettingsWindowController: NSWindowController {
    private static let frameAutosaveName = "CodexBarSettingsWindowFrame"

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

        window.identifier = NSUserInterfaceItemIdentifier("CodexBarSettingsWindow")
        window.title = selection.pane.title
        window.styleMask = [.titled, .closable, .miniaturizable, .resizable]
        window.isReleasedWhenClosed = false
        window.isRestorable = false
        window.tabbingMode = .disallowed
        window.collectionBehavior.insert(.moveToActiveSpace)
        window.setContentSize(NSSize(width: SettingsPane.windowWidth, height: SettingsPane.windowHeight))
        if !window.setFrameUsingName(Self.frameAutosaveName) {
            window.center()
        }
        _ = window.setFrameAutosaveName(Self.frameAutosaveName)
        SettingsWindowSizing.enforceMinimumSize(window)
        SettingsWindowAppearance.refresh(window)
        DockIconController.shared.registerSettingsWindow(window)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is unavailable")
    }

    override func showWindow(_ sender: Any?) {
        guard let window = self.window else { return }
        DockIconController.shared.registerSettingsWindow(window)
        DockIconController.shared.promote()
        if window.isMiniaturized {
            window.deminiaturize(sender)
        }
        SettingsWindowSizing.enforceMinimumSize(window)
        SettingsWindowAppearance.refresh(window)
        super.showWindow(sender)
        window.makeKeyAndOrderFront(sender)
        NSApp.activate(ignoringOtherApps: true)
    }

    func prepareForApplicationTermination() {
        self.window?.orderOut(nil)
        self.close()
        self.window = nil
    }
}
