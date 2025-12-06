//
//  SecureRecordingsView.swift
//  SpeechDictation
//
//  Created by AI Assistant on 1/27/25.
//
//  Secure recordings management interface with authentication gating.
//  Provides comprehensive management of private recordings with complete file protection.
//  Follows existing NavigationView and List patterns for consistency.
//

import SwiftUI

/// Main view for managing secure private recordings
/// Integrates authentication, recording controls, and session management
/// Uses structured concurrency for all async operations
struct SecureRecordingsView: View {
    @Binding var isPresented: Bool
    
    @StateObject private var secureRecordingManager = SecureRecordingManager.shared
    @StateObject private var authManager = LocalAuthenticationManager.shared
    @State private var showingNewRecordingDialog = false
    @State private var newRecordingTitle = ""
    @State private var showingDeleteConfirmation = false
    @State private var sessionToDelete: SecureRecordingSession?
    @State private var playbackSession: SecureRecordingSession?
    @State private var isAuthenticating = false
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        NavigationView {
            Group {
                if authManager.isAuthenticationRequired && !authManager.authenticationState.isAuthenticated {
                    authenticationView
                } else {
                    recordingsListView
                }
            }
            .navigationTitle("Secure Recordings")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarLeading) {
                    Button("Close") {
                        isPresented = false
                    }
                }
                
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    if authManager.authenticationState.isAuthenticated {
                        if secureRecordingManager.isRecording {
                            Button("Stop Recording") {
                                Task {
                                    await secureRecordingManager.stopSecureRecording()
                                }
                            }
                            .foregroundColor(.red)
                        } else {
                            Button(action: {
                                showingNewRecordingDialog = true
                            }) {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundColor(.accentColor)
                            }
                        }
                    }
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .onAppear {
            authManager.refreshBiometricCapabilities()
            Task {
                await authenticateIfRequired()
            }
        }
        .alert("New Secure Recording", isPresented: $showingNewRecordingDialog) {
            TextField("Recording title (optional)", text: $newRecordingTitle)
            Button("Start Recording") {
                Task {
                    await startNewRecording()
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This will create a private recording with complete file protection and on-device transcription.")
        }
        .alert("Delete Recording", isPresented: $showingDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                Task {
                    if let session = sessionToDelete {
                        await deleteRecording(session)
                    }
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            if let session = sessionToDelete {
                Text("Are you sure you want to permanently delete \"\(session.displayTitle)\"? This action cannot be undone.")
            }
        }
        .sheet(item: $playbackSession) { session in
            SecurePlaybackView(session: session)
        }
    }
    
    // MARK: - Authentication View
    
    /// Authentication interface with biometric and passcode options
    private var authenticationView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            // Security icon
            Image(systemName: "lock.shield.fill")
                .font(.system(size: 64))
                .foregroundColor(.accentColor)
                .padding(.bottom, 16)
            
            VStack(spacing: 16) {
                Text("Secure Recordings")
                    .font(.title)
                    .fontWeight(.semibold)
                
                Text("Private recordings are protected with complete file protection and require authentication to access.")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
            }
            
            VStack(spacing: 12) {
                // Primary authentication button
                Button(action: {
                    Task {
                        await authenticate()
                    }
                }) {
                    HStack {
                        Image(systemName: biometricIcon)
                            .font(.title2)
                        Text(authenticationButtonText)
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .disabled(isAuthenticating)
                
                // Passcode fallback (if biometrics available)
                if authManager.isBiometricAuthenticationAvailable() {
                    Button(action: {
                        Task {
                            await authenticateWithPasscode()
                        }
                    }) {
                        Text("Use Passcode")
                            .font(.subheadline)
                            .foregroundColor(.accentColor)
                    }
                    .disabled(isAuthenticating)
                }
            }
            .padding(.horizontal)
            
            Spacer()
            
            // Authentication state message
            if case .error(let message) = authManager.authenticationState {
                Text(message)
                    .font(.caption)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Recordings List View
    
    /// Main recordings management interface with list and controls
    private var recordingsListView: some View {
        VStack {
            // Current recording status
            if secureRecordingManager.isRecording, let currentSession = secureRecordingManager.currentSession {
                currentRecordingHeader(session: currentSession)
            }
            
            // Recordings list
            List {
                ForEach(secureRecordingManager.getAllSessions()) { session in
                    SecureRecordingRow(
                        session: session,
                        onDelete: { sessionToDelete = session; showingDeleteConfirmation = true },
                        onPlay: { playbackSession = session }
                    )
                }
            }
            .listStyle(PlainListStyle())
            .overlay(
                Group {
                    if secureRecordingManager.allSessions.isEmpty && !secureRecordingManager.isRecording {
                        emptyStateView
                    }
                }
            )
        }
    }
    
    /// Current recording status header
    private func currentRecordingHeader(session: SecureRecordingSession) -> some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "record.circle.fill")
                    .foregroundColor(.red)
                    .font(.title2)
                Text("Recording: \(session.displayTitle)")
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer()
            }
            
            HStack {
                Text("Duration: \(formatDuration(secureRecordingManager.recordingDuration))")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Spacer()
            }
        }
        .padding()
        .background(Color.red.opacity(0.1))
        .cornerRadius(8)
        .padding(.horizontal)
    }
    
    /// Empty state when no recordings exist
    private var emptyStateView: some View {
        VStack(spacing: 16) {
                                        Image(systemName: "waveform.circle.fill")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            Text("No Secure Recordings")
                .font(.title2)
                .foregroundColor(.secondary)
            
            Text("Tap the + button to create your first private recording with complete file protection.")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Authentication Logic
    
    /// Performs initial authentication check on view appearance
    private func authenticateIfRequired() async {
        guard authManager.isAuthenticationRequired else { return }
        
        if !authManager.authenticationState.isAuthenticated {
            await authenticate()
        }
    }
    
    /// Authenticates using primary method (biometrics or passcode)
    private func authenticate() async {
        isAuthenticating = true
        defer { isAuthenticating = false }
        
        _ = await authManager.authenticate(reason: "Access secure recordings")
    }
    
    /// Authenticates using device passcode as fallback
    private func authenticateWithPasscode() async {
        isAuthenticating = true
        defer { isAuthenticating = false }
        
        _ = await authManager.authenticateWithPasscode(reason: "Access secure recordings")
    }
    
    // MARK: - Recording Management
    
    /// Starts a new secure recording with user consent
    private func startNewRecording() async {
        let title = newRecordingTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        newRecordingTitle = ""
        
        _ = await secureRecordingManager.startSecureRecording(title: title, hasConsent: true)
    }
    
    /// Deletes a secure recording after confirmation
    private func deleteRecording(_ session: SecureRecordingSession) async {
        _ = await secureRecordingManager.deleteSession(session.id)
        sessionToDelete = nil
    }
    
    // MARK: - Helper Properties
    
    /// Dynamic biometric icon based on device capabilities
    private var biometricIcon: String {
        switch authManager.biometricType {
        case .faceID: return "faceid"
        case .touchID: return "touchid"
        case .opticID: return "opticid"
        case .none: return "key.fill"
        }
    }
    
    /// Dynamic authentication button text based on device capabilities
    private var authenticationButtonText: String {
        switch authManager.biometricType {
        case .faceID: return "Authenticate with Face ID"
        case .touchID: return "Authenticate with Touch ID"
        case .opticID: return "Authenticate with Optic ID"
        case .none: return "Authenticate with Passcode"
        }
    }
    
    /// Formats duration for display
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - Recording Row View

/// Individual row for displaying secure recording session information
struct SecureRecordingRow: View {
    let session: SecureRecordingSession
    let onDelete: () -> Void
    let onPlay: () -> Void
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(session.displayTitle)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(session.startTime.formatted(.dateTime.day().month().hour().minute()))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    if session.isCompleted {
                        Text(formatDuration(session.duration))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    } else {
                        Text("Recording...")
                            .font(.subheadline)
                            .foregroundColor(.red)
                    }
                    
                    Text(formatFileSize(session.audioFileSize))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            // Status indicators
            HStack(spacing: 8) {
                Label("Encrypted", systemImage: "lock.shield.fill")
                    .font(.caption2)
                    .foregroundColor(.green)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                
                Label("On-Device", systemImage: "iphone")
                    .font(.caption2)
                    .foregroundColor(.blue)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                
                if session.hasConsent {
                    Label("Consent", systemImage: "checkmark.circle.fill")
                        .font(.caption2)
                        .foregroundColor(.green)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // Play button on separate line for better layout
            if session.isCompleted {
                Button(action: onPlay) {
                    HStack {
                        Image(systemName: "play.circle.fill")
                        Text("Play")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.accentColor)
                .accessibilityLabel("Play secure recording")
            }
        }
        .padding(.vertical, 4)
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button("Delete", role: .destructive) {
                onDelete()
            }
        }
    }
    
    /// Formats file size for display
    private func formatFileSize(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useMB, .useKB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
    
    /// Formats duration for display
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - Preview Provider

struct SecureRecordingsView_Previews: PreviewProvider {
    static var previews: some View {
        SecureRecordingsView(isPresented: .constant(true))
    }
} 