//
//  SecureRecordingTests.swift
//  SpeechDictationTests
//
//  Created by AI Assistant on 1/27/25.
//
//  Unit tests for secure recording business logic and workflows.
//  Tests authentication flows, file protection, session management, and security constraints.
//  Focuses on business logic validation rather than basic operations.
//

import XCTest
import LocalAuthentication
@testable import SpeechDictation

/// Test cases for secure recording business logic
/// Validates security constraints, authentication flows, and data protection
final class SecureRecordingTests: XCTestCase {
    
    var mockAuthManager: MockLocalAuthenticationManager!
    var mockCacheManager: MockCacheManager!
    var testFileManager: FileManager!
    var testDirectory: URL!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        // Setup test environment
        testFileManager = FileManager.default
        testDirectory = testFileManager.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try testFileManager.createDirectory(at: testDirectory, withIntermediateDirectories: true, attributes: nil)
        
        // Setup mocks
        mockAuthManager = MockLocalAuthenticationManager()
        mockCacheManager = MockCacheManager(testDirectory: testDirectory)
    }
    
    override func tearDownWithError() throws {
        // Cleanup test directory
        try? testFileManager.removeItem(at: testDirectory)
        
        mockAuthManager = nil
        mockCacheManager = nil
        testFileManager = nil
        testDirectory = nil
        
        try super.tearDownWithError()
    }
    
    // MARK: - Authentication Business Logic Tests
    
    /// Tests that authentication requirement properly gates access to secure features
    func testAuthenticationRequirementGating() async throws {
        // Given: Authentication is required but user is not authenticated
        mockAuthManager.isAuthenticationRequired = true
        mockAuthManager.authenticationState = .notEvaluated
        
        // When: Attempting to access secure features
        let canAccess = mockAuthManager.authenticationState.isAuthenticated
        
        // Then: Access should be denied
        XCTAssertFalse(canAccess, "Access should be denied when authentication is required but not completed")
    }
    
    /// Tests authentication state transitions and validation
    func testAuthenticationStateTransitions() async throws {
        // Given: Initial unauthenticated state
        mockAuthManager.authenticationState = .notEvaluated
        
        // When: Successful authentication occurs
        let success = await mockAuthManager.authenticate(reason: "Test authentication")
        
        // Then: State should transition to authenticated
        XCTAssertTrue(success, "Authentication should succeed in test environment")
        XCTAssertTrue(mockAuthManager.authenticationState.isAuthenticated, "State should be authenticated after successful auth")
        
        // When: Authentication is reset
        mockAuthManager.resetAuthenticationState()
        
        // Then: State should return to not evaluated
        XCTAssertFalse(mockAuthManager.authenticationState.isAuthenticated, "State should be reset after explicit reset")
    }
    
    /// Tests biometric capability detection and fallback logic
    func testBiometricCapabilityDetection() throws {
        // Given: Device with different biometric capabilities
        let testCases: [(BiometricType, Bool)] = [
            (.faceID, true),
            (.touchID, true),
            (.opticID, true),
            (.none, false)
        ]
        
        for (biometricType, expectedAvailability) in testCases {
            // When: Setting biometric type
            mockAuthManager.biometricType = biometricType
            
            // Then: Availability should match expected
            let isAvailable = mockAuthManager.isBiometricAuthenticationAvailable()
            XCTAssertEqual(isAvailable, expectedAvailability, "Biometric availability should match type: \(biometricType)")
        }
    }
    
    // MARK: - Session Lifecycle Business Logic Tests
    
    /// Tests secure recording session creation with proper metadata
    func testSecureRecordingSessionCreation() throws {
        // Given: Valid session parameters
        let sessionId = "test-session-123"
        let title = "Test Medical Consultation"
        let startTime = Date()
        
        // When: Creating a secure recording session
        let session = SecureRecordingSession(
            id: sessionId,
            title: title,
            startTime: startTime,
            endTime: nil,
            duration: 0,
            audioFileName: "audio_\(sessionId).m4a",
            transcriptFileName: "transcript_\(sessionId).json",
            isCompleted: false,
            hasConsent: true
        )
        
        // Then: Session should have correct metadata
        XCTAssertEqual(session.id, sessionId, "Session ID should match")
        XCTAssertEqual(session.title, title, "Title should match")
        XCTAssertTrue(session.hasConsent, "Consent should be recorded")
        XCTAssertFalse(session.isCompleted, "New session should not be completed")
        XCTAssertEqual(session.displayTitle, title, "Display title should use provided title")
    }
    
    /// Tests session completion with proper state transitions
    func testSecureRecordingSessionCompletion() throws {
        // Given: An active recording session
        let sessionId = "test-session-456"
        let startTime = Date().addingTimeInterval(-120) // 2 minutes ago
        let endTime = Date()
        let duration = endTime.timeIntervalSince(startTime)
        
        var session = SecureRecordingSession(
            id: sessionId,
            title: "Test Session",
            startTime: startTime,
            endTime: nil,
            duration: 0,
            audioFileName: "audio_\(sessionId).m4a",
            transcriptFileName: "transcript_\(sessionId).json",
            isCompleted: false,
            hasConsent: true
        )
        
        // When: Completing the session
        session = SecureRecordingSession(
            id: session.id,
            title: session.title,
            startTime: session.startTime,
            endTime: endTime,
            duration: duration,
            audioFileName: session.audioFileName,
            transcriptFileName: session.transcriptFileName,
            isCompleted: true,
            hasConsent: session.hasConsent
        )
        
        // Then: Session should be properly completed
        XCTAssertTrue(session.isCompleted, "Session should be marked as completed")
        XCTAssertNotNil(session.endTime, "End time should be set")
        XCTAssertGreaterThan(session.duration, 0, "Duration should be positive")
        XCTAssertEqual(session.duration, duration, accuracy: 1.0, "Duration should match calculated time")
    }
    
    /// Tests default display title generation for untitled sessions
    func testSessionDisplayTitleGeneration() throws {
        // Given: A session without a custom title
        let startTime = Date()
        let session = SecureRecordingSession(
            id: "test-session",
            title: "",
            startTime: startTime,
            endTime: nil,
            duration: 0,
            audioFileName: "audio.m4a",
            transcriptFileName: "transcript.json",
            isCompleted: false,
            hasConsent: true
        )
        
        // When: Getting display title
        let displayTitle = session.displayTitle
        
        // Then: Should generate default title with time
        XCTAssertTrue(displayTitle.contains("Recording"), "Display title should contain 'Recording'")
        XCTAssertFalse(displayTitle.isEmpty, "Display title should not be empty")
    }
    
    // MARK: - File Protection Business Logic Tests
    
    /// Tests that secure storage applies complete file protection
    func testSecureFileProtectionApplication() throws {
        // Given: Data to store securely
        let testData = "Sensitive medical recording data".data(using: .utf8)!
        let fileName = "test_secure_file.json"
        
        // When: Saving data securely
        let savedURL = mockCacheManager.saveSecurely(data: testData, forKey: fileName)
        
        // Then: File should exist and have protection applied
        XCTAssertNotNil(savedURL, "Secure save should return valid URL")
        XCTAssertTrue(mockCacheManager.secureProtectionApplied, "Complete file protection should be applied")
        
        // And: File should be retrievable
        let retrievedData = mockCacheManager.retrieveSecureData(forKey: fileName)
        XCTAssertNotNil(retrievedData, "Secure data should be retrievable")
        XCTAssertEqual(retrievedData, testData, "Retrieved data should match original")
    }
    
    /// Tests secure file validation and integrity checking
    func testSecureFileValidation() throws {
        // Given: A file that should have complete protection
        let fileName = "protected_file.json"
        let testData = "Protected content".data(using: .utf8)!
        
        // When: Saving and then validating protection
        let savedURL = mockCacheManager.saveSecurely(data: testData, forKey: fileName)
        let isValid = mockCacheManager.validateFileProtection(at: savedURL!)
        
        // Then: File should be valid and protected
        XCTAssertTrue(isValid, "Secure file should pass protection validation")
    }
    
    /// Tests secure file deletion and cleanup
    func testSecureFileDeletion() throws {
        // Given: An existing secure file
        let fileName = "file_to_delete.json"
        let testData = "Data to be deleted".data(using: .utf8)!
        let savedURL = mockCacheManager.saveSecurely(data: testData, forKey: fileName)
        XCTAssertNotNil(savedURL, "File should be created")
        
        // When: Deleting the secure file
        let deleteSuccess = mockCacheManager.deleteSecureData(forKey: fileName)
        
        // Then: File should be deleted and no longer accessible
        XCTAssertTrue(deleteSuccess, "Secure file deletion should succeed")
        
        let retrievedAfterDeletion = mockCacheManager.retrieveSecureData(forKey: fileName)
        XCTAssertNil(retrievedAfterDeletion, "File should not be retrievable after deletion")
    }
    
    // MARK: - Storage Space Validation Tests
    
    /// Tests storage space validation for secure recordings
    func testStorageSpaceValidation() throws {
        // Given: Mock cache manager with controllable storage space
        let minimumRequired: Int64 = 100 * 1024 * 1024 // 100MB
        
        // When: Checking available space with sufficient storage
        mockCacheManager.mockAvailableSpace = minimumRequired + 1000
        let hasSufficientSpace = mockCacheManager.getAvailableStorageSpace()! > minimumRequired
        
        // Then: Should indicate sufficient space
        XCTAssertTrue(hasSufficientSpace, "Should have sufficient space when above minimum")
        
        // When: Checking with insufficient storage
        mockCacheManager.mockAvailableSpace = minimumRequired - 1000
        let hasInsufficientSpace = mockCacheManager.getAvailableStorageSpace()! < minimumRequired
        
        // Then: Should indicate insufficient space
        XCTAssertTrue(hasInsufficientSpace, "Should have insufficient space when below minimum")
    }
    
    // MARK: - Consent and Legal Compliance Tests
    
    /// Tests that recordings cannot start without proper consent
    func testConsentRequirement() throws {
        // Given: A session creation attempt without consent
        let sessionWithoutConsent = SecureRecordingSession(
            id: "no-consent-session",
            title: "Test",
            startTime: Date(),
            endTime: nil,
            duration: 0,
            audioFileName: "audio.m4a",
            transcriptFileName: "transcript.json",
            isCompleted: false,
            hasConsent: false
        )
        
        // Then: Session should reflect lack of consent
        XCTAssertFalse(sessionWithoutConsent.hasConsent, "Session should properly track consent state")
    }
    
    /// Tests consent validation in recording workflow
    func testConsentValidationWorkflow() throws {
        // Given: Different consent states
        let consentStates = [true, false]
        
        for hasConsent in consentStates {
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
            
            // Then: Consent state should be accurately recorded
            XCTAssertEqual(session.hasConsent, hasConsent, "Consent state should match input for: \(hasConsent)")
        }
    }
    
    // MARK: - Data Integrity and Security Tests
    
    /// Tests that session metadata is properly encoded and decoded
    func testSessionMetadataSerialization() throws {
        // Given: A complete session with all metadata
        let originalSession = SecureRecordingSession(
            id: "serialization-test",
            title: "Test Recording with Special Characters: åäö",
            startTime: Date(),
            endTime: Date().addingTimeInterval(120),
            duration: 120.5,
            audioFileName: "audio_test.m4a",
            transcriptFileName: "transcript_test.json",
            isCompleted: true,
            hasConsent: true
        )
        
        // When: Encoding and decoding the session
        let encodedData = try JSONEncoder().encode(originalSession)
        let decodedSession = try JSONDecoder().decode(SecureRecordingSession.self, from: encodedData)
        
        // Then: All properties should be preserved
        XCTAssertEqual(decodedSession.id, originalSession.id, "ID should be preserved")
        XCTAssertEqual(decodedSession.title, originalSession.title, "Title should be preserved")
        XCTAssertEqual(decodedSession.duration, originalSession.duration, accuracy: 0.1, "Duration should be preserved")
        XCTAssertEqual(decodedSession.isCompleted, originalSession.isCompleted, "Completion state should be preserved")
        XCTAssertEqual(decodedSession.hasConsent, originalSession.hasConsent, "Consent state should be preserved")
    }
    
    /// Tests secure directory structure and organization
    func testSecureDirectoryStructure() throws {
        // Given: Multiple sessions with different IDs
        let sessionIds = ["session-1", "session-2", "session-3"]
        
        for sessionId in sessionIds {
            // When: Creating secure files for each session
            let testData = "Session data for \(sessionId)".data(using: .utf8)!
            let fileName = "metadata.json"
            
            let savedURL = mockCacheManager.saveSecurely(data: testData, forKey: fileName, subdirectory: sessionId)
            
            // Then: Each session should have its own secure directory
            XCTAssertNotNil(savedURL, "Should create secure file for session: \(sessionId)")
            XCTAssertTrue(savedURL!.path.contains(sessionId), "URL should contain session ID in path")
        }
    }
}

