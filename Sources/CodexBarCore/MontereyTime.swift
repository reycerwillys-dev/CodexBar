import Dispatch
import Foundation

/// A monotonic duration implementation that does not depend on the macOS 13 Swift clock APIs.
///
/// Keep the public name aligned with Swift's `Duration` so existing Core clients can retain their
/// typed timeout and deadline APIs while deploying to Monterey.
public struct Duration: Sendable, Hashable, Comparable, AdditiveArithmetic, CustomStringConvertible {
    public struct Components: Sendable, Hashable {
        public let seconds: Int64
        public let attoseconds: Int64
    }

    private static let attosecondsPerSecond: Int64 = 1_000_000_000_000_000_000
    private static let attosecondsPerMillisecond: Int64 = 1_000_000_000_000_000
    private static let attosecondsPerMicrosecond: Int64 = 1_000_000_000_000
    private static let attosecondsPerNanosecond: Int64 = 1_000_000_000

    private let secondsValue: Int64
    private let attosecondsValue: Int64

    private init(seconds: Int64, attoseconds: Int64) {
        let normalized = Self.normalize(seconds: seconds, attoseconds: attoseconds)
        self.secondsValue = normalized.seconds
        self.attosecondsValue = normalized.attoseconds
    }

    public static let zero = Duration(seconds: 0, attoseconds: 0)

    public var components: Components {
        Components(seconds: self.secondsValue, attoseconds: self.attosecondsValue)
    }

    public var description: String {
        let fractionalSeconds = Double(self.attosecondsValue) / Double(Self.attosecondsPerSecond)
        return "\(Double(self.secondsValue) + fractionalSeconds) seconds"
    }

    public static func seconds<Value: BinaryInteger>(_ seconds: Value) -> Duration {
        Duration(seconds: Int64(clamping: seconds), attoseconds: 0)
    }

    public static func seconds<Value: BinaryFloatingPoint>(_ seconds: Value) -> Duration {
        Self.fromFloatingSeconds(Double(seconds))
    }

    public static func milliseconds<Value: BinaryInteger>(_ milliseconds: Value) -> Duration {
        Self.fromIntegerUnits(
            Int64(clamping: milliseconds),
            unitsPerSecond: 1_000,
            attosecondsPerUnit: Self.attosecondsPerMillisecond)
    }

    public static func milliseconds<Value: BinaryFloatingPoint>(_ milliseconds: Value) -> Duration {
        Self.fromFloatingSeconds(Double(milliseconds) / 1_000)
    }

    public static func microseconds<Value: BinaryInteger>(_ microseconds: Value) -> Duration {
        Self.fromIntegerUnits(
            Int64(clamping: microseconds),
            unitsPerSecond: 1_000_000,
            attosecondsPerUnit: Self.attosecondsPerMicrosecond)
    }

    public static func microseconds<Value: BinaryFloatingPoint>(_ microseconds: Value) -> Duration {
        Self.fromFloatingSeconds(Double(microseconds) / 1_000_000)
    }

    public static func nanoseconds<Value: BinaryInteger>(_ nanoseconds: Value) -> Duration {
        Self.fromIntegerUnits(
            Int64(clamping: nanoseconds),
            unitsPerSecond: 1_000_000_000,
            attosecondsPerUnit: Self.attosecondsPerNanosecond)
    }

    public static func nanoseconds<Value: BinaryFloatingPoint>(_ nanoseconds: Value) -> Duration {
        Self.fromFloatingSeconds(Double(nanoseconds) / 1_000_000_000)
    }

    public static func < (lhs: Duration, rhs: Duration) -> Bool {
        if lhs.secondsValue != rhs.secondsValue {
            return lhs.secondsValue < rhs.secondsValue
        }
        return lhs.attosecondsValue < rhs.attosecondsValue
    }

    public static func + (lhs: Duration, rhs: Duration) -> Duration {
        let (seconds, overflow) = lhs.secondsValue.addingReportingOverflow(rhs.secondsValue)
        if overflow {
            return rhs.secondsValue >= 0 ? Self.maximum : Self.minimum
        }
        return Duration(
            seconds: seconds,
            attoseconds: lhs.attosecondsValue + rhs.attosecondsValue)
    }

    public static func - (lhs: Duration, rhs: Duration) -> Duration {
        lhs + -rhs
    }

    public static prefix func - (duration: Duration) -> Duration {
        if duration.secondsValue == Int64.min {
            return Self.maximum
        }
        return Duration(seconds: -duration.secondsValue, attoseconds: -duration.attosecondsValue)
    }

    public static func * (lhs: Duration, rhs: Double) -> Duration {
        Self.fromFloatingSeconds(lhs.timeInterval * rhs)
    }

    public static func * (lhs: Double, rhs: Duration) -> Duration {
        rhs * lhs
    }

    public static func / (lhs: Duration, rhs: Double) -> Duration {
        Self.fromFloatingSeconds(lhs.timeInterval / rhs)
    }

    fileprivate var timeInterval: TimeInterval {
        Double(self.secondsValue) + Double(self.attosecondsValue) / Double(Self.attosecondsPerSecond)
    }

    fileprivate var nonnegativeSleepNanoseconds: UInt64 {
        guard self > .zero else { return 0 }
        let seconds = UInt64(self.secondsValue)
        let maximumWholeSeconds = UInt64.max / 1_000_000_000
        guard seconds <= maximumWholeSeconds else { return UInt64.max }

        let wholeNanoseconds = seconds * 1_000_000_000
        let wholeFractionalNanoseconds = UInt64(self.attosecondsValue / Self.attosecondsPerNanosecond)
        let hasSubNanosecondRemainder = self.attosecondsValue % Self.attosecondsPerNanosecond != 0
        let fractionalNanoseconds = wholeFractionalNanoseconds + (hasSubNanosecondRemainder ? 1 : 0)
        let (result, overflow) = wholeNanoseconds.addingReportingOverflow(fractionalNanoseconds)
        return overflow ? UInt64.max : result
    }

