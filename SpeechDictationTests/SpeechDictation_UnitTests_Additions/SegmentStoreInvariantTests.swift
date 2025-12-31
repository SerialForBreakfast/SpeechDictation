//
//  SegmentStoreInvariantTests.swift
//  SpeechDictationTests
//
//  Created: 2025-12-13
//
//  Purpose:
//  Unit tests that protect segment merge invariants required for long-form transcription:
//
//  - No accidental overwrite of earlier session segments on engine restarts (BUG-001).
//  - No unbounded growth from duplicate/volatile updates.
//  - Deterministic ordering and monotonic time ranges for reliable playback highlighting.
//
//  These tests are intentionally “business-logic only” and avoid microphone/Speech API dependencies.
//

import Foundation
import XCTest
@testable import SpeechDictation

@MainActor
final class SegmentStoreInvariantTests: XCTestCase {

    override func setUp() async throws {
        try await super.setUp()
        TimingDataManager.shared.clearSegments()
    }

    override func tearDown() async throws {
        TimingDataManager.shared.clearSegments()
        try await super.tearDown()
    }

    func testTimingDataManager_mergeSegments_sortsByStartTime() {
        let manager: TimingDataManager = TimingDataManager.shared
        manager.clearSegments()

        let segments: [TranscriptionSegment] = [
            TranscriptionSegment(text: "B", startTime: 2.0, endTime: 3.0, confidence: 0.9),
            TranscriptionSegment(text: "A", startTime: 0.0, endTime: 1.0, confidence: 0.9),
            TranscriptionSegment(text: "C", startTime: 1.0, endTime: 2.0, confidence: 0.9)
        ]

        manager.mergeSegments(segments)

        let starts: [TimeInterval] = manager.segments.map(\.startTime)
        XCTAssertEqual(starts, starts.sorted(), "Segments should be stored sorted by startTime for stable UI/playback logic.")

        manager.clearSegments()
    }

    func testTimingDataManager_mergeSegments_deduplicatesExactDuplicateSegments() {
        let manager: TimingDataManager = TimingDataManager.shared
        manager.clearSegments()

        let segment: TranscriptionSegment = TranscriptionSegment(text: "Hello", startTime: 0.0, endTime: 1.0, confidence: 0.9)
        manager.mergeSegments([segment, segment])

        XCTAssertEqual(manager.segments.count, 1, "Exact duplicate segments should not be stored twice.")
        manager.clearSegments()
    }

    func testTimingDataManager_mergeSegments_replacesSameStartTime_withHigherConfidenceCorrection() {
        // This is a realistic correction path: same timing bucket, better confidence and/or corrected text.
        let manager: TimingDataManager = TimingDataManager.shared
        manager.clearSegments()

        let v1: TranscriptionSegment = TranscriptionSegment(text: "How ar", startTime: 0.0, endTime: 1.0, confidence: 0.6)
        manager.mergeSegments([v1])
        XCTAssertEqual(manager.segments.count, 1)
        XCTAssertEqual(manager.segments[0].text, "How ar")

        let v2: TranscriptionSegment = TranscriptionSegment(text: "How are", startTime: 0.0, endTime: 1.0, confidence: 0.8)
        manager.mergeSegments([v2])
        XCTAssertEqual(manager.segments.count, 1, "Correction should replace within the same startTime key.")
        XCTAssertEqual(manager.segments[0].text, "How are")
        XCTAssertEqual(manager.segments[0].confidence, 0.8, accuracy: 0.000_1)

        manager.clearSegments()
    }

    func testTimingDataManager_mergeSegments_refusesNegativeOrNaNTimes() {
        let manager: TimingDataManager = TimingDataManager.shared
        manager.clearSegments()

        let invalid: [TranscriptionSegment] = [
            TranscriptionSegment(text: "Bad", startTime: -1.0, endTime: 0.0, confidence: 0.9),
            TranscriptionSegment(text: "NaN", startTime: Double.nan, endTime: 1.0, confidence: 0.9)
        ]
        manager.mergeSegments(invalid)

        XCTAssertEqual(manager.segments.count, 0, "Invalid segments should be dropped, not stored.")
        manager.clearSegments()
    }

    func testSegmentIdentityStrategy_futureStableIdentity_preventsOverwriteOnRestartEvenWithOverlappingTimes() {
        XCTExpectFailure("Not implemented: requires stable segment identity (UUID/taskID/runID) in TranscriptionSegment or merge policy.")

        // Target behavior:
        // - Overlapping startTimes coming from a restarted engine should NOT overwrite previous committed segments
        //   unless they are part of the same correction window (same identity).
        let manager: TimingDataManager = TimingDataManager.shared
        manager.clearSegments()

        let task1: [TranscriptionSegment] = [
            TranscriptionSegment(text: "Hello", startTime: 0.0, endTime: 1.0, confidence: 0.9),
            TranscriptionSegment(text: "world", startTime: 1.0, endTime: 2.0, confidence: 0.9)
        ]
        manager.mergeSegments(task1)

        let task2Restarted: [TranscriptionSegment] = [
            TranscriptionSegment(text: "How", startTime: 0.0, endTime: 1.0, confidence: 0.9),
            TranscriptionSegment(text: "are", startTime: 1.0, endTime: 2.0, confidence: 0.9)
        ]
        manager.mergeSegments(task2Restarted)

        XCTAssertEqual(manager.segments.count, 4, "Future: overlapping times should not overwrite earlier segments.")
        manager.clearSegments()
    }
}
