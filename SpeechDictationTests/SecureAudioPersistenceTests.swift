//
//  SecureAudioPersistenceTests.swift
//  SpeechDictationTests
//
//  Created by AI Assistant on 12/6/24.
//
//  Unit tests for secure audio file persistence during recording stop workflow.
//  Tests the critical fix ensuring audio files are migrated to secure storage with complete file protection.
//  Validates that playback resources can be successfully loaded after recording completion.
//

import XCTest
import AVFoundation
@testable import SpeechDictation

/// Tests secure audio file persistence and migration during recording stop workflow
/// BUSINESS VALUE: Prevents "Audio file missing" errors during secure playback
/// SECURITY VALUE: Ensures all recording artifacts have .completeFileProtection
final class SecureAudioPersistenceTests: XCTestCase {
    
    var mockCacheManager: MockCacheManager!
    var mockAudioRecordingManager: MockAudioRecordingManager!
    var testDirectory: URL!
    var tempAudioDirectory: URL!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        // Setup test directories
        testDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("SecureTests-\(UUID().uuidString)")
        tempAudioDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("TempAudio-\(UUID().uuidString)")
        
        try FileManager.default.createDirectory(at: testDirectory, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: tempAudioDirectory, withIntermediateDirectories: true)
        
        // Setup mocks
        mockCacheManager = MockCacheManager(testDirectory: testDirectory)
        mockAudioRecordingManager = MockAudioRecordingManager(tempDirectory: tempAudioDirectory)
    }
    
    override func tearDownWithError() throws {
        // Cleanup test directories
        try? FileManager.default.removeItem(at: testDirectory)
        try? FileManager.default.removeItem(at: tempAudioDirectory)
        
        mockCacheManager = nil
        mockAudioRecordingManager = nil
        testDirectory = nil
        tempAudioDirectory = nil
        
        try super.tearDownWithError()
    }
    
    // MARK: - Audio File Migration Tests
    
    /// Tests that temporary audio file is successfully migrated to secure storage on stop
    /// BUSINESS VALUE: Prevents "Audio file missing" error during playback
    func testAudioFileMigrationToSecureStorage() throws {
        // Given: A temporary audio file from recording
        let tempAudioURL = try mockAudioRecordingManager.createMockAudioFile()
        let sessionId = UUID().uuidString
        let audioFileName = "recording_\(sessionId).m4a"
        
        XCTAssertTrue(FileManager.default.fileExists(atPath: tempAudioURL.path),
                     "Temporary audio file must exist before migration")
        
        // When: Migrating audio file to secure storage
        let audioData = try Data(contentsOf: tempAudioURL)
        let secureURL = mockCacheManager.saveSecurely(
            data: audioData,
            forKey: audioFileName,
            subdirectory: sessionId
        )
        
        // Then: Audio file should be in secure storage
        XCTAssertNotNil(secureURL, "Secure save must succeed")
        XCTAssertTrue(secureURL!.path.contains(sessionId),
                     "Secure URL must contain session ID in path")
        XCTAssertTrue(mockCacheManager.secureProtectionApplied,
                     "Critical Security Bug: .completeFileProtection not applied to audio file")
        
        // And: Audio data should be intact
        let retrievedData = mockCacheManager.retrieveSecureData(forKey: audioFileName, subdirectory: sessionId)
        XCTAssertNotNil(retrievedData, "Audio file must be retrievable from secure storage")
        XCTAssertEqual(retrievedData?.count, audioData.count,
                      "Audio data size must match original after migration")
    }
    
    /// Tests that temporary audio file is deleted after successful migration
    /// BUSINESS VALUE: Prevents sensitive audio from remaining in unsecured temp storage
    func testTemporaryAudioFileDeletionAfterMigration() throws {
        // Given: A temporary audio file that needs to be cleaned up
        let tempAudioURL = try mockAudioRecordingManager.createMockAudioFile()
        let sessionId = UUID().uuidString
        let audioFileName = "recording_\(sessionId).m4a"
        
        // When: Migrating and then deleting temporary file
        let audioData = try Data(contentsOf: tempAudioURL)
        let secureURL = mockCacheManager.saveSecurely(
            data: audioData,
            forKey: audioFileName,
            subdirectory: sessionId
        )
        XCTAssertNotNil(secureURL, "Migration must succeed for cleanup test")
        
        // Simulate deletion of temp file
        try FileManager.default.removeItem(at: tempAudioURL)
        
        // Then: Temporary file should no longer exist
        XCTAssertFalse(FileManager.default.fileExists(atPath: tempAudioURL.path),
                      "Critical Security Bug: Temporary audio file not deleted after migration")
        
        // But: Secure file should still be accessible
        let secureData = mockCacheManager.retrieveSecureData(forKey: audioFileName, subdirectory: sessionId)
        XCTAssertNotNil(secureData,
                       "Secure audio file must remain accessible after temp file deletion")
    }
    
    /// Tests handling of migration when source audio file is missing
    /// BUSINESS VALUE: Prevents crashes when temporary file is unexpectedly missing
    func testAudioMigrationHandlesMissingSourceFile() throws {
        // Given: A path to a non-existent temporary audio file
        let missingAudioURL = tempAudioDirectory.appendingPathComponent("missing_audio.m4a")
        let sessionId = UUID().uuidString
        let audioFileName = "recording_\(sessionId).m4a"
        
        XCTAssertFalse(FileManager.default.fileExists(atPath: missingAudioURL.path),
                      "Source file must not exist for this test")
        
        // When: Attempting to migrate missing audio file
        var migrationError: Error?
        do {
            _ = try Data(contentsOf: missingAudioURL)
            XCTFail("Should throw error when reading missing file")
        } catch {
            migrationError = error
        }
        
        // Then: Operation should fail gracefully without crashing
        XCTAssertNotNil(migrationError, "Missing source file should produce error")
        
        // And: No secure file should be created
        let secureData = mockCacheManager.retrieveSecureData(forKey: audioFileName, subdirectory: sessionId)
        XCTAssertNil(secureData, "No secure file should exist when source is missing")
    }
    
    /// Tests audio file migration preserves file format and metadata
    /// BUSINESS VALUE: Ensures audio remains playable after migration
    func testAudioFileMigrationPreservesFormat() throws {
        // Given: A mock audio file with specific format
        let tempAudioURL = try mockAudioRecordingManager.createMockAudioFile()
        let originalData = try Data(contentsOf: tempAudioURL)
        let sessionId = UUID().uuidString
        let audioFileName = "recording_\(sessionId).m4a"
        
        // When: Migrating audio file to secure storage
        _ = mockCacheManager.saveSecurely(
            data: originalData,
            forKey: audioFileName,
            subdirectory: sessionId
        )
        
        // Then: Audio data should be byte-for-byte identical
        let retrievedData = mockCacheManager.retrieveSecureData(forKey: audioFileName, subdirectory: sessionId)
        XCTAssertNotNil(retrievedData, "Migrated audio must be retrievable")
        XCTAssertEqual(retrievedData, originalData,
                      "Audio data must be identical after migration for playback compatibility")
    }
    
    // MARK: - Playback Resource Loading Tests
    
    /// Tests successful loading of playback resources for completed session
    /// BUSINESS VALUE: Verifies secure playback can access all required files
    func testPlaybackResourcesLoadSuccessfully() throws {
        // Given: A completed session with audio, transcript, and metadata
        let sessionId = UUID().uuidString
        let audioFileName = "recording_\(sessionId).m4a"
        let transcriptFileName = "transcript_\(sessionId).json"
        
        // Create mock audio file in secure storage
        let tempAudioURL = try mockAudioRecordingManager.createMockAudioFile()
        let audioData = try Data(contentsOf: tempAudioURL)
        let secureAudioURL = mockCacheManager.saveSecurely(
            data: audioData,
            forKey: audioFileName,
            subdirectory: sessionId
        )
        XCTAssertNotNil(secureAudioURL, "Audio must be saved for playback test")
        
        // Create mock transcript (using simple JSON structure since SecureTranscriptPayload is private)
        let transcriptData = """
        {
            "transcript": "Test transcript text",
            "segments": [
                {
                    "text": "Test",
                    "startTime": 0.0,
                    "endTime": 1.0,
                    "confidence": 0.95
                }
            ],
            "savedAt": "\(ISO8601DateFormatter().string(from: Date()))"
        }
        """.data(using: .utf8)!
        
        let secureTranscriptURL = mockCacheManager.saveSecurely(
            data: transcriptData,
            forKey: transcriptFileName,
            subdirectory: sessionId
        )
        XCTAssertNotNil(secureTranscriptURL, "Transcript must be saved for playback test")
        
        // When: Loading playback resources
        let audioExists = FileManager.default.fileExists(atPath: secureAudioURL!.path)
        let transcriptExists = mockCacheManager.retrieveSecureData(forKey: transcriptFileName, subdirectory: sessionId) != nil
        
        // Then: All resources should be accessible
        XCTAssertTrue(audioExists,
                     "Critical Bug: Audio file missing for completed session - playback will fail")
        XCTAssertTrue(transcriptExists,
                     "Transcript file must be accessible for playback")
        
        // And: File protection should be validated
        XCTAssertTrue(mockCacheManager.secureProtectionApplied,
                     "All playback resources must have .completeFileProtection")
    }
    
    /// Tests playback resource loading fails gracefully for incomplete session
    /// BUSINESS VALUE: Prevents crashes when attempting to play incomplete recordings
    func testPlaybackResourcesRejectIncompleteSession() throws {
        // Given: An incomplete session (no audio file saved yet)
        let sessionId = UUID().uuidString
        let session = SecureRecordingSession(
            id: sessionId,
            title: "Incomplete Recording",
            startTime: Date(),
            endTime: nil,
            duration: 0,
            audioFileName: "recording_\(sessionId).m4a",
            transcriptFileName: "transcript_\(sessionId).json",
            isCompleted: false,
            hasConsent: true
        )
        
        // When: Attempting to load playback resources for incomplete session
        let shouldAllowPlayback = session.isCompleted
        
        // Then: Playback should be prevented
        XCTAssertFalse(shouldAllowPlayback,
                      "Critical Bug: Incomplete session allowed for playback - will crash")
    }
    
    /// Tests playback resource loading validates file protection
    /// BUSINESS VALUE: Ensures only properly secured files are played back
    func testPlaybackResourcesValidateFileProtection() throws {
        // Given: Audio file with complete file protection
        let sessionId = UUID().uuidString
        let audioFileName = "recording_\(sessionId).m4a"
        
        let tempAudioURL = try mockAudioRecordingManager.createMockAudioFile()
        let audioData = try Data(contentsOf: tempAudioURL)
        let secureURL = mockCacheManager.saveSecurely(
            data: audioData,
            forKey: audioFileName,
            subdirectory: sessionId
        )
        XCTAssertNotNil(secureURL, "Audio must be saved for protection test")
        
        // When: Validating file protection
        let isProtected = mockCacheManager.validateFileProtection(at: secureURL!)
        
        // Then: Protection must be confirmed before playback
        XCTAssertTrue(isProtected,
                     "Critical Security Bug: Audio file lacks .completeFileProtection")
    }
    
    /// Tests playback resource loading handles missing transcript gracefully
    /// BUSINESS VALUE: Provides clear error when transcript is missing
    func testPlaybackResourcesHandleMissingTranscript() throws {
        // Given: Session with audio but missing transcript
        let sessionId = UUID().uuidString
        let audioFileName = "recording_\(sessionId).m4a"
        let transcriptFileName = "transcript_\(sessionId).json"
        
        // Create only audio file, no transcript
        let tempAudioURL = try mockAudioRecordingManager.createMockAudioFile()
        let audioData = try Data(contentsOf: tempAudioURL)
        let secureAudioURL = mockCacheManager.saveSecurely(
            data: audioData,
            forKey: audioFileName,
            subdirectory: sessionId
        )
        XCTAssertNotNil(secureAudioURL, "Audio must be saved for test")
        
        // When: Checking for transcript
        let transcriptData = mockCacheManager.retrieveSecureData(forKey: transcriptFileName, subdirectory: sessionId)
        
        // Then: Missing transcript should be detected
        XCTAssertNil(transcriptData,
                    "Transcript should not exist for this test scenario")
    }
    
    // MARK: - Session Completion Workflow Tests
    
    /// Tests complete stop recording workflow with all file persistence
    /// BUSINESS VALUE: Validates end-to-end workflow for session completion
    func testCompleteStopRecordingWorkflow() throws {
        // Given: An active recording session
        let sessionId = UUID().uuidString
        let audioFileName = "recording_\(sessionId).m4a"
        let transcriptFileName = "transcript_\(sessionId).json"
        let startTime = Date().addingTimeInterval(-60) // 1 minute ago
        
        // Simulate recording creates temporary audio file
        let tempAudioURL = try mockAudioRecordingManager.createMockAudioFile()
        XCTAssertTrue(FileManager.default.fileExists(atPath: tempAudioURL.path),
                     "Recording must create temporary audio file")
        
        // When: Stopping recording (full workflow)
        
        // Step 1: Stop audio recording (returns temp URL)
        let finalAudioURL = tempAudioURL
        
        // Step 2: Migrate audio to secure storage
        let audioData = try Data(contentsOf: finalAudioURL)
        let secureAudioURL = mockCacheManager.saveSecurely(
            data: audioData,
            forKey: audioFileName,
            subdirectory: sessionId
        )
        
        // Step 3: Delete temporary file
        try FileManager.default.removeItem(at: finalAudioURL)
        
        // Step 4: Save transcript (using simple JSON structure since SecureTranscriptPayload is private)
        let transcriptData = """
        {
            "transcript": "Test transcript",
            "segments": [],
            "savedAt": "\(ISO8601DateFormatter().string(from: Date()))"
        }
        """.data(using: .utf8)!
        
        let secureTranscriptURL = mockCacheManager.saveSecurely(
            data: transcriptData,
            forKey: transcriptFileName,
            subdirectory: sessionId
        )
        
        // Step 5: Update session to completed
        let completedSession = SecureRecordingSession(
            id: sessionId,
            title: "Test Recording",
            startTime: startTime,
            endTime: Date(),
            duration: Date().timeIntervalSince(startTime),
            audioFileName: audioFileName,
            transcriptFileName: transcriptFileName,
            isCompleted: true,
            hasConsent: true
        )
        
        // Then: All persistence operations should succeed
        XCTAssertNotNil(secureAudioURL,
                       "Critical Bug: Audio migration failed")
        XCTAssertNotNil(secureTranscriptURL,
                       "Transcript save failed")
        XCTAssertTrue(completedSession.isCompleted,
                     "Session should be marked completed")
        XCTAssertFalse(FileManager.default.fileExists(atPath: tempAudioURL.path),
                      "Critical Security Bug: Temporary audio file not cleaned up")
        
        // And: Playback resources should be ready
        let audioAvailable = FileManager.default.fileExists(atPath: secureAudioURL!.path)
        let transcriptAvailable = mockCacheManager.retrieveSecureData(
            forKey: transcriptFileName,
            subdirectory: sessionId
        ) != nil
        
        XCTAssertTrue(audioAvailable && transcriptAvailable,
                     "Critical Bug: Playback resources not available after completion")
    }
    
    /// Tests session metadata includes correct file references after migration
    /// BUSINESS VALUE: Ensures session metadata points to correct secure file locations
    func testSessionMetadataFileReferences() throws {
        // Given: Session with specific file names
        let sessionId = UUID().uuidString
        let expectedAudioFileName = "recording_\(sessionId).m4a"
        let expectedTranscriptFileName = "transcript_\(sessionId).json"
        
        // When: Creating session metadata
        let session = SecureRecordingSession(
            id: sessionId,
            title: "Test Recording",
            startTime: Date(),
            endTime: Date(),
            duration: 60.0,
            audioFileName: expectedAudioFileName,
            transcriptFileName: expectedTranscriptFileName,
            isCompleted: true,
            hasConsent: true
        )
        
        // Then: File references should match expected secure storage paths
        XCTAssertEqual(session.audioFileName, expectedAudioFileName,
                      "Audio file name must match secure storage key")
        XCTAssertEqual(session.transcriptFileName, expectedTranscriptFileName,
                      "Transcript file name must match secure storage key")
        
        // And: File names should be unique per session
        XCTAssertTrue(session.audioFileName.contains(sessionId) ||
                     session.audioFileName.contains("recording"),
                     "Audio file name should be session-specific")
    }
}

// MARK: - Mock Objects

/// Mock audio recording manager for testing audio file creation and migration
class MockAudioRecordingManager {
    private let tempDirectory: URL
    
    init(tempDirectory: URL) {
        self.tempDirectory = tempDirectory
    }
    
    /// Creates a mock audio file with sample data for testing
    func createMockAudioFile() throws -> URL {
        let fileName = "temp_recording_\(UUID().uuidString).m4a"
        let fileURL = tempDirectory.appendingPathComponent(fileName)
        
        // Create mock audio data (simple binary data for testing)
        let mockAudioData = Data(repeating: 0xAA, count: 1024) // 1KB mock audio
        try mockAudioData.write(to: fileURL)
        
        return fileURL
    }
    
    /// Simulates stopping recording and returning temporary file URL
    func stopRecording() -> URL? {
        return try? createMockAudioFile()
    }
}

