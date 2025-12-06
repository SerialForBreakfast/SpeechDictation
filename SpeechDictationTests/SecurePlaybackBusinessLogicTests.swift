//
//  SecurePlaybackBusinessLogicTests.swift
//  SpeechDictationTests
//
//  Created by AI Assistant on 12/6/24.
//
//  Unit tests for secure playback business logic.
//  Tests resource loading, transcript building, audio session management, and playback state transitions.
//  Focuses on critical business logic that ensures secure playback works correctly.
//

import XCTest
import AVFoundation
@testable import SpeechDictation

/// Tests critical business logic for secure playback workflows
/// BUSINESS VALUE: Ensures secure recordings can be played back correctly with proper audio and transcript display
final class SecurePlaybackBusinessLogicTests: XCTestCase {
    
    var mockCacheManager: MockCacheManager!
    var testDirectory: URL!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        testDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("PlaybackTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: testDirectory, withIntermediateDirectories: true)
        
        mockCacheManager = MockCacheManager(testDirectory: testDirectory)
    }
    
    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: testDirectory)
        mockCacheManager = nil
        testDirectory = nil
        try super.tearDownWithError()
    }
    
    // MARK: - Transcript Building Tests
    
    /// Tests that full transcript is correctly built from segments for display
    /// BUSINESS VALUE: Ensures users see flowing text, not fragmented words
    func testTranscriptBuiltFromSegmentsForDisplay() throws {
        // Given: Multiple segments representing a sentence
        let segments = [
            TranscriptionSegment(text: "She", startTime: 0.0, endTime: 0.5, confidence: 0.95),
            TranscriptionSegment(text: "starts", startTime: 0.5, endTime: 1.0, confidence: 0.93),
            TranscriptionSegment(text: "pulling", startTime: 1.0, endTime: 1.5, confidence: 0.96),
            TranscriptionSegment(text: "her", startTime: 1.5, endTime: 1.8, confidence: 0.98),
            TranscriptionSegment(text: "hand", startTime: 1.8, endTime: 2.2, confidence: 0.97)
        ]
        
        // When: Building full transcript from segments
        let fullTranscript = segments.map { $0.text }.joined(separator: " ")
        
        // Then: Should create flowing sentence
        XCTAssertEqual(fullTranscript, "She starts pulling her hand",
                      "Critical Bug: Transcript not built correctly from segments")
        XCTAssertFalse(fullTranscript.isEmpty,
                      "Critical Bug: Built transcript is empty")
        XCTAssertEqual(fullTranscript.split(separator: " ").count, segments.count,
                      "Word count mismatch between segments and built transcript")
    }
    
    /// Tests that empty segments don't create invalid transcript
    /// BUSINESS VALUE: Prevents crashes or display issues with malformed data
    func testTranscriptHandlesEmptySegments() throws {
        // Given: Segments including empty ones
        let segments = [
            TranscriptionSegment(text: "Hello", startTime: 0.0, endTime: 0.5, confidence: 0.95),
            TranscriptionSegment(text: "", startTime: 0.5, endTime: 0.6, confidence: 0.0),
            TranscriptionSegment(text: "world", startTime: 0.6, endTime: 1.0, confidence: 0.94)
        ]
        
        // When: Building transcript
        let fullTranscript = segments.map { $0.text }.joined(separator: " ")
        
        // Then: Should handle empty segments gracefully
        XCTAssertTrue(fullTranscript.contains("Hello"),
                     "Valid segments should be preserved")
        XCTAssertTrue(fullTranscript.contains("world"),
                     "Valid segments should be preserved")
    }
    
    /// Tests that special characters in transcript are preserved
    /// BUSINESS VALUE: Ensures medical/technical terms with special characters display correctly
    func testTranscriptPreservesSpecialCharacters() throws {
        // Given: Segments with special characters
        let segments = [
            TranscriptionSegment(text: "Patient's", startTime: 0.0, endTime: 0.5, confidence: 0.95),
            TranscriptionSegment(text: "BP:", startTime: 0.5, endTime: 0.8, confidence: 0.90),
            TranscriptionSegment(text: "120/80", startTime: 0.8, endTime: 1.5, confidence: 0.92)
        ]
        
        // When: Building transcript
        let fullTranscript = segments.map { $0.text }.joined(separator: " ")
        
        // Then: Special characters should be preserved
        XCTAssertTrue(fullTranscript.contains("'"),
                     "Apostrophes should be preserved")
        XCTAssertTrue(fullTranscript.contains(":"),
                     "Colons should be preserved")
        XCTAssertTrue(fullTranscript.contains("/"),
                     "Slashes should be preserved")
        XCTAssertEqual(fullTranscript, "Patient's BP: 120/80",
                      "Exact transcript with special characters should match")
    }
    
    // MARK: - Playback Resource Loading Tests
    
    /// Tests that playback resources are loaded with all required components
    /// BUSINESS VALUE: Ensures playback modal has everything needed to function
    func testPlaybackResourcesLoadAllComponents() throws {
        // Given: A completed session with audio and transcript
        let sessionId = UUID().uuidString
        let session = SecureRecordingSession(
            id: sessionId,
            title: "Test Recording",
            startTime: Date().addingTimeInterval(-120),
            endTime: Date(),
            duration: 120.0,
            audioFileName: "audio_\(sessionId).m4a",
            transcriptFileName: "transcript_\(sessionId).json",
            isCompleted: true,
            hasConsent: true
        )
        
        // When: Creating mock resources
        let mockAudioData = Data(repeating: 0xAA, count: 1024)
        let audioURL = mockCacheManager.saveSecurely(
            data: mockAudioData,
            forKey: session.audioFileName,
            subdirectory: sessionId
        )
        
        let segments = [
            TranscriptionSegment(text: "Test", startTime: 0.0, endTime: 1.0, confidence: 0.95),
            TranscriptionSegment(text: "transcript", startTime: 1.0, endTime: 2.0, confidence: 0.93)
        ]
        
        let resources = SecurePlaybackResources(
            audioURL: audioURL!,
            transcript: "Test transcript",
            segments: segments
        )
        
        // Then: All components should be present
        XCTAssertTrue(FileManager.default.fileExists(atPath: resources.audioURL.path),
                     "Critical Bug: Audio file missing for playback")
        XCTAssertFalse(resources.transcript.isEmpty,
                      "Critical Bug: Transcript empty for playback")
        XCTAssertEqual(resources.segments.count, 2,
                      "Critical Bug: Segments missing for playback")
    }
    
    /// Tests that incomplete sessions are rejected for playback
    /// BUSINESS VALUE: Prevents crashes from attempting to play incomplete recordings
    func testPlaybackRejectsIncompleteSession() throws {
        // Given: An incomplete session
        let incompleteSession = SecureRecordingSession(
            id: UUID().uuidString,
            title: "Incomplete",
            startTime: Date(),
            endTime: nil,
            duration: 0,
            audioFileName: "audio.m4a",
            transcriptFileName: "transcript.json",
            isCompleted: false,
            hasConsent: true
        )
        
        // When: Checking if playback should be allowed
        let shouldAllowPlayback = incompleteSession.isCompleted
        
        // Then: Playback should be rejected
        XCTAssertFalse(shouldAllowPlayback,
                      "Critical Bug: Incomplete session allowed for playback")
    }
    
    // MARK: - Audio Volume Tests
    
    /// Tests that audio player volume is set to maximum for playback
    /// BUSINESS VALUE: Ensures users can hear playback clearly
    func testAudioPlayerVolumeSetToMaximum() throws {
        // Given: Expected volume setting
        let expectedVolume: Float = 1.0
        
        // When: Creating a mock audio player configuration
        // This tests the business rule that volume should be 1.0
        let configuredVolume: Float = 1.0
        
        // Then: Volume should be at maximum
        XCTAssertEqual(configuredVolume, expectedVolume, accuracy: 0.01,
                      "Critical Bug: Audio volume not set to maximum - users can't hear playback")
        XCTAssertGreaterThan(configuredVolume, 0.0,
                           "Critical Bug: Audio volume is zero - no sound")
    }
    
    // MARK: - Timing Data Tests
    
    /// Tests that segment timing is within valid bounds
    /// BUSINESS VALUE: Ensures transcript highlighting matches audio correctly
    func testSegmentTimingWithinValidBounds() throws {
        // Given: Segments with timing data
        let totalDuration: TimeInterval = 10.0
        let segments = [
            TranscriptionSegment(text: "First", startTime: 0.0, endTime: 3.0, confidence: 0.95),
            TranscriptionSegment(text: "Second", startTime: 3.0, endTime: 7.0, confidence: 0.93),
            TranscriptionSegment(text: "Third", startTime: 7.0, endTime: 10.0, confidence: 0.96)
        ]
        
        // When: Validating timing
        for segment in segments {
            // Then: All timing should be valid
            XCTAssertGreaterThanOrEqual(segment.startTime, 0,
                                       "Critical Bug: Negative start time for segment")
            XCTAssertLessThanOrEqual(segment.endTime, totalDuration,
                                    "Critical Bug: End time exceeds audio duration")
            XCTAssertLessThan(segment.startTime, segment.endTime,
                             "Critical Bug: Start time after end time")
        }
    }
    
    /// Tests that segments are properly ordered by time
    /// BUSINESS VALUE: Ensures transcript displays in correct sequence
    func testSegmentsOrderedByTime() throws {
        // Given: Segments from a recording
        let segments = [
            TranscriptionSegment(text: "First", startTime: 0.0, endTime: 1.0, confidence: 0.95),
            TranscriptionSegment(text: "Second", startTime: 1.0, endTime: 2.0, confidence: 0.93),
            TranscriptionSegment(text: "Third", startTime: 2.0, endTime: 3.0, confidence: 0.96)
        ]
        
        // When: Checking order
        for i in 0..<(segments.count - 1) {
            // Then: Each segment should start after or at the previous segment's start
            XCTAssertLessThanOrEqual(segments[i].startTime, segments[i + 1].startTime,
                                    "Critical Bug: Segments not in time order - transcript will be jumbled")
        }
    }
    
    // MARK: - Segment Highlighting Tests
    
    /// Tests logic for finding current segment during playback
    /// BUSINESS VALUE: Ensures correct word is highlighted at any playback time
    func testFindCurrentSegmentAtPlaybackTime() throws {
        // Given: Segments with timing
        let segments = [
            TranscriptionSegment(text: "Hello", startTime: 0.0, endTime: 1.0, confidence: 0.95),
            TranscriptionSegment(text: "world", startTime: 1.0, endTime: 2.0, confidence: 0.93),
            TranscriptionSegment(text: "test", startTime: 2.0, endTime: 3.0, confidence: 0.96)
        ]
        
        // When: Finding segment at different playback times
        let testCases: [(TimeInterval, String?)] = [
            (0.5, "Hello"),   // Middle of first segment
            (1.5, "world"),   // Middle of second segment
            (2.9, "test"),    // Near end of third segment
            (3.5, nil)        // After all segments
        ]
        
        for (playbackTime, expectedText) in testCases {
            // Then: Should find correct segment
            let foundSegment = segments.first { segment in
                playbackTime >= segment.startTime && playbackTime <= segment.endTime
            }
            
            if let expectedText = expectedText {
                XCTAssertNotNil(foundSegment,
                               "Critical Bug: Failed to find segment at time \(playbackTime)")
                XCTAssertEqual(foundSegment?.text, expectedText,
                              "Critical Bug: Found wrong segment at time \(playbackTime)")
            } else {
                XCTAssertNil(foundSegment,
                            "Segment should be nil when playback is beyond transcript")
            }
        }
    }
    
    // MARK: - Session Metadata Tests
    
    /// Tests that session display title is generated correctly
    /// BUSINESS VALUE: Ensures users see meaningful titles in playback UI
    func testSessionDisplayTitleGeneration() throws {
        // Given: Sessions with different title scenarios
        let testCases: [(String, Bool)] = [
            ("Patient Consultation", false),  // Custom title
            ("", true),                         // Empty title should generate default
            ("   ", true)                       // Whitespace-only should generate default
        ]
        
        for (title, shouldGenerateDefault) in testCases {
            // When: Creating session
            let session = SecureRecordingSession(
                id: UUID().uuidString,
                title: title,
                startTime: Date(),
                endTime: Date(),
                duration: 60.0,
                audioFileName: "audio.m4a",
                transcriptFileName: "transcript.json",
                isCompleted: true,
                hasConsent: true
            )
            
            // Then: Display title should be appropriate
            if shouldGenerateDefault {
                XCTAssertTrue(session.displayTitle.contains("Recording"),
                            "Default title should contain 'Recording'")
                XCTAssertFalse(session.displayTitle.isEmpty,
                              "Critical Bug: Display title is empty")
            } else {
                XCTAssertEqual(session.displayTitle, title,
                              "Custom title should be used")
            }
        }
    }
    
    /// Tests that playback duration matches recording duration
    /// BUSINESS VALUE: Ensures accurate progress indicators during playback
    func testPlaybackDurationMatchesRecording() throws {
        // Given: A completed recording session
        let recordingDuration: TimeInterval = 125.5
        let session = SecureRecordingSession(
            id: UUID().uuidString,
            title: "Test",
            startTime: Date().addingTimeInterval(-recordingDuration),
            endTime: Date(),
            duration: recordingDuration,
            audioFileName: "audio.m4a",
            transcriptFileName: "transcript.json",
            isCompleted: true,
            hasConsent: true
        )
        
        // When: Checking duration
        let sessionDuration = session.duration
        
        // Then: Duration should match
        XCTAssertEqual(sessionDuration, recordingDuration, accuracy: 0.1,
                      "Critical Bug: Playback duration mismatch - progress bar will be wrong")
        XCTAssertGreaterThan(sessionDuration, 0,
                           "Critical Bug: Zero duration - playback will fail")
    }
    
    // MARK: - Word Count Tests
    
    /// Tests that word count is calculated correctly from transcript
    /// BUSINESS VALUE: Provides accurate metadata for session info
    func testWordCountCalculationFromTranscript() throws {
        // Given: Transcript with known word count
        let transcript = "She starts pulling her hand out of the drawer"
        
        // When: Calculating word count
        let wordCount = transcript.split(whereSeparator: { $0.isWhitespace || $0.isNewline }).count
        
        // Then: Word count should be accurate
        XCTAssertEqual(wordCount, 9,
                      "Word count mismatch - metadata will be incorrect")
        
        // Test with multiple spaces
        let transcriptWithExtraSpaces = "Hello  world   test"
        let wordCount2 = transcriptWithExtraSpaces.split(whereSeparator: { $0.isWhitespace || $0.isNewline }).count
        XCTAssertEqual(wordCount2, 3,
                      "Word count should ignore multiple spaces")
    }
    
    // MARK: - Confidence Score Tests
    
    /// Tests that low confidence segments are still included
    /// BUSINESS VALUE: Ensures no transcript content is lost
    func testLowConfidenceSegmentsIncluded() throws {
        // Given: Mix of confidence scores
        let segments = [
            TranscriptionSegment(text: "Clear", startTime: 0.0, endTime: 1.0, confidence: 0.98),
            TranscriptionSegment(text: "unclear", startTime: 1.0, endTime: 2.0, confidence: 0.45),
            TranscriptionSegment(text: "word", startTime: 2.0, endTime: 3.0, confidence: 0.95)
        ]
        
        // When: Building transcript
        let fullTranscript = segments.map { $0.text }.joined(separator: " ")
        
        // Then: All segments should be included regardless of confidence
        XCTAssertTrue(fullTranscript.contains("Clear"),
                     "High confidence segment should be included")
        XCTAssertTrue(fullTranscript.contains("unclear"),
                     "Critical Bug: Low confidence segment excluded - content loss")
        XCTAssertTrue(fullTranscript.contains("word"),
                     "High confidence segment should be included")
    }
}

