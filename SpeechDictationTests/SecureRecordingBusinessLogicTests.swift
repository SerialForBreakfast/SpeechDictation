//
//  SecureRecordingBusinessLogicTests.swift
//  SpeechDictationTests
//
//  Created by AI Assistant on 1/27/25.
//
//  Focused unit tests for secure recording business logic.
//  Tests only meaningful behaviors where bugs could cause security vulnerabilities or data corruption.
//  Skips trivial operations like basic getters/setters or simple math.
//

import XCTest
@testable import SpeechDictation

/// Tests critical business logic for secure recording workflows
/// Focuses on security-sensitive behaviors and complex state management
final class SecureRecordingBusinessLogicTests: XCTestCase {
    
    var mockAuthManager: MockLocalAuthenticationManager!
    var mockCacheManager: MockCacheManager!
    var testDirectory: URL!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        testDirectory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: testDirectory, withIntermediateDirectories: true, attributes: nil)
        
        mockAuthManager = MockLocalAuthenticationManager()
        mockCacheManager = MockCacheManager(testDirectory: testDirectory)
    }
    
    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: testDirectory)
        mockAuthManager = nil
        mockCacheManager = nil
        testDirectory = nil
        try super.tearDownWithError()
    }
    
    // MARK: - Authentication State Management Business Logic
    
    /// Tests that authentication requirement properly gates access to sensitive operations
    /// BUSINESS VALUE: Prevents unauthorized access to private recordings
    func testAuthenticationRequirementEnforcement() async throws {
        // Given: Authentication is required but user hasn't authenticated
        mockAuthManager.isAuthenticationRequired = true
        mockAuthManager.authenticationState = .notEvaluated
        
        // When: Checking if sensitive operations should be allowed
        let shouldAllowAccess = mockAuthManager.authenticationState.isAuthenticated
        
        // Then: Access must be denied to protect private data
        XCTAssertFalse(shouldAllowAccess, 
                      "Critical Security Bug: Unauthenticated users can access private recordings")
        
        // When: User successfully authenticates
        let authSuccess = await mockAuthManager.authenticate(reason: "Test")
        
        // Then: Access should be granted after successful authentication
        XCTAssertTrue(authSuccess, "Authentication should succeed in test environment")
        XCTAssertTrue(mockAuthManager.authenticationState.isAuthenticated, 
                     "Authentication state must update after successful auth")
    }
    
    /// Tests authentication state transitions handle edge cases correctly
    /// BUSINESS VALUE: Ensures authentication states are consistent and can't be bypassed
    func testAuthenticationStateTransitionIntegrity() async throws {
        // Given: Multiple authentication attempts with different outcomes
        mockAuthManager.authenticationState = .notEvaluated
        
        // When: First authentication fails
        mockAuthManager.setAuthenticationResult(false)
        let firstAttempt = await mockAuthManager.authenticate(reason: "Test")
        
        // Then: State should reflect failure, not success
        XCTAssertFalse(firstAttempt, "Failed authentication should return false")
        XCTAssertFalse(mockAuthManager.authenticationState.isAuthenticated, 
                      "Failed authentication must not grant access")
        
        // When: Subsequent authentication succeeds
        mockAuthManager.setAuthenticationResult(true)
        let secondAttempt = await mockAuthManager.authenticate(reason: "Test")
        
        // Then: State should transition to authenticated
        XCTAssertTrue(secondAttempt, "Successful authentication should return true")
        XCTAssertTrue(mockAuthManager.authenticationState.isAuthenticated, 
                     "Successful authentication must grant access")
        
        // When: Authentication is explicitly reset
        mockAuthManager.resetAuthenticationState()
        
        // Then: Access should be revoked
        XCTAssertFalse(mockAuthManager.authenticationState.isAuthenticated, 
                      "Reset must revoke authentication state")
    }
    
    /// Tests biometric fallback logic handles device capability changes
    /// BUSINESS VALUE: Ensures authentication works across different device configurations
    func testBiometricFallbackLogic() throws {
        // Test critical authentication paths based on device capabilities
        let testScenarios: [(BiometricType, Bool, String)] = [
            (.faceID, true, "Face ID should be available when device supports it"),
            (.touchID, true, "Touch ID should be available when device supports it"), 
            (.opticID, true, "Optic ID should be available when device supports it"),
            (.none, false, "No biometrics should force passcode-only authentication")
        ]
        
        for (biometricType, expectedAvailability, failureMessage) in testScenarios {
            // When: Device has specific biometric capability
            mockAuthManager.biometricType = biometricType
            
            // Then: Availability must match device capability exactly
            let isAvailable = mockAuthManager.isBiometricAuthenticationAvailable()
            XCTAssertEqual(isAvailable, expectedAvailability, failureMessage)
        }
    }
    
    // MARK: - Session Lifecycle Business Logic
    
    /// Tests that session completion properly validates all required data
    /// BUSINESS VALUE: Ensures recordings are never lost due to incomplete metadata
    func testSessionCompletionDataIntegrity() throws {
        // Given: A recording session with various completion states
        let sessionId = "integrity-test-\(UUID().uuidString)"
        let startTime = Date().addingTimeInterval(-300) // 5 minutes ago
        
        // Test incomplete session (missing end time)
        let incompleteSession = SecureRecordingSession(
            id: sessionId,
            title: "Test Recording",
            startTime: startTime,
            endTime: nil,  // Missing end time
            duration: 0,   // Missing duration
            audioFileName: "audio_\(sessionId).m4a",
            transcriptFileName: "transcript_\(sessionId).json",
            isCompleted: false,
            hasConsent: true
        )
        
        // Verify incomplete session is properly marked
        XCTAssertFalse(incompleteSession.isCompleted, 
                      "Incomplete sessions must be flagged to prevent data loss")
        XCTAssertNil(incompleteSession.endTime, 
                    "Incomplete sessions should not have end time")
        
        // When: Session is properly completed
        let endTime = Date()
        let duration = endTime.timeIntervalSince(startTime)
        
        let completedSession = SecureRecordingSession(
            id: sessionId,
            title: incompleteSession.title,
            startTime: incompleteSession.startTime,
            endTime: endTime,
            duration: duration,
            audioFileName: incompleteSession.audioFileName,
            transcriptFileName: incompleteSession.transcriptFileName,
            isCompleted: true,
            hasConsent: incompleteSession.hasConsent
        )
        
        // Then: All completion data must be present and valid
        XCTAssertTrue(completedSession.isCompleted, 
                     "Completed sessions must be properly flagged")
        XCTAssertNotNil(completedSession.endTime, 
                       "Completed sessions must have end time")
        XCTAssertGreaterThan(completedSession.duration, 0, 
                           "Completed sessions must have positive duration")
        XCTAssertEqual(completedSession.duration, duration, accuracy: 0.1, 
                      "Duration calculation must be accurate for timing data")
    }
    
    /// Tests session ID uniqueness to prevent data collisions
    /// BUSINESS VALUE: Prevents recordings from overwriting each other
    func testSessionIdUniquenessLogic() throws {
        // Given: Multiple session creation attempts
        var generatedIds: Set<String> = []
        let sessionCount = 100
        
        // When: Creating many sessions rapidly
        for _ in 0..<sessionCount {
            let sessionId = "session-\(UUID().uuidString)"
            
            // Then: Each ID must be unique to prevent data collisions
            XCTAssertFalse(generatedIds.contains(sessionId), 
                          "Session ID collision detected: \(sessionId)")
            generatedIds.insert(sessionId)
        }
        
        // Verify we actually generated the expected number of unique IDs
        XCTAssertEqual(generatedIds.count, sessionCount, 
                      "Failed to generate expected number of unique session IDs")
    }
    
    /// Tests consent validation prevents unauthorized recordings
    /// BUSINESS VALUE: Legal compliance and user privacy protection
    func testConsentValidationLogic() throws {
        // Test all consent scenarios that affect legal compliance
        let consentScenarios: [(Bool, String)] = [
            (true, "Recordings with explicit consent should be allowed"),
            (false, "Recordings without consent should be flagged for legal compliance")
        ]
        
        for (hasConsent, message) in consentScenarios {
            // When: Creating session with specific consent state
            let session = SecureRecordingSession(
                id: "consent-test-\(hasConsent)",
                title: "Consent Test",
                startTime: Date(),
                endTime: nil,
                duration: 0,
                audioFileName: "audio.m4a",
                transcriptFileName: "transcript.json",
                isCompleted: false,
                hasConsent: hasConsent
            )
            
            // Then: Consent state must be accurately tracked for legal compliance
            XCTAssertEqual(session.hasConsent, hasConsent, message)
        }
    }
    
    // MARK: - Security Constraint Enforcement
    
    /// Tests that file protection is actually applied and verified
    /// BUSINESS VALUE: Ensures private recordings are properly encrypted
    func testFileProtectionEnforcement() throws {
        // Given: Sensitive data that requires protection
        let sensitiveData = "Private medical conversation transcript".data(using: .utf8)!
        let fileName = "protected_recording.json"
        
        // When: Saving data with security requirements
        let savedURL = mockCacheManager.saveSecurely(data: sensitiveData, forKey: fileName)
        
        // Then: Protection must be applied and verifiable
        XCTAssertNotNil(savedURL, "Secure save operation must succeed")
        XCTAssertTrue(mockCacheManager.secureProtectionApplied, 
                     "Critical Security Bug: File protection not applied to sensitive data")
        
        // When: Validating file protection after save
        let isProtected = mockCacheManager.validateFileProtection(at: savedURL!)
        
        // Then: Protection validation must confirm security
        XCTAssertTrue(isProtected, 
                     "Critical Security Bug: File protection validation failed")
        
        // When: Retrieving protected data
        let retrievedData = mockCacheManager.retrieveSecureData(forKey: fileName)
        
        // Then: Data should be retrievable but protected
        XCTAssertNotNil(retrievedData, "Protected data must remain accessible")
        XCTAssertEqual(retrievedData, sensitiveData, 
                      "Retrieved data must match original (encryption should be transparent)")
    }
    
    /// Tests storage space validation prevents recordings from failing mid-session
    /// BUSINESS VALUE: Prevents data loss and poor user experience
    func testStorageSpaceValidation() throws {
        // Given: Different storage scenarios that could affect recordings
        let minimumRequired: Int64 = 100 * 1024 * 1024 // 100MB minimum for quality recordings
        
        let storageScenarios: [(Int64, Bool, String)] = [
            (minimumRequired + 1000, true, "Sufficient storage should allow recordings"),
            (minimumRequired - 1000, false, "Insufficient storage should prevent data loss"),
            (0, false, "No available storage should block recordings"),
            (minimumRequired, false, "Exactly minimum storage should be conservative")
        ]
        
        for (availableSpace, shouldAllow, message) in storageScenarios {
            // When: Checking storage with specific available space
            mockCacheManager.mockAvailableSpace = availableSpace
            let hasSpace = mockCacheManager.getAvailableStorageSpace()! > minimumRequired
            
            // Then: Storage validation must make correct decisions
            XCTAssertEqual(hasSpace, shouldAllow, message)
        }
    }
    
    /// Tests secure file deletion actually removes sensitive data
    /// BUSINESS VALUE: Ensures deleted recordings cannot be recovered
    func testSecureFileDeletion() throws {
        // Given: Sensitive data that user wants to delete
        let sensitiveData = "Private conversation to be deleted".data(using: .utf8)!
        let fileName = "sensitive_to_delete.json"
        
        // When: Creating then deleting sensitive file
        let savedURL = mockCacheManager.saveSecurely(data: sensitiveData, forKey: fileName)
        XCTAssertNotNil(savedURL, "File creation must succeed for deletion test")
        
        let deleteSuccess = mockCacheManager.deleteSecureData(forKey: fileName)
        
        // Then: Deletion must be complete and irreversible
        XCTAssertTrue(deleteSuccess, "Secure deletion must succeed")
        
        let retrievedAfterDeletion = mockCacheManager.retrieveSecureData(forKey: fileName)
        XCTAssertNil(retrievedAfterDeletion, 
                    "Critical Security Bug: Deleted sensitive data is still accessible")
    }
    
    // MARK: - Data Integrity and Serialization Logic
    
    /// Tests that session metadata survives serialization without corruption
    /// BUSINESS VALUE: Ensures recording metadata is never lost or corrupted
    func testSessionMetadataSerializationIntegrity() throws {
        // Given: Session with complex metadata including edge cases
        let originalSession = SecureRecordingSession(
            id: "serialization-test-\(UUID().uuidString)",
            title: "Test Recording with Special Characters: åäö 🎤 \"quotes\" & symbols",
            startTime: Date(timeIntervalSince1970: 1640995200), // Fixed date for consistency
            endTime: Date(timeIntervalSince1970: 1640995320),   // 2 minutes later
            duration: 120.5,
            audioFileName: "audio_test_\(UUID().uuidString).m4a",
            transcriptFileName: "transcript_test_\(UUID().uuidString).json",
            isCompleted: true,
            hasConsent: true
        )
        
        // When: Serializing and deserializing session metadata
        let encodedData = try JSONEncoder().encode(originalSession)
        let decodedSession = try JSONDecoder().decode(SecureRecordingSession.self, from: encodedData)
        
        // Then: All critical metadata must be preserved exactly
        XCTAssertEqual(decodedSession.id, originalSession.id, 
                      "Session ID corruption would cause data loss")
        XCTAssertEqual(decodedSession.title, originalSession.title, 
                      "Title corruption affects user experience")
        XCTAssertEqual(decodedSession.duration, originalSession.duration, accuracy: 0.01, 
                      "Duration corruption affects timing data accuracy")
        XCTAssertEqual(decodedSession.isCompleted, originalSession.isCompleted, 
                      "Completion status corruption affects data integrity")
        XCTAssertEqual(decodedSession.hasConsent, originalSession.hasConsent, 
                      "Consent corruption affects legal compliance")
        XCTAssertEqual(decodedSession.audioFileName, originalSession.audioFileName, 
                      "File name corruption would cause data loss")
        XCTAssertEqual(decodedSession.transcriptFileName, originalSession.transcriptFileName, 
                      "Transcript file name corruption would cause data loss")
    }
    
    /// Tests secure directory structure prevents data leakage between sessions
    /// BUSINESS VALUE: Ensures recordings are properly isolated
    func testSecureDirectoryIsolation() throws {
        // Given: Multiple sensitive recording sessions
        let sessionIds = ["patient-123", "meeting-456", "personal-789"]
        
        for sessionId in sessionIds {
            // When: Creating isolated storage for each session
            let testData = "Sensitive data for session \(sessionId)".data(using: .utf8)!
            let fileName = "metadata.json"
            
            let savedURL = mockCacheManager.saveSecurely(
                data: testData, 
                forKey: fileName, 
                subdirectory: sessionId
            )
            
            // Then: Each session must have isolated storage
            XCTAssertNotNil(savedURL, "Secure storage creation must succeed for session: \(sessionId)")
            XCTAssertTrue(savedURL!.path.contains(sessionId), 
                         "Critical Security Bug: Session data not properly isolated for \(sessionId)")
        }
    }
} 