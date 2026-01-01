//
//  LocalAuthenticationManager.swift
//  SpeechDictation
//
//  Created by AI Assistant on 1/27/25.
//
//  Local authentication manager for securing access to private recordings.
//  Provides Face ID/Touch ID authentication with proper fallback to device passcode.
//  Handles authentication states and provides clear user feedback.
//

import Foundation
import LocalAuthentication

/// Authentication states for biometric access
enum AuthenticationState {
    case notEvaluated
    case authenticated
    case denied
    case biometricUnavailable
    case biometricNotEnrolled
    case devicePasscodeNotSet
    case error(String)
}

/// Biometric authentication types available on the device
enum BiometricType {
    case none
    case touchID
    case faceID
    case opticID
    
    var description: String {
        switch self {
        case .none: return "None"
        case .touchID: return "Touch ID"
        case .faceID: return "Face ID"
        case .opticID: return "Optic ID"
        }
    }
}

/// Service for managing biometric authentication and device security
/// Provides secure access control for private recordings and sensitive features
/// Uses LocalAuthentication framework with proper error handling and fallbacks
@MainActor
final class LocalAuthenticationManager: ObservableObject {
    static let shared = LocalAuthenticationManager()
    
    // MARK: - Published Properties
    
    @Published private(set) var authenticationState: AuthenticationState = .notEvaluated
    @Published private(set) var isAuthenticationRequired = false
    @Published private(set) var biometricType: BiometricType = .none
    @Published private(set) var isAuthenticating = false
    
    // MARK: - Private Properties
    
    private let context = LAContext()
    private let userDefaults = UserDefaults.standard
    
    // UserDefaults keys
    private let authenticationRequiredKey = "secureRecordingsAuthenticationRequired"
    private let lastAuthenticationTimeKey = "lastAuthenticationTime"
    
    // MARK: - Initialization
    
    private init() {
        loadSettings()
        updateBiometricType()
    }
    
    // MARK: - Public Interface
    
    /// Checks if biometric authentication is available on the device
    /// - Returns: True if biometrics are available and enrolled
    func isBiometricAuthenticationAvailable() -> Bool {
        var error: NSError?
        let result = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
        
        if let error = error {
            AppLog.error(.auth, "Biometric authentication availability check failed: \(error.localizedDescription)")
            return false
        }
        
        return result
    }
    
    /// Enables or disables authentication requirement for secure recordings
    /// - Parameter enabled: Whether authentication should be required
    func setAuthenticationRequired(_ enabled: Bool) {
        isAuthenticationRequired = enabled
        userDefaults.set(enabled, forKey: authenticationRequiredKey)
        
        if !enabled {
            authenticationState = .notEvaluated
        }
        
        AppLog.info(.auth, "Authentication requirement set to: \(enabled)")
    }
    
    /// Authenticates the user using biometrics or device passcode
    /// - Parameter reason: Human-readable reason for authentication request
    /// - Returns: True if authentication was successful
    func authenticate(reason: String = "Access secure recordings") async -> Bool {
        guard isAuthenticationRequired else {
            authenticationState = .authenticated
            return true
        }
        
        // Check if recently authenticated (within last 5 minutes)
        if isRecentlyAuthenticated() {
            authenticationState = .authenticated
            return true
        }
        
        isAuthenticating = true
        authenticationState = .notEvaluated
        
        let context = LAContext()
        context.localizedFallbackTitle = "Use Passcode"
        context.localizedCancelTitle = "Cancel"
        
        var error: NSError?
        
        // Check if authentication is available
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            if let error = error {
                await handleAuthenticationError(error)
            } else {
                authenticationState = .biometricUnavailable
            }
            isAuthenticating = false
            return false
        }
        
        do {
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: reason
            )
            
            if success {
                authenticationState = .authenticated
                recordSuccessfulAuthentication()
                AppLog.info(.auth, "Biometric authentication successful")
            } else {
                authenticationState = .denied
                AppLog.notice(.auth, "Biometric authentication denied")
            }
            
