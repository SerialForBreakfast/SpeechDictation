//
//  TranscriptUpdateCoalescerTests.swift
//  SpeechDictationTests
//
//  Created: 2025-12-13
//
//  Purpose:
//  Long-form transcription typically generates rapid partial updates. Without coalescing,
//  the UI can thrash, waste CPU, and make autoscroll jittery.
//  These tests define a business-logic contract for throttling partial updates while
//  never delaying final commits.
//
//  Reference:
//  - XCTest async testing guidance:
//    https://developer.apple.com/documentation/xctest/asynchronous-tests-and-expectations
//

import Foundation
import XCTest
@testable import SpeechDictation

@MainActor
final class TranscriptUpdateCoalescerTests: XCTestCase {

    func testCoalescer_burstyPartials_emitFewerUpdates() async {
        let clock: ManualClock = ManualClock()
        let coalescer: TranscriptUpdateCoalescerReference = TranscriptUpdateCoalescerReference(
            throttleInterval: 0.250,
            clock: clock
        )

        var emitted: [String] = []

        coalescer.onEmit = { text in
            emitted.append(text)
        }

        // Burst of partials within 250ms should coalesce.
        coalescer.receivePartial("H")
        coalescer.receivePartial("He")
        coalescer.receivePartial("Hel")
        coalescer.receivePartial("Hell")
        coalescer.receivePartial("Hello")

        XCTAssertEqual(emitted.count, 0, "No immediate emission until throttle window elapses.")

        clock.advance(by: 0.249)
        await coalescer.pump()
        XCTAssertEqual(emitted.count, 0, "Still within throttle window.")

        clock.advance(by: 0.001)
        await coalescer.pump()
        XCTAssertEqual(emitted.count, 1, "Coalescer should emit only the latest partial after the window.")
        XCTAssertEqual(emitted.last, "Hello")
    }

    func testCoalescer_finalAlwaysFlushesImmediately() async {
        let clock: ManualClock = ManualClock()
        let coalescer: TranscriptUpdateCoalescerReference = TranscriptUpdateCoalescerReference(
            throttleInterval: 0.250,
            clock: clock
        )

        var emitted: [String] = []
        coalescer.onEmit = { text in
            emitted.append(text)
        }

        coalescer.receivePartial("How ar")
        XCTAssertEqual(emitted.count, 0)

        // Final should bypass throttling.
        coalescer.receiveFinal("How are you")
        XCTAssertEqual(emitted.count, 1)
        XCTAssertEqual(emitted[0], "How are you")
    }

    func testCoalescer_cancelStopsFutureEmissions() async {
        let clock: ManualClock = ManualClock()
        let coalescer: TranscriptUpdateCoalescerReference = TranscriptUpdateCoalescerReference(
            throttleInterval: 0.250,
            clock: clock
        )

        var emitted: [String] = []
        coalescer.onEmit = { text in
            emitted.append(text)
        }

        coalescer.receivePartial("Test")
        coalescer.cancel()

        clock.advance(by: 1.0)
        await coalescer.pump()

        XCTAssertEqual(emitted.count, 0, "Cancelled coalescer must not emit after cancellation.")
    }
}

// MARK: - Test-only reference implementation

/// A testable coalescer with an injected clock so unit tests are deterministic.
/// Production implementation can use ContinuousClock or Dispatch timers.
final class TranscriptUpdateCoalescerReference {

    typealias EmitHandler = (String) -> Void

    private let throttleInterval: TimeInterval
    private let clock: ManualClock

    private var lastPartial: String = ""
    private var lastEmissionTime: TimeInterval?
    private var isCancelled: Bool = false

    var onEmit: EmitHandler?

    init(throttleInterval: TimeInterval, clock: ManualClock) {
        self.throttleInterval = throttleInterval
        self.clock = clock
    }

    func receivePartial(_ text: String) {
        guard !isCancelled else { return }
        lastPartial = text
        if lastEmissionTime == nil {
            lastEmissionTime = clock.now
        }
    }

    func receiveFinal(_ text: String) {
        guard !isCancelled else { return }
        // Finals should flush immediately and reset throttling state.
        onEmit?(text)
        lastPartial = ""
        lastEmissionTime = nil
    }

    func cancel() {
        isCancelled = true
        lastPartial = ""
        lastEmissionTime = nil
    }

    /// Drives time-based emission in a deterministic way (unit tests call this explicitly).
    func pump() async {
        guard !isCancelled else { return }
        guard let start: TimeInterval = lastEmissionTime else { return }
        guard !lastPartial.isEmpty else { return }

        let elapsed: TimeInterval = clock.now - start
        if elapsed >= throttleInterval {
            onEmit?(lastPartial)
            lastPartial = ""
            lastEmissionTime = nil
        }
    }
}

/// A deterministic clock for unit tests.
final class ManualClock {
    private(set) var now: TimeInterval = 0.0

    func advance(by delta: TimeInterval) {
        now += delta
    }
}
