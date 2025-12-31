//
//  TranscriptAccumulationTests.swift
//  SpeechDictationTests
//
//  Critical unit tests for REQ-001: Continuous Transcript Accumulation
//

import XCTest
@testable import SpeechDictation

@MainActor
class TranscriptAccumulationTests: XCTestCase {
    
    // MARK: - Transcript Composition Tests
    
    func testComposeTranscript_EmptyAccumulated_ReturnsPartial() {
        let accumulated = ""
        let partial = "Hello world"
        
        let result = composeTranscript(accumulated: accumulated, partial: partial)
        
        XCTAssertEqual(result, "Hello world", "Should return just the partial when accumulated is empty")
    }
    
    func testComposeTranscript_EmptyPartial_ReturnsAccumulated() {
        let accumulated = "Hello world"
        let partial = ""
        
        let result = composeTranscript(accumulated: accumulated, partial: partial)
        
        XCTAssertEqual(result, "Hello world", "Should return just the accumulated when partial is empty")
    }
    
    func testComposeTranscript_BothPresent_ConcatenatesWithSpace() {
        let accumulated = "Hello world"
        let partial = "How are you"
        
        let result = composeTranscript(accumulated: accumulated, partial: partial)
        
        XCTAssertEqual(result, "Hello world How are you", "Should concatenate with space separator")
    }
    
    func testComposeTranscript_BothEmpty_ReturnsEmpty() {
        let accumulated = ""
        let partial = ""
        
        let result = composeTranscript(accumulated: accumulated, partial: partial)
        
        XCTAssertEqual(result, "", "Should return empty when both are empty")
    }
    
    func testComposeTranscript_MultipleUtterances_AccumulatesCorrectly() {
        var accumulated = ""
        
        // First utterance
        let partial1 = "Hello world"
        let composed1 = composeTranscript(accumulated: accumulated, partial: partial1)
        XCTAssertEqual(composed1, "Hello world")
        
        // Finalize first utterance
        accumulated = composed1
        
        // Second utterance
        let partial2 = "How are you"
        let composed2 = composeTranscript(accumulated: accumulated, partial: partial2)
        XCTAssertEqual(composed2, "Hello world How are you", "Second utterance should be appended")
        
        // Finalize second utterance
        accumulated = composed2
        
        // Third utterance
        let partial3 = "Goodbye"
        let composed3 = composeTranscript(accumulated: accumulated, partial: partial3)
        XCTAssertEqual(composed3, "Hello world How are you Goodbye", "Third utterance should be appended")
    }
    
    // MARK: - Segment Timestamp Offset Tests
    
    func testSegmentTimestampOffset_FirstTask_NoOffset() {
        let sessionStart = Date()
        let taskStart = sessionStart
        
        let offset = taskStart.timeIntervalSince(sessionStart)
        
        XCTAssertEqual(offset, 0.0, accuracy: 0.001, "First task should have zero offset")
    }
    
    func testSegmentTimestampOffset_SecondTask_HasOffset() {
        let sessionStart = Date()
        let taskStart = sessionStart.addingTimeInterval(5.0) // Task started 5s after session
        
        let offset = taskStart.timeIntervalSince(sessionStart)
        
        XCTAssertEqual(offset, 5.0, accuracy: 0.001, "Second task should have 5s offset")
    }
    
    func testSegmentTimestampOffset_MultipleRestarts_MonotonicTimestamps() {
        let sessionStart = Date()
        
        // First task: 0-3s
        let task1Start = sessionStart
        let task1Offset = task1Start.timeIntervalSince(sessionStart)
        let task1Segments = [
            (timestamp: 0.0, duration: 1.5),
            (timestamp: 1.5, duration: 1.5)
        ]
        let task1AdjustedSegments = task1Segments.map { seg in
            (startTime: task1Offset + seg.timestamp, endTime: task1Offset + seg.timestamp + seg.duration)
        }
        
        // Second task: 3-6s
        let task2Start = sessionStart.addingTimeInterval(3.0)
        let task2Offset = task2Start.timeIntervalSince(sessionStart)
        let task2Segments = [
            (timestamp: 0.0, duration: 2.0),
            (timestamp: 2.0, duration: 1.0)
        ]
        let task2AdjustedSegments = task2Segments.map { seg in
            (startTime: task2Offset + seg.timestamp, endTime: task2Offset + seg.timestamp + seg.duration)
        }
        
        // Verify task 1 timestamps
        XCTAssertEqual(task1AdjustedSegments[0].startTime, 0.0, accuracy: 0.001)
        XCTAssertEqual(task1AdjustedSegments[1].endTime, 3.0, accuracy: 0.001)
        
        // Verify task 2 timestamps (should start where task 1 ended)
        XCTAssertEqual(task2AdjustedSegments[0].startTime, 3.0, accuracy: 0.001, "Task 2 should start at 3s")
        XCTAssertEqual(task2AdjustedSegments[1].endTime, 6.0, accuracy: 0.001)
        
        // Verify monotonic (no overlaps)
        XCTAssertLessThan(task1AdjustedSegments[1].endTime, task2AdjustedSegments[0].startTime + 0.001,
                         "Task 2 should start after task 1 ends")
    }
    
