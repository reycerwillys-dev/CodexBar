import Foundation

/// An `NSLock`-backed state container compatible with Monterey.
final class StateLock<State>: @unchecked Sendable {
    private let lock = NSLock()
    private var state: State

    init(initialState: State) {
        self.state = initialState
    }

    func withLock<Result>(_ body: (inout State) throws -> Result) rethrows -> Result {
        self.lock.lock()
        defer { self.lock.unlock() }
        return try body(&self.state)
    }
}
