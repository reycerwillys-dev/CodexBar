import Testing
@testable import CodexBarCore

@Suite("Monterey time compatibility")
struct MontereyTimeTests {
    @Test
    func `duration arithmetic normalizes fractional seconds`() {
        let duration = Duration.milliseconds(1500) + .milliseconds(750)

        #expect(duration.components.seconds == 2)
        #expect(duration.components.attoseconds == 250_000_000_000_000_000)
        #expect(duration - .milliseconds(250) == .seconds(2))
    }

    @Test
    func `continuous-clock instants preserve monotonic offsets`() {
        let start = ContinuousClock.now
        let deadline = start.advanced(by: .milliseconds(125))

        #expect(start < deadline)
        #expect(start.duration(to: deadline) == .milliseconds(125))
        #expect(deadline - start == .milliseconds(125))
        #expect(deadline - .milliseconds(125) == start)
    }
}
