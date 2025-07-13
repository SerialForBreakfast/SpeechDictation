import SwiftUI
import AVFoundation

/// A view that handles camera permission requests and provides user guidance
/// This view ensures proper camera access before launching the camera experience
struct CameraPermissionsView: View {
    @State private var authorizationStatus: AVAuthorizationStatus = .notDetermined
    @State private var showingSettings = false
    @Environment(\.dismiss) private var dismiss
    
    let onPermissionGranted: () -> Void
    
    var body: some View {
        NavigationView {
            VStack(spacing: 32) {
                // Header illustration
                VStack(spacing: 16) {
                    Image(systemName: cameraIcon)
                        .font(.system(size: 72))
                        .foregroundColor(iconColor)
                        .accessibilityHidden(true)
                    
                    Text(titleText)
                        .font(.title)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                        .accessibilityAddTraits(.isHeader)
                        .accessibilityHeading(.h1)
                }
                .padding(.top, 60)
                
                // Description
                Text(descriptionText)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                    .accessibilityLabel(accessibilityDescription)
                
                // Features list
                VStack(alignment: .leading, spacing: 12) {
                    FeatureRow(
                        icon: "viewfinder",
                        title: "Real-time Object Detection",
                        description: "Identifies objects in your camera view"
                    )
                    
                    FeatureRow(
                        icon: "eye",
                        title: "Scene Description",
                        description: "Provides context about your environment"
                    )
                    
                    FeatureRow(
                        icon: "accessibility",
                        title: "Accessibility Features",
                        description: "Audio descriptions for visual content"
                    )
                    
                    FeatureRow(
                        icon: "lock.shield",
                        title: "Privacy Protected",
                        description: "All processing happens on your device"
                    )
                }
                .padding(.horizontal, 24)
                .accessibilityElement(children: .contain)
                .accessibilityLabel("Camera features")
                
                Spacer()
                
                // Action buttons
                VStack(spacing: 16) {
                    Button(action: requestCameraPermission) {
                        Text(primaryButtonText)
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(primaryButtonColor)
                            .cornerRadius(12)
                    }
                    .disabled(authorizationStatus == .restricted)
                    .accessibilityLabel(primaryButtonAccessibilityLabel)
                    .accessibilityHint(primaryButtonAccessibilityHint)
                    
                    if authorizationStatus == .denied {
                        Button(action: { showingSettings = true }) {
                            Text("Open Settings")
                                .font(.subheadline)
                                .foregroundColor(.blue)
                        }
                        .accessibilityLabel("Open Settings")
                        .accessibilityHint("Opens the Settings app to manually enable camera permission")
                    }
                    
                    Button(action: { dismiss() }) {
                        Text("Not Now")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .accessibilityLabel("Not Now")
                    .accessibilityHint("Return to main menu without enabling camera")
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }
            .navigationTitle("Camera Access")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .accessibilityLabel("Cancel")
                    .accessibilityHint("Return to main menu")
                }
            }
        }
        .onAppear {
            checkCameraPermission()
        }
        .sheet(isPresented: $showingSettings) {
            SettingsRedirectView()
        }
    }
    
    // MARK: - Helper Methods
    
    /// Checks the current camera authorization status
    private func checkCameraPermission() {
        authorizationStatus = AVCaptureDevice.authorizationStatus(for: .video)
        
        if authorizationStatus == .authorized {
            onPermissionGranted()
        }
    }
    
    /// Requests camera permission from the user
    private func requestCameraPermission() {
        switch authorizationStatus {
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    self.authorizationStatus = granted ? .authorized : .denied
                    if granted {
                        self.onPermissionGranted()
                    }
                }
            }
        case .authorized:
            onPermissionGranted()
        case .denied, .restricted:
            showingSettings = true
        @unknown default:
            break
        }
    }
    
    // MARK: - Computed Properties
    
    private var cameraIcon: String {
        switch authorizationStatus {
        case .authorized:
            return "camera.fill"
        case .denied, .restricted:
            return "camera.slash.fill"
        default:
            return "camera"
        }
    }
    
    private var iconColor: Color {
        switch authorizationStatus {
        case .authorized:
            return .green
        case .denied, .restricted:
            return .red
        default:
            return .blue
        }
    }
    
    private var titleText: String {
        switch authorizationStatus {
        case .authorized:
            return "Camera Ready"
        case .denied:
            return "Camera Access Denied"
        case .restricted:
            return "Camera Restricted"
        default:
            return "Enable Camera Access"
        }
    }
    
    private var descriptionText: String {
        switch authorizationStatus {
        case .authorized:
            return "Camera access is enabled. You can now use live object detection and scene description features."
        case .denied:
            return "Camera access was denied. To use camera features, please enable camera access in Settings."
        case .restricted:
            return "Camera access is restricted on this device. Camera features are not available."
        default:
            return "Speech Dictation needs camera access to provide live object detection and scene description features."
        }
    }
    
    private var accessibilityDescription: String {
        return "\(descriptionText) This enables real-time object detection, scene description, accessibility features, and privacy-protected processing on your device."
    }
    
    private var primaryButtonText: String {
        switch authorizationStatus {
        case .authorized:
            return "Continue to Camera"
        case .denied:
            return "Enable in Settings"
        case .restricted:
            return "Camera Unavailable"
        default:
            return "Allow Camera Access"
        }
    }
    
    private var primaryButtonColor: Color {
        switch authorizationStatus {
        case .restricted:
            return .gray
        default:
            return .blue
        }
    }
    
    private var primaryButtonAccessibilityLabel: String {
        switch authorizationStatus {
        case .authorized:
            return "Continue to Camera"
        case .denied:
            return "Enable camera access in Settings"
        case .restricted:
            return "Camera unavailable"
        default:
            return "Allow camera access"
        }
    }
    
    private var primaryButtonAccessibilityHint: String {
        switch authorizationStatus {
        case .authorized:
            return "Proceeds to the camera view with object detection"
        case .denied:
            return "Opens Settings app to enable camera permission"
        case .restricted:
            return "Camera is restricted and cannot be enabled"
        default:
            return "Requests permission to use the camera for object detection"
        }
    }
}

/// A row displaying a camera feature with icon and description
struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(.blue)
                .frame(width: 32, height: 32)
                .accessibilityHidden(true)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(description)")
    }
}

/// A view that provides guidance for opening Settings app
struct SettingsRedirectView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Image(systemName: "gear")
                    .font(.system(size: 64))
                    .foregroundColor(.blue)
                    .accessibilityHidden(true)
                
                Text("Open Settings")
                    .font(.title)
                    .fontWeight(.bold)
                    .accessibilityAddTraits(.isHeader)
                
                Text("To enable camera access:\n\n1. Open the Settings app\n2. Find 'Speech Dictation'\n3. Tap 'Camera'\n4. Select 'Allow'")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                Button(action: openSettings) {
                    Text("Open Settings")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(12)
                }
                .padding(.horizontal)
                .accessibilityLabel("Open Settings app")
                .accessibilityHint("Opens the Settings app where you can enable camera access")
                
                Spacer()
            }
            .padding()
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func openSettings() {
        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsUrl)
        }
        dismiss()
    }
} 