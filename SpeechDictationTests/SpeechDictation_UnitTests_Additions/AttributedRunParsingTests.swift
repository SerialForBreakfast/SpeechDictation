//
//  AttributedRunParsingTests.swift
//  SpeechDictationTests
//
//  Created: 2025-12-13
//
//  Purpose:
//  Unit tests that encode the requirements for converting “attributed transcript runs”
//  (ex: audioTimeRange + confidence) into stable TranscriptionSegment values.
//  These tests are designed to support iOS 26 SpeechTranscriber’s audioTimeRange attribute
//  (which is delivered via attributed string runs), while remaining fully testable on older SDKs.
//
//  References:
//  - Apple docs: SpeechTranscriber.ResultAttributeOption.audioTimeRange
//    https://developer.apple.com/documentation/speech/speechtranscriber/resultattributeoption/audiotimerange
//  - WWDC25 session: “Bring advanced speech-to-text capabilities to your app with SpeechAnalyzer”
//    https://developer.apple.com/videos/play/wwdc2025/277/
//

import Foundation
import XCTest
@testable import SpeechDictation

@MainActor
final class AttributedRunParsingTests: XCTestCase {

    // MARK: - Run-to-segment parsing invariants

    func testRunParser_ordersSegmentsByStartTime_monotonic() {
        let runs: [AttributedTranscriptRun] = [
            AttributedTranscriptRun(text: "world", audioTimeRange: AudioTimeRange(start: 1.0, end: 2.0), confidence: 0.90, isFinal: true),
            AttributedTranscriptRun(text: "Hello", audioTimeRange: AudioTimeRange(start: 0.0, end: 1.0), confidence: 0.95, isFinal: true)
        ]

        let segments: [TranscriptionSegment] = TranscriptRunParserReference.extractSegments(from: runs)

        XCTAssertEqual(segments.count, 2)
        XCTAssertEqual(segments[0].text, "Hello")
        XCTAssertEqual(segments[1].text, "world")
        XCTAssertLessThanOrEqual(segments[0].endTime, segments[1].startTime + 0.000_1)
    }

    func testRunParser_filtersRunsMissingTimeRange() {
        let runs: [AttributedTranscriptRun] = [
            AttributedTranscriptRun(text: "Hello", audioTimeRange: nil, confidence: 0.90, isFinal: true),
            AttributedTranscriptRun(text: "world", audioTimeRange: AudioTimeRange(start: 0.0, end: 1.0), confidence: 0.90, isFinal: true)
        ]

        let segments: [TranscriptionSegment] = TranscriptRunParserReference.extractSegments(from: runs)

        XCTAssertEqual(segments.count, 1)
        XCTAssertEqual(segments[0].text, "world")
    }

    func testRunParser_deduplicatesExactDuplicates() {
        let run: AttributedTranscriptRun = AttributedTranscriptRun(text: "Hello", audioTimeRange: AudioTimeRange(start: 0.0, end: 1.0), confidence: 0.90, isFinal: true)
        let runs: [AttributedTranscriptRun] = [run, run]

        let segments: [TranscriptionSegment] = TranscriptRunParserReference.extractSegments(from: runs)

        XCTAssertEqual(segments.count, 1, "Exact duplicate runs should not create duplicate segments.")
        XCTAssertEqual(segments[0].text, "Hello")
    }

    func testRunParser_replacesTextForSameTimeRange_whenCorrectionArrives() {
        // Business rule:
        // If the speech engine revises the text for the same time range (common for partials),
        // treat it as a correction, not a new segment.
        let runsV1: [AttributedTranscriptRun] = [
            AttributedTranscriptRun(text: "How ar", audioTimeRange: AudioTimeRange(start: 0.0, end: 1.0), confidence: 0.60, isFinal: false)
        ]
        let runsV2: [AttributedTranscriptRun] = [
            AttributedTranscriptRun(text: "How are", audioTimeRange: AudioTimeRange(start: 0.0, end: 1.0), confidence: 0.75, isFinal: false)
        ]

        let segmentsV1: [TranscriptionSegment] = TranscriptRunParserReference.extractSegments(from: runsV1)
        let segmentsV2: [TranscriptionSegment] = TranscriptRunParserReference.extractSegments(from: runsV2)

        XCTAssertEqual(segmentsV1.count, 1)
        XCTAssertEqual(segmentsV2.count, 1)
        XCTAssertEqual(segmentsV1[0].startTime, segmentsV2[0].startTime, accuracy: 0.001)
        XCTAssertEqual(segmentsV1[0].endTime, segmentsV2[0].endTime, accuracy: 0.001)
        XCTAssertEqual(segmentsV2[0].text, "How are", "Corrected run should replace text for the same time range.")
        XCTAssertGreaterThan(segmentsV2[0].confidence, segmentsV1[0].confidence, "Confidence often improves as partial stabilizes.")
    }

    func testRunParser_refusesOverlappingRanges_byDroppingLaterOverlap() {
        // Business rule:
        // Overlaps in a committed timeline complicate playback highlighting and segment merging.
        // We enforce a no-overlap invariant by dropping later segments that overlap.
        //
        // Alternate strategies are possible (clamp, split). If you choose another,
        // update this test to match the chosen policy.
        let runs: [AttributedTranscriptRun] = [
            AttributedTranscriptRun(text: "A", audioTimeRange: AudioTimeRange(start: 0.0, end: 1.0), confidence: 0.90, isFinal: true),
            AttributedTranscriptRun(text: "B", audioTimeRange: AudioTimeRange(start: 0.5, end: 1.5), confidence: 0.90, isFinal: true)
        ]

        let segments: [TranscriptionSegment] = TranscriptRunParserReference.extractSegments(from: runs)

        XCTAssertEqual(segments.count, 1, "Overlapping later segment should be dropped to keep invariant.")
        XCTAssertEqual(segments[0].text, "A")
    }

    // MARK: - Bridge tests: segments feed into TimingDataManager

    func testRunParserSegments_mergeIntoTimingDataManager_withoutDuplicates() {
        // This test guards the “appending volatile into committed transcript” duplication pitfall:
        // if parsed runs contain duplicates or corrected versions, TimingDataManager should not
        // grow without bound for the same timeline window.
        let manager: TimingDataManager = TimingDataManager.shared
        manager.clearSegments()

        let runs: [AttributedTranscriptRun] = [
            AttributedTranscriptRun(text: "Hello", audioTimeRange: AudioTimeRange(start: 0.0, end: 1.0), confidence: 0.90, isFinal: false),
            AttributedTranscriptRun(text: "Hello", audioTimeRange: AudioTimeRange(start: 0.0, end: 1.0), confidence: 0.92, isFinal: false) // duplicate
        ]
        let segments: [TranscriptionSegment] = TranscriptRunParserReference.extractSegments(from: runs)

        manager.mergeSegments(segments)

        XCTAssertEqual(manager.segments.count, 1, "Expected deduped single segment in manager.")
        manager.clearSegments()
    }
}

// MARK: - Test-only types (SDK-agnostic stand-ins)

/// Represents a time range for an attributed transcript run.
/// Mirrors the intent of SpeechTranscriber audioTimeRange metadata.
struct AudioTimeRange: Equatable, Hashable {
    let start: TimeInterval
    let end: TimeInterval
}

/// Represents a single attributed run emitted by a speech engine.
/// In iOS 26, you’d obtain these from AttributedString runs using the audioTimeRange attribute option.
struct AttributedTranscriptRun: Equatable, Hashable {
    let text: String
    let audioTimeRange: AudioTimeRange?
    let confidence: Double
    let isFinal: Bool
}

/// Reference implementation used for TDD.
/// Replace usage with your production run parser once implemented.
enum TranscriptRunParserReference {

    /// Extracts segments by:
    /// - filtering missing/invalid time ranges
    /// - sorting by start time
    /// - deduplicating by (start,end,text)
    /// - handling corrections by preferring later runs for the same (start,end)
    /// - enforcing no-overlap by dropping later overlaps
    static func extractSegments(from runs: [AttributedTranscriptRun]) -> [TranscriptionSegment] {
        // Filter invalid
        let valid: [AttributedTranscriptRun] = runs.filter { run in
            guard let range: AudioTimeRange = run.audioTimeRange else { return false }
            if range.start.isNaN || range.end.isNaN { return false }
            if range.end <= range.start { return false }
            return true
        }

        // Group by exact time range so corrections replace.
        var byRange: [AudioTimeRange: AttributedTranscriptRun] = [:]
        for run in valid {
            guard let range: AudioTimeRange = run.audioTimeRange else { continue }
            // Prefer the later item (last writer wins), which models “latest correction”.
            byRange[range] = run
        }

        // Build segments sorted by range.
        let sortedRanges: [AudioTimeRange] = byRange.keys.sorted { a, b in
            if a.start != b.start { return a.start < b.start }
            return a.end < b.end
        }

        var output: [TranscriptionSegment] = []
        var lastEnd: TimeInterval = -Double.greatestFiniteMagnitude

        for range in sortedRanges {
            guard let run: AttributedTranscriptRun = byRange[range] else { continue }

            // Enforce no-overlap invariant (drop later overlaps).
            if range.start < lastEnd {
                continue
            }

            let segment: TranscriptionSegment = TranscriptionSegment(
                text: run.text,
                startTime: range.start,
                endTime: range.end,
                confidence: Float(run.confidence)
            )
            output.append(segment)
            lastEnd = range.end
        }

        // Deduplicate exact duplicates (defensive)
        var seen: Set<TranscriptionSegmentIdentity> = Set<TranscriptionSegmentIdentity>()
        var deduped: [TranscriptionSegment] = []
        for seg in output {
            let id: TranscriptionSegmentIdentity = TranscriptionSegmentIdentity(text: seg.text, startTime: seg.startTime, endTime: seg.endTime)
            if seen.contains(id) { continue }
            seen.insert(id)
            deduped.append(seg)
        }

        return deduped
    }

    private struct TranscriptionSegmentIdentity: Hashable {
        let text: String
        let startTime: TimeInterval
        let endTime: TimeInterval
    }
}