    fileprivate func adding(to uptimeNanoseconds: UInt64) -> UInt64 {
        if self >= .zero {
            let delta = self.nonnegativeSleepNanoseconds
            let (result, overflow) = uptimeNanoseconds.addingReportingOverflow(delta)
            return overflow ? UInt64.max : result
        }

        let delta = (-self).nonnegativeSleepNanoseconds
        return delta >= uptimeNanoseconds ? 0 : uptimeNanoseconds - delta
    }

    fileprivate static func uptimeDelta(_ nanoseconds: UInt64, negative: Bool) -> Duration {
        let seconds = Int64(nanoseconds / 1_000_000_000)
        let attoseconds = Int64(nanoseconds % 1_000_000_000) * Self.attosecondsPerNanosecond
        return Duration(
            seconds: negative ? -seconds : seconds,
            attoseconds: negative ? -attoseconds : attoseconds)
    }

    private static let maximum = Duration(
        normalizedSeconds: Int64.max,
        normalizedAttoseconds: Self.attosecondsPerSecond - 1)
    private static let minimum = Duration(
        normalizedSeconds: Int64.min,
        normalizedAttoseconds: -(Self.attosecondsPerSecond - 1))

    private init(normalizedSeconds: Int64, normalizedAttoseconds: Int64) {
        self.secondsValue = normalizedSeconds
        self.attosecondsValue = normalizedAttoseconds
    }

    private static func fromIntegerUnits(
        _ value: Int64,
        unitsPerSecond: Int64,
        attosecondsPerUnit: Int64) -> Duration
    {
        Duration(
            seconds: value / unitsPerSecond,
            attoseconds: (value % unitsPerSecond) * attosecondsPerUnit)
    }

    private static func fromFloatingSeconds(_ value: Double) -> Duration {
        guard !value.isNaN else { return .zero }
        if value >= Double(Int64.max) { return Self.maximum }
        if value <= Double(Int64.min) { return Self.minimum }

        let seconds = value.rounded(.towardZero)
        let fractional = value - seconds
        let attoseconds = (fractional * Double(Self.attosecondsPerSecond)).rounded()
        return Duration(seconds: Int64(seconds), attoseconds: Int64(attoseconds))
    }

    private static func normalize(seconds: Int64, attoseconds: Int64) -> Components {
        let carry = attoseconds / Self.attosecondsPerSecond
        var remainder = attoseconds % Self.attosecondsPerSecond
        let (carriedSeconds, overflow) = seconds.addingReportingOverflow(carry)
        if overflow {
            return carry >= 0 ? Self.maximum.components : Self.minimum.components
        }

        var normalizedSeconds = carriedSeconds
        if normalizedSeconds > 0, remainder < 0 {
            normalizedSeconds -= 1
            remainder += Self.attosecondsPerSecond
        } else if normalizedSeconds < 0, remainder > 0 {
            normalizedSeconds += 1
            remainder -= Self.attosecondsPerSecond
        }
        return Components(seconds: normalizedSeconds, attoseconds: remainder)
    }
}

/// A `DispatchTime`-backed monotonic clock with the subset of the Swift clock API used by CodexBar.
public struct ContinuousClock: Sendable {
    public struct Instant: Sendable, Hashable, Comparable {
        fileprivate let uptimeNanoseconds: UInt64

        public static var now: Instant {
            Instant(uptimeNanoseconds: DispatchTime.now().uptimeNanoseconds)
        }

        public func advanced(by duration: Duration) -> Instant {
            Instant(uptimeNanoseconds: duration.adding(to: self.uptimeNanoseconds))
        }

        public func duration(to other: Instant) -> Duration {
            if other.uptimeNanoseconds >= self.uptimeNanoseconds {
                return Duration.uptimeDelta(other.uptimeNanoseconds - self.uptimeNanoseconds, negative: false)
            }
            return Duration.uptimeDelta(self.uptimeNanoseconds - other.uptimeNanoseconds, negative: true)
        }

        public static func < (lhs: Instant, rhs: Instant) -> Bool {
            lhs.uptimeNanoseconds < rhs.uptimeNanoseconds
        }

        public static func + (lhs: Instant, rhs: Duration) -> Instant {
            lhs.advanced(by: rhs)
        }

        public static func + (lhs: Duration, rhs: Instant) -> Instant {
            rhs.advanced(by: lhs)
        }

        public static func - (lhs: Instant, rhs: Duration) -> Instant {
            lhs.advanced(by: -rhs)
        }

        public static func - (lhs: Instant, rhs: Instant) -> Duration {
            rhs.duration(to: lhs)
        }

        public static func += (lhs: inout Instant, rhs: Duration) {
            lhs = lhs + rhs
        }

        public static func -= (lhs: inout Instant, rhs: Duration) {
            lhs = lhs - rhs
        }
    }

    public init() {}

    public static var now: Instant {
        .now
    }

    public var now: Instant {
        .now
    }

    public func sleep(until deadline: Instant) async throws {
        try await Task<Never, Never>.sleep(for: self.now.duration(to: deadline))
    }
}

public extension Task where Success == Never, Failure == Never {
    /// Monterey-compatible counterpart to the macOS 13 `Task.sleep(for:)` convenience.
    static func sleep(for duration: Duration) async throws {
        try Task<Never, Never>.checkCancellation()
        let nanoseconds = duration.nonnegativeSleepNanoseconds
        guard nanoseconds > 0 else { return }
        try await Task<Never, Never>.sleep(nanoseconds: nanoseconds)
    }
}