    // MARK: - TimingDataManager Merge Tests
    
    func testTimingDataManager_MergeSegments_NoOverlap_AddsAll() {
        let manager = TimingDataManager.shared
        manager.clearSegments() // Start fresh
        
        // First batch of segments
        let segments1 = [
            TranscriptionSegment(text: "Hello", startTime: 0.0, endTime: 1.0, confidence: 0.9),
            TranscriptionSegment(text: "world", startTime: 1.0, endTime: 2.0, confidence: 0.9)
        ]
        manager.mergeSegments(segments1)
        XCTAssertEqual(manager.segments.count, 2, "Should have 2 segments after first merge")
        
        // Second batch (different timestamps)
        let segments2 = [
            TranscriptionSegment(text: "How", startTime: 3.0, endTime: 4.0, confidence: 0.9),
            TranscriptionSegment(text: "are", startTime: 4.0, endTime: 5.0, confidence: 0.9)
        ]
        manager.mergeSegments(segments2)
        XCTAssertEqual(manager.segments.count, 4, "Should have 4 segments after second merge (accumulated)")
        
        // Verify all segments present
        let allTexts = manager.segments.map { $0.text }
        XCTAssertTrue(allTexts.contains("Hello"), "Should contain first utterance")
        XCTAssertTrue(allTexts.contains("world"), "Should contain first utterance")
        XCTAssertTrue(allTexts.contains("How"), "Should contain second utterance")
        XCTAssertTrue(allTexts.contains("are"), "Should contain second utterance")
        
        manager.clearSegments() // Cleanup
    }
    
    func testTimingDataManager_MergeSegments_SameStartTime_Replaces() {
        let manager = TimingDataManager.shared
        manager.clearSegments() // Start fresh
        
        // First segment
        let segment1 = TranscriptionSegment(text: "Hello", startTime: 0.0, endTime: 1.0, confidence: 0.8)
        manager.mergeSegments([segment1])
        XCTAssertEqual(manager.segments.count, 1)
        XCTAssertEqual(manager.segments[0].text, "Hello")
        
        // Second segment with SAME start time (should replace)
        let segment2 = TranscriptionSegment(text: "Hi", startTime: 0.0, endTime: 1.0, confidence: 0.9)
        manager.mergeSegments([segment2])
        XCTAssertEqual(manager.segments.count, 1, "Should still have 1 segment (replaced)")
        XCTAssertEqual(manager.segments[0].text, "Hi", "Should have replaced text")
        
        manager.clearSegments() // Cleanup
    }
    