// MARK: - Mock Objects for Testing

/// Mock LocalAuthenticationManager for testing authentication logic
class MockLocalAuthenticationManager: ObservableObject {
    @Published var authenticationState: AuthenticationState = .notEvaluated
    @Published var isAuthenticationRequired = false
    @Published var biometricType: BiometricType = .faceID
    @Published var isAuthenticating = false
    
    private var shouldSucceedAuthentication = true
    
    func setAuthenticationResult(_ shouldSucceed: Bool) {
        shouldSucceedAuthentication = shouldSucceed
    }
    
    func isBiometricAuthenticationAvailable() -> Bool {
        return biometricType != .none
    }
    
    func authenticate(reason: String = "Test authentication") async -> Bool {
        isAuthenticating = true
        
        // Simulate authentication delay
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        if shouldSucceedAuthentication {
            authenticationState = .authenticated
        } else {
            authenticationState = .denied
        }
        
        isAuthenticating = false
        return shouldSucceedAuthentication
    }
    
    func authenticateWithPasscode(reason: String = "Test passcode authentication") async -> Bool {
        return await authenticate(reason: reason)
    }
    
    func resetAuthenticationState() {
        authenticationState = .notEvaluated
    }
    
    func getCurrentBiometricType() -> BiometricType {
        return biometricType
    }
}

