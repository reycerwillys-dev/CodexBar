import SwiftUI

final class SettingsOpenRequest {
    var wasHandled = false
}

@MainActor
struct SettingsWindowOpener {
    enum Path {
        case notification
        case appKit
    }

    enum Outcome: Equatable {
        case preferred
        case fallback
        case failed
    }

    private let notification: @MainActor () -> Bool
    private let appKit: @MainActor () -> Bool

    init(
        notification: @escaping @MainActor () -> Bool,
        appKit: @escaping @MainActor () -> Bool)
    {
        self.notification = notification
        self.appKit = appKit
    }

    static func live() -> Self {
        Self(
            notification: {
                DockIconController.shared.promote()
                let request = SettingsOpenRequest()
                NotificationCenter.default.post(name: .codexbarOpenSettings, object: request)
                return request.wasHandled
            },
            appKit: {
                DockIconController.shared.promote()
                return NSApp.sendAction(#selector(AppDelegate.showPreferencesWindow(_:)), to: nil, from: nil)
            })
    }

    func open(preferred: Path) -> Outcome {
        let attempts = preferred == .notification
            ? [self.notification, self.appKit]
            : [self.appKit, self.notification]
        if attempts[0]() {
            return .preferred
        }
        if attempts[1]() {
            return .fallback
        }
        return .failed
    }
}

struct HiddenWindowView: View {
    var body: some View {
        Color.clear
            .frame(width: 20, height: 20)
            .background(KeepaliveWindowConfigurator())
            .task {
                // Migrate keychain items to reduce permission prompts during development (runs off main thread)
                await Task.detached(priority: .userInitiated) {
                    KeychainMigration.migrateIfNeeded()
                }.value
            }
    }
}

@MainActor
struct KeepaliveWindowConfigurator: NSViewRepresentable {
    func makeNSView(context: Context) -> KeepaliveWindowConfiguratorView {
        KeepaliveWindowConfiguratorView()
    }

    func updateNSView(_ nsView: KeepaliveWindowConfiguratorView, context: Context) {}
}

@MainActor
final class KeepaliveWindowConfiguratorView: NSView {
    private let windowProvider: (NSView) -> NSWindow?

    init(windowProvider: @escaping (NSView) -> NSWindow? = { $0.window }) {
        self.windowProvider = windowProvider
        super.init(frame: .zero)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is unavailable")
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        guard let window = self.windowProvider(self) else { return }

        window.identifier = NSUserInterfaceItemIdentifier("CodexBarLifecycleKeepalive")
        // Do not rewrite styleMask from this NSHostingView move callback. On Monterey,
        // doing so re-enters SwiftUI's DefaultWindowStyle while AppKit is enumerating
        // the hosting hierarchy and aborts in _recursiveClearViewWillDidDisappearOnMoveToWindow.
        // Alpha, placement, sizing, and hit-testing already make this shell invisible.
        var collectionBehavior: NSWindow.CollectionBehavior = [.ignoresCycle, .transient, .canJoinAllSpaces]
        if #available(macOS 13, *) {
            collectionBehavior.insert(.auxiliary)
        }
        window.collectionBehavior = collectionBehavior
        window.isExcludedFromWindowsMenu = true
        window.level = .floating
        window.isOpaque = false
        window.alphaValue = 0
        window.backgroundColor = .clear
        window.hasShadow = false
        window.ignoresMouseEvents = true
        window.canHide = false
        window.setContentSize(NSSize(width: 1, height: 1))
        window.setFrameOrigin(NSPoint(x: -5000, y: -5000))
    }
}