            isAuthenticating = false
            return success
            
        } catch {
            await handleAuthenticationError(error)
            isAuthenticating = false
            return false
        }
    }
    
    /// Authenticates using device passcode as fallback
    /// - Parameter reason: Human-readable reason for authentication request
    /// - Returns: True if authentication was successful
    func authenticateWithPasscode(reason: String = "Access secure recordings") async -> Bool {
        guard isAuthenticationRequired else {
            authenticationState = .authenticated
            return true
        }
        
        isAuthenticating = true
        authenticationState = .notEvaluated
        
        let context = LAContext()
        context.localizedFallbackTitle = "Cancel"
        
        var error: NSError?
        
        // Check if device passcode is available
        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else {
            if let error = error {
                await handleAuthenticationError(error)
            } else {
                authenticationState = .devicePasscodeNotSet
            }
            isAuthenticating = false
            return false
        }
        
        do {
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthentication,
                localizedReason: reason
            )
            
            if success {
                authenticationState = .authenticated
                recordSuccessfulAuthentication()
                AppLog.info(.auth, "Passcode authentication successful")
            } else {
                authenticationState = .denied
                AppLog.notice(.auth, "Passcode authentication denied")
            }
            
            isAuthenticating = false
            return success
            
        } catch {
            await handleAuthenticationError(error)
            isAuthenticating = false
            return false
        }
    }
    
    /// Resets authentication state (requires re-authentication)
    func resetAuthenticationState() {
        authenticationState = .notEvaluated
        userDefaults.removeObject(forKey: lastAuthenticationTimeKey)
        AppLog.info(.auth, "Authentication state reset")
    }
    
    /// Forces a fresh biometric capability check.
    /// Call when application state changes (e.g., foreground) to ensure cached data is current.
    func refreshBiometricCapabilities() {
        updateBiometricType()
    }
    
    /// Gets the cached biometric type determined during initialization or the most recent refresh.
    /// - Returns: The current `BiometricType` without mutating internal state.
    func getCurrentBiometricType() -> BiometricType {
        return biometricType
    }
    
    /// Checks if the device has any form of authentication set up
    /// - Returns: True if device has passcode or biometrics configured
    func isDeviceSecure() -> Bool {
        let context = LAContext()
        var error: NSError?
        return context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error)
    }
    
    // MARK: - Private Methods
    
    private func loadSettings() {
        isAuthenticationRequired = userDefaults.bool(forKey: authenticationRequiredKey)
    }
    
    private func updateBiometricType() {
        let context = LAContext()
        var error: NSError?
        
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            biometricType = .none
            return
        }
        
        switch context.biometryType {
        case .none:
            biometricType = .none
        case .touchID:
            biometricType = .touchID
        case .faceID:
            biometricType = .faceID
        case .opticID:
            if #available(iOS 17.0, *) {
                biometricType = .opticID
            } else {
                biometricType = .none
            }
        @unknown default:
            biometricType = .none
        }
    }
    
    private func isRecentlyAuthenticated() -> Bool {
        guard let lastAuthTime = userDefaults.object(forKey: lastAuthenticationTimeKey) as? Date else {
            return false
        }
        
        let timeInterval = Date().timeIntervalSince(lastAuthTime)
        let fiveMinutes: TimeInterval = 5 * 60
        
        return timeInterval < fiveMinutes
    }
    
    private func recordSuccessfulAuthentication() {
        userDefaults.set(Date(), forKey: lastAuthenticationTimeKey)
    }
    
    private func handleAuthenticationError(_ error: Error) async {
        if let laError = error as? LAError {
            switch laError.code {
            case .biometryNotAvailable:
                authenticationState = .biometricUnavailable
                AppLog.notice(.auth, "Biometric authentication not available")
                
            case .biometryNotEnrolled:
                authenticationState = .biometricNotEnrolled
                AppLog.notice(.auth, "Biometric authentication not enrolled")
                
            case .passcodeNotSet:
                authenticationState = .devicePasscodeNotSet
                AppLog.notice(.auth, "Device passcode not set")
                
            case .userCancel:
                authenticationState = .denied
                AppLog.notice(.auth, "User cancelled authentication")
                
            case .userFallback:
                // User chose to use passcode instead of biometrics
                let success = await authenticateWithPasscode()
                if !success {
                    authenticationState = .denied
                }
                
            case .systemCancel:
                authenticationState = .denied
                AppLog.notice(.auth, "System cancelled authentication")
                
            case .authenticationFailed:
                authenticationState = .denied
                AppLog.notice(.auth, "Authentication failed")
                
            default:
                authenticationState = .error(laError.localizedDescription)
                AppLog.error(.auth, "Authentication error: \(laError.localizedDescription)")
            }
        } else {
            authenticationState = .error(error.localizedDescription)
            AppLog.error(.auth, "Authentication error: \(error.localizedDescription)")
        }
    }
}

// MARK: - Extensions

extension AuthenticationState: Equatable {
    static func == (lhs: AuthenticationState, rhs: AuthenticationState) -> Bool {
        switch (lhs, rhs) {
        case (.notEvaluated, .notEvaluated),
             (.authenticated, .authenticated),
             (.denied, .denied),
             (.biometricUnavailable, .biometricUnavailable),
             (.biometricNotEnrolled, .biometricNotEnrolled),
             (.devicePasscodeNotSet, .devicePasscodeNotSet):
            return true
        case (.error(let lhsMessage), .error(let rhsMessage)):
            return lhsMessage == rhsMessage
        default:
            return false
        }
    }
}

extension AuthenticationState {
    /// User-friendly description of the authentication state
    var description: String {
        switch self {
        case .notEvaluated:
            return "Authentication not evaluated"
        case .authenticated:
            return "Authenticated"
        case .denied:
            return "Authentication denied"
        case .biometricUnavailable:
            return "Biometric authentication unavailable"
        case .biometricNotEnrolled:
            return "Biometric authentication not set up"
        case .devicePasscodeNotSet:
            return "Device passcode not set"
        case .error(let message):
            return "Error: \(message)"
        }
    }
    
    /// Whether the current state represents successful authentication
    var isAuthenticated: Bool {
        if case .authenticated = self {
            return true
        }
        return false
    }
} 