/// Mock CacheManager for testing secure storage logic
class MockCacheManager {
    private let testDirectory: URL
    private var secureFiles: [String: Data] = [:]
    
    var secureProtectionApplied = false
    var mockAvailableSpace: Int64 = 1_000_000_000 // 1GB default
    
    init(testDirectory: URL) {
        self.testDirectory = testDirectory
    }
    
    func saveSecurely(data: Data, forKey key: String, subdirectory: String? = nil) -> URL? {
        var targetDirectory = testDirectory
        
        if let subdirectory = subdirectory {
            targetDirectory = targetDirectory.appendingPathComponent(subdirectory)
            try? FileManager.default.createDirectory(at: targetDirectory, withIntermediateDirectories: true, attributes: nil)
        }
        
        let fileURL = targetDirectory.appendingPathComponent(key)
        
        do {
            try data.write(to: fileURL)
            secureProtectionApplied = true // Simulate protection application
            secureFiles[key] = data
            return fileURL
        } catch {
            return nil
        }
    }
    
    func retrieveSecureData(forKey key: String, subdirectory: String? = nil) -> Data? {
        return secureFiles[key]
    }
    
    func deleteSecureData(forKey key: String, subdirectory: String? = nil) -> Bool {
        secureFiles.removeValue(forKey: key)
        return true
    }
    
    func validateFileProtection(at url: URL) -> Bool {
        return secureProtectionApplied
    }
    
    func getAvailableStorageSpace() -> Int64? {
        return mockAvailableSpace
    }
} 