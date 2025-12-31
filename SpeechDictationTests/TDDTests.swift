//
//  TDDTests.swift
//  SpeechDictationTests
//
//  Test-Driven Development test suite for long-form transcription reliability.
//
//  Created: 2025-12-13
//
//  Notes:
//  - These tests intentionally encode the refined task requirements (BUG-001, TASK-027A..F).
//  - Some tests are marked with XCTExpectFailure to support incremental development without
//    disabling/skipping tests. Convert these to strict assertions as implementations land.
//

//import Foundation
//import XCTest
//@testable import SpeechDictation
//
///// A TDD-oriented test suite that encodes the “long-form, real-world” requirements:
///// - Continuous transcript accumulation across long pauses
///// - No duplication (volatile partials must not be permanently appended)
///// - No loss on task restarts (monotonic time ranges / stable segment identity)
///// - Clear stop/cancel semantics (flush vs. discard volatile)
/////
///// This file is intentionally “requirements-first” and should be evolved alongside implementations.
//@MainActor
//final class TDDTests: XCTestCase {
//
//    // MARK: - Constants
//
//    private enum Constants {
//        static let textJoinSeparator: String = " "
//        static let timingAccuracy: TimeInterval = 0.001
//    }
//
//    // MARK: - Setup / Teardown
//
//    override func setUp() async throws {
//        try await super.setUp()
//        TimingDataManager.shared.clearSegments()
//    }
//
//    override func tearDown() async throws {
//        TimingDataManager.shared.clearSegments()
//        try await super.tearDown()
//    }
//
//    // MARK: - TASK-027A: Transcript Buffer Model (Finalized vs Volatile)
//
//    func testTranscriptBuffer_partialDoesNotMutateFinalized() {
//        let buffer: TranscriptBufferReference = TranscriptBufferReference()
//
//        buffer.apply(.final(text: "Hello world"))
//        buffer.apply(.partial(text: "How ar"))
//
//        XCTAssertEqual(buffer.finalizedText, "Hello world")
//        XCTAssertEqual(buffer.volatileText, "How ar")
//        XCTAssertEqual(buffer.displayText, "Hello world How ar")
//    }
//
//    func testTranscriptBuffer_finalCommitsAndClearsVolatile() {
//        let buffer: TranscriptBufferReference = TranscriptBufferReference()
//
//        buffer.apply(.partial(text: "Hello wor"))
//        XCTAssertEqual(buffer.displayText, "Hello wor")
//
//        buffer.apply(.final(text: "Hello world"))
//        XCTAssertEqual(buffer.finalizedText, "Hello world")
//        XCTAssertEqual(buffer.volatileText, "")
//        XCTAssertEqual(buffer.displayText, "Hello world")
//    }
//
//    func testTranscriptBuffer_partialRegressionNeverRemovesFinalized() {
//        let buffer: TranscriptBufferReference = TranscriptBufferReference()
//
//        buffer.apply(.final(text: "We discussed timelines"))
//        buffer.apply(.partial(text: "and the budg"))
//        buffer.apply(.partial(text: "and the budget")) // regression/correction within volatile
//
//        XCTAssertEqual(buffer.finalizedText, "We discussed timelines")
//        XCTAssertEqual(buffer.volatileText, "and the budget")
//        XCTAssertEqual(buffer.displayText, "We discussed timelines and the budget")
//    }
//
//    func testTranscriptBuffer_multipleUtterancesWithPauses_preservesAllTextInOrder() {
//        let buffer: TranscriptBufferReference = TranscriptBufferReference()
//
//        // Utterance 1 (final)
//        buffer.apply(.final(text: "Hello world"))
//
//        // Long pause (no events). Nothing should change.
//        XCTAssertEqual(buffer.displayText, "Hello world")
//
//        // Utterance 2 (partial then final)
//        buffer.apply(.partial(text: "How ar"))
//        XCTAssertEqual(buffer.displayText, "Hello world How ar")
//
//        buffer.apply(.final(text: "How are you"))
//        XCTAssertEqual(buffer.displayText, "Hello world How are you")
//
//        // Another pause
//        XCTAssertEqual(buffer.displayText, "Hello world How are you")
//
//        // Utterance 3
//        buffer.apply(.partial(text: "Good"))
//        buffer.apply(.final(text: "Goodbye"))
//
//        XCTAssertEqual(buffer.displayText, "Hello world How are you Goodbye")
//
//        // Guard: no duplication.
//        XCTAssertEqual(buffer.finalizedText, "Hello world How are you Goodbye")
//        XCTAssertEqual(buffer.volatileText, "")
//    }
//
//    func testTranscriptBuffer_stopFlushesVolatileByDefault() {
//        let buffer: TranscriptBufferReference = TranscriptBufferReference()
//
//        buffer.apply(.final(text: "Segment one"))
//        buffer.apply(.partial(text: "Segment two par"))
//
//        // Stop should flush volatile into finalized for “recording stop” semantics,
//        // aligning with analyzer finalization intent.
//        buffer.stop(flushVolatileIntoFinalized: true)
//
//        XCTAssertEqual(buffer.finalizedText, "Segment one Segment two par")
//        XCTAssertEqual(buffer.volatileText, "")
//        XCTAssertEqual(buffer.displayText, "Segment one Segment two par")
//    }
//
//    func testTranscriptBuffer_cancelDiscardsVolatileByDefault() {
//        let buffer: TranscriptBufferReference = TranscriptBufferReference()
//
//        buffer.apply(.final(text: "Committed"))
//        buffer.apply(.partial(text: "Uncommitted"))
//
//        // Cancel should discard volatile by default.
//        buffer.cancel(discardVolatile: true)
//
//        XCTAssertEqual(buffer.finalizedText, "Committed")
//        XCTAssertEqual(buffer.volatileText, "")
//        XCTAssertEqual(buffer.displayText, "Committed")
//    }
//
//    // MARK: - BUG-001: Segment Overwrite on Engine Restart (Monotonic Time Bug)
//
//    func testTimingDataManager_currentBehavior_overlappingStartTimes_canOverwriteEarlierSegments() {
//        // This test documents the current failure mode:
//        // If timestamps restart at ~0 after task restart and merge is keyed by startTime,
//        // earlier segments can be overwritten.
//        //
//        // Keep this test as “documentation of the bug” even after fixing by changing it to:
//        // - XCTExpectFailure when fixed, OR
//        // - assert that overwrite does NOT happen, depending on the chosen fix.
//        let manager: TimingDataManager = TimingDataManager.shared
//        manager.clearSegments()
//
//        let task1: [TranscriptionSegment] = [
//            TranscriptionSegment(text: "Hello", startTime: 0.0, endTime: 1.0, confidence: 0.9),
//            TranscriptionSegment(text: "world", startTime: 1.0, endTime: 2.0, confidence: 0.9)
//        ]
//        manager.mergeSegments(task1)
//        XCTAssertEqual(manager.segments.count, 2)
//
//        let task2Restarted: [TranscriptionSegment] = [
//            TranscriptionSegment(text: "How", startTime: 0.0, endTime: 1.0, confidence: 0.9),
//            TranscriptionSegment(text: "are", startTime: 1.0, endTime: 2.0, confidence: 0.9)
//        ]
//        manager.mergeSegments(task2Restarted)
//
//        // If the manager replaces by startTime, we end up with 2 segments (overwritten).
//        // If the manager has already been fixed, this may become 4.
//        if manager.segments.count == 2 {
//            let texts: [String] = manager.segments.map(\.text)
//            XCTAssertFalse(texts.contains("Hello"), "Bug reproduced: first utterance overwritten.")
//            XCTAssertTrue(texts.contains("How"), "New utterance exists.")
//        } else {
//            XCTFail("Expected overwrite behavior to be present for documentation. If fixed, update this test to XCTExpectFailure or invert the assertion.")
//        }
//
//        manager.clearSegments()
//    }
//
//    func testTimingDataManager_desiredBehavior_taskRestartWithOffset_accumulatesWithoutOverwrite() {
//        let manager: TimingDataManager = TimingDataManager.shared
//        manager.clearSegments()
//
//        // Task 1: 0-2s
//        let task1: [TranscriptionSegment] = [
//            TranscriptionSegment(text: "Hello", startTime: 0.0, endTime: 1.0, confidence: 0.9),
//            TranscriptionSegment(text: "world", startTime: 1.0, endTime: 2.0, confidence: 0.9)
//        ]
//        manager.mergeSegments(task1)
//        XCTAssertEqual(manager.segments.count, 2)
//
//        // Task 2 restarts, but engine applies offset to keep session timeline monotonic.
//        let offset: TimeInterval = 3.0
//        let task2Raw: [TranscriptionSegment] = [
//            TranscriptionSegment(text: "How", startTime: 0.0, endTime: 1.0, confidence: 0.9),
//            TranscriptionSegment(text: "are", startTime: 1.0, endTime: 2.0, confidence: 0.9)
//        ]
//        let task2Offset: [TranscriptionSegment] = task2Raw.map { seg in
//            TranscriptionSegment(
//                text: seg.text,
//                startTime: seg.startTime + offset,
//                endTime: seg.endTime + offset,
//                confidence: seg.confidence
//            )
//        }
//
//        manager.mergeSegments(task2Offset)
//
//        XCTAssertEqual(manager.segments.count, 4, "Desired: both tasks are accumulated with no overwrite when offsets are monotonic.")
//        let texts: [String] = manager.segments.map(\.text)
//        XCTAssertTrue(texts.contains("Hello"))
//        XCTAssertTrue(texts.contains("world"))
//        XCTAssertTrue(texts.contains("How"))
//        XCTAssertTrue(texts.contains("are"))
//
//        // Verify monotonic time ordering.
//        let starts: [TimeInterval] = manager.segments.map(\.startTime).sorted()
//        XCTAssertEqual(starts, [0.0, 1.0, 3.0, 4.0], "Expected offset applied to second task start times.")
//
//        manager.clearSegments()
//    }
//
//    func testTimingDataManager_futureDesiredBehavior_stableIdentityAvoidsOverwriteEvenWithoutOffset() {
//        // This is the “endgame” behavior for BUG-001:
//        // even if an engine accidentally emits overlapping timestamps,
//        // TimingDataManager should not overwrite previously persisted segments
//        // unless it is a true correction from the same rolling window.
//        //
//        // This requires a stable segment identity (UUID / run ID / composite ID),
//        // which may not exist yet in TranscriptionSegment.
//        XCTExpectFailure("Not implemented: requires stable segment identity in TranscriptionSegment + mergeSegments logic that does not key solely on startTime.")
//
//        let manager: TimingDataManager = TimingDataManager.shared
//        manager.clearSegments()
//
//        let task1: [TranscriptionSegment] = [
//            TranscriptionSegment(text: "Hello", startTime: 0.0, endTime: 1.0, confidence: 0.9),
//            TranscriptionSegment(text: "world", startTime: 1.0, endTime: 2.0, confidence: 0.9)
//        ]
//        manager.mergeSegments(task1)
//
//        let task2Overlapping: [TranscriptionSegment] = [
//            TranscriptionSegment(text: "How", startTime: 0.0, endTime: 1.0, confidence: 0.9),
//            TranscriptionSegment(text: "are", startTime: 1.0, endTime: 2.0, confidence: 0.9)
//        ]
//        manager.mergeSegments(task2Overlapping)
//
//        XCTAssertEqual(manager.segments.count, 4, "Future desired behavior: do not overwrite earlier segments simply because times overlap.")
//        manager.clearSegments()
//    }
//
//    // MARK: - TASK-027B: Stop / Cancel contract (error filtering)
//
//    func testIgnorableError_cancellationIsIgnored() {
//        let error: CancellationError = CancellationError()
//        XCTAssertTrue(isIgnorableTranscriptionError(error), "Cancellation should not be treated as a user-facing failure.")
//    }
//
//    func testIgnorableError_userCancelledNSErrorIsIgnored() {
//        let error: NSError = NSError(domain: NSCocoaErrorDomain, code: NSUserCancelledError, userInfo: nil)
//        XCTAssertTrue(isIgnorableTranscriptionError(error), "User cancelled errors should not be surfaced as failures.")
//    }
//
//    func testIgnorableError_randomNSErrorIsNotIgnored() {
//        let error: NSError = NSError(domain: "com.example.test", code: 12345, userInfo: nil)
//        XCTAssertFalse(isIgnorableTranscriptionError(error), "Unknown errors should be handled and surfaced (or mapped) appropriately.")
//    }
//
//    // MARK: - TASK-027C: Monotonic session offsets (pure logic tests)
//
//    func testSessionOffsetCalculator_initialOffsetIsZero() {
//        let calculator: SessionOffsetCalculator = SessionOffsetCalculator()
//        XCTAssertEqual(calculator.currentOffset, 0.0, accuracy: Constants.timingAccuracy)
//    }
//
//    func testSessionOffsetCalculator_updatesToLastEndTime() {
//        let calculator: SessionOffsetCalculator = SessionOffsetCalculator()
//
//        calculator.observeFinalSegmentEndTime(2.0)
//        XCTAssertEqual(calculator.currentOffset, 2.0, accuracy: Constants.timingAccuracy)
//
//        // Later update should never decrease.
//        calculator.observeFinalSegmentEndTime(1.0)
//        XCTAssertEqual(calculator.currentOffset, 2.0, accuracy: Constants.timingAccuracy)
//
//        calculator.observeFinalSegmentEndTime(5.5)
//        XCTAssertEqual(calculator.currentOffset, 5.5, accuracy: Constants.timingAccuracy)
//    }
//}
//
//// MARK: - Reference models and helpers for TDD
//
///// A minimal reference implementation of the required transcript accumulation semantics.
///// This is NOT production code; it exists so tests can specify correct behavior independent of engine quirks.
/////
///// Intended semantics (from refined tasks / ADR):
///// - finalizedText is append-only and stable.
///// - volatileText replaces itself on every partial update.
///// - on final: append to finalizedText and clear volatileText.
///// - stop may flush volatile into finalized; cancel may discard volatile (configurable).
//private final class TranscriptBufferReference {
//
//    private(set) var finalizedText: String = ""
//    private(set) var volatileText: String = ""
//
//    var displayText: String {
//        if finalizedText.isEmpty { return volatileText }
//        if volatileText.isEmpty { return finalizedText }
//        return finalizedText + " " + volatileText
//    }
//
//    func apply(_ event: TranscriptBufferEvent) {
//        switch event {
//        case .partial(let text):
//            volatileText = text
//        case .final(let text):
//            commitFinal(text)
//        }
//    }
//
//    func stop(flushVolatileIntoFinalized: Bool) {
//        if flushVolatileIntoFinalized, !volatileText.isEmpty {
//            commitFinal(volatileText)
//        }
//        volatileText = ""
//    }
//
//    func cancel(discardVolatile: Bool) {
//        if discardVolatile {
//            volatileText = ""
//        }
//    }
//
//    private func commitFinal(_ text: String) {
//        if finalizedText.isEmpty {
//            finalizedText = text
//        } else if text.isEmpty {
//            // no-op
//        } else {
//            finalizedText = finalizedText + " " + text
//        }
//        volatileText = ""
//    }
//}
//
//private enum TranscriptBufferEvent {
//    case partial(text: String)
//    case final(text: String)
//}
//
///// Encodes the “monotonic offset” rule required to avoid overlapping timestamps across restarts.
/////
///// In production, this should be driven by finalized segment end times on the session timeline.
//private struct SessionOffsetCalculator {
//
//    private(set) var currentOffset: TimeInterval = 0.0
//
//    mutating func observeFinalSegmentEndTime(_ endTime: TimeInterval) {
//        guard endTime.isFinite else { return }
//        if endTime > currentOffset {
//            currentOffset = endTime
//        }
//    }
//}
//
///// Filters errors that should not surface as “real failures” to the user.
///// This should match the engine’s error mapping strategy.
//private func isIgnorableTranscriptionError(_ error: Error) -> Bool {
//    if error is CancellationError { return true }
//
//    let nsError: NSError = error as NSError
//    if nsError.domain == NSCocoaErrorDomain, nsError.code == NSUserCancelledError {
//        return true
//    }
//
//    return false
//}
//
//// MARK: - Test-only helpers (matches existing patterns used in other tests)
//
//extension TimingDataManager {
//    /// Clears segments to support deterministic unit tests.
//    /// This should remain in production as a debug/testing hook, or be available behind a DEBUG build flag.
//    @MainActor func clearSegments() {
//        self.updateSegments([])
//    }
//}