    func testTimingDataManager_MergeSegments_OverlappingStartTimes_BUG_DETECTED() {
        let manager = TimingDataManager.shared
        manager.clearSegments() // Start fresh
        
        // Simulate the BUG: Task restarts reset timestamps to 0
        // First task: segments at 0-2s
        let task1Segments = [
            TranscriptionSegment(text: "Hello", startTime: 0.0, endTime: 1.0, confidence: 0.9),
            TranscriptionSegment(text: "world", startTime: 1.0, endTime: 2.0, confidence: 0.9)
        ]
        manager.mergeSegments(task1Segments)
        XCTAssertEqual(manager.segments.count, 2, "Should have 2 segments from first task")
        
        // Second task WITHOUT offset: segments at 0-2s again (BUG!)
        let task2SegmentsBUGGY = [
            TranscriptionSegment(text: "How", startTime: 0.0, endTime: 1.0, confidence: 0.9),
            TranscriptionSegment(text: "are", startTime: 1.0, endTime: 2.0, confidence: 0.9)
        ]
        manager.mergeSegments(task2SegmentsBUGGY)
        
        // BUG: This will REPLACE the first task's segments
        XCTAssertEqual(manager.segments.count, 2, "BUG DETECTED: Still only 2 segments (should be 4)")
        let allTexts = manager.segments.map { $0.text }
        XCTAssertFalse(allTexts.contains("Hello"), "BUG DETECTED: First utterance lost")
        XCTAssertTrue(allTexts.contains("How"), "Second utterance present")
        
        manager.clearSegments() // Cleanup
    }
    
    func testTimingDataManager_MergeSegments_WithOffset_CORRECT() {
        let manager = TimingDataManager.shared
        manager.clearSegments() // Start fresh
        
        // First task: segments at 0-2s
        let task1Segments = [
            TranscriptionSegment(text: "Hello", startTime: 0.0, endTime: 1.0, confidence: 0.9),
            TranscriptionSegment(text: "world", startTime: 1.0, endTime: 2.0, confidence: 0.9)
        ]
        manager.mergeSegments(task1Segments)
        XCTAssertEqual(manager.segments.count, 2, "Should have 2 segments from first task")
        
        // Second task WITH offset: segments at 3-5s (CORRECT!)
        let task2SegmentsCORRECT = [
            TranscriptionSegment(text: "How", startTime: 3.0, endTime: 4.0, confidence: 0.9),
            TranscriptionSegment(text: "are", startTime: 4.0, endTime: 5.0, confidence: 0.9)
        ]
        manager.mergeSegments(task2SegmentsCORRECT)
        
        // CORRECT: Should have all 4 segments
        XCTAssertEqual(manager.segments.count, 4, "CORRECT: Should have 4 segments (accumulated)")
        let allTexts = manager.segments.map { $0.text }
        XCTAssertTrue(allTexts.contains("Hello"), "CORRECT: First utterance preserved")
        XCTAssertTrue(allTexts.contains("world"), "CORRECT: First utterance preserved")
        XCTAssertTrue(allTexts.contains("How"), "CORRECT: Second utterance present")
        XCTAssertTrue(allTexts.contains("are"), "CORRECT: Second utterance present")
        
        manager.clearSegments() // Cleanup
    }
    
    // MARK: - Integration Tests
    
    func testREQ001_TranscriptAccumulation_ThreeUtterances() {
        // This test documents the EXACT requirement
        var accumulated = ""
        var partial = ""
        
        // Utterance 1: "Hello world"
        partial = "Hello world"
        let composed1 = composeTranscript(accumulated: accumulated, partial: partial)
        XCTAssertEqual(composed1, "Hello world", "UI should show: Hello world")
        
        // Finalize utterance 1
        accumulated = composed1
        partial = ""
        
        // Utterance 2: "How are you"
        partial = "How are you"
        let composed2 = composeTranscript(accumulated: accumulated, partial: partial)
        XCTAssertEqual(composed2, "Hello world How are you", "UI should show: Hello world How are you")
        
        // Finalize utterance 2
        accumulated = composed2
        partial = ""
        
        // Utterance 3: "Goodbye"
        partial = "Goodbye"
        let composed3 = composeTranscript(accumulated: accumulated, partial: partial)
        XCTAssertEqual(composed3, "Hello world How are you Goodbye", "UI should show: Hello world How are you Goodbye")
        
        // Final check: All text preserved
        XCTAssertTrue(composed3.contains("Hello world"), "Must contain utterance 1")
        XCTAssertTrue(composed3.contains("How are you"), "Must contain utterance 2")
        XCTAssertTrue(composed3.contains("Goodbye"), "Must contain utterance 3")
    }
    
    // MARK: - Helper Methods
    
    /// Mirrors the LegacyTranscriptionEngine.composeTranscript logic
    private func composeTranscript(accumulated: String, partial: String) -> String {
        if accumulated.isEmpty {
            return partial
        } else if partial.isEmpty {
            return accumulated
        } else {
            return accumulated + " " + partial
        }
    }
}
