import SwiftUI
import AVFoundation

/// A coordinating view that manages the camera experience flow
/// Handles permission requests and transitions to the camera interface
struct CameraExperienceView: View {
    @State private var showingPermissions = true
    @State private var hasPermission = false
    
    var body: some View {
        Group {
            if hasPermission {
                // Show the actual camera view once permission is granted
                createCameraView()
                    .navigationBarHidden(true)
            } else {
                // Show permission request view first
                CameraPermissionsView {
                    // Called when permission is granted
                    withAnimation(.easeInOut(duration: 0.5)) {
                        hasPermission = true
                        showingPermissions = false
                    }
                }
            }
        }
        .onAppear {
            checkInitialPermission()
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Camera Experience")
    }
    
    // MARK: - Helper Methods
    
    /// Checks if camera permission is already granted
    private func checkInitialPermission() {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        if status == .authorized {
            hasPermission = true
            showingPermissions = false
        }
    }
    
    /// Creates the actual camera view with ML models
    /// - Returns: Configured CameraSceneDescriptionView
    private func createCameraView() -> some View {
        let objectDetector = YOLOv3Model()
        let sceneDescriber = Places365SceneDescriber()
        
        if let detector = objectDetector {
            return AnyView(
                CameraSceneDescriptionView(
                    objectDetector: detector,
                    sceneDescriber: sceneDescriber
                )
                .accessibilityLabel("Live Camera View")
                .accessibilityHint("Camera feed with real-time object detection and scene description overlays")
            )
        } else {
            // Fallback if model loading fails
            return AnyView(
                CameraErrorView()
            )
        }
    }
}

/// A controls menu for camera settings and options
struct CameraControlsMenu: View {
    @State private var showingSettings = false
    
    var body: some View {
        Menu {
            Button(action: { showingSettings = true }) {
                Label("Camera Settings", systemImage: "gear")
            }
            .accessibilityLabel("Camera Settings")
            .accessibilityHint("Opens camera and accessibility settings")
            
            Button(action: toggleFlashlight) {
                Label("Toggle Flashlight", systemImage: "flashlight.on.fill")
            }
            .accessibilityLabel("Toggle Flashlight")
            .accessibilityHint("Turns the device flashlight on or off")
            
            Button(action: shareCamera) {
                Label("Share Camera View", systemImage: "square.and.arrow.up")
            }
            .accessibilityLabel("Share Camera View")
            .accessibilityHint("Share or export the current camera detection results")
        } label: {
            Image(systemName: "ellipsis.circle")
                .accessibilityLabel("Camera Menu")
                .accessibilityHint("Opens camera options and settings")
        }
        .sheet(isPresented: $showingSettings) {
            CameraSettingsView()
        }
    }
    
    private func toggleFlashlight() {
        guard let device = AVCaptureDevice.default(for: .video),
              device.hasTorch else { return }
        
        do {
            try device.lockForConfiguration()
            device.torchMode = device.isTorchActive ? .off : .on
            device.unlockForConfiguration()
        } catch {
            print("Flashlight error: \(error)")
        }
    }
    
    private func shareCamera() {
        // TODO: Implement camera sharing functionality
        print("Share camera functionality - to be implemented")
    }
}

/// Error view shown when camera models fail to load
struct CameraErrorView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 64))
                .foregroundColor(.orange)
                .accessibilityHidden(true)
            
            Text("Camera Models Unavailable")
                .font(.title2)
                .fontWeight(.semibold)
                .accessibilityAddTraits(.isHeader)
            
            Text("The required machine learning models for object detection could not be loaded. Please try again later or contact support if the problem persists.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            VStack(spacing: 12) {
                Button(action: retryModelLoading) {
                    Text("Try Again")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(12)
                }
                .accessibilityLabel("Try Again")
                .accessibilityHint("Attempts to reload the camera models")
                
                Button(action: { dismiss() }) {
                    Text("Back to Menu")
                        .font(.subheadline)
                        .foregroundColor(.blue)
                }
                .accessibilityLabel("Back to Menu")
                .accessibilityHint("Returns to the main experience selection screen")
            }
            .padding(.horizontal)
        }
        .padding()
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Camera Error: Models unavailable")
    }
    
    private func retryModelLoading() {
        // TODO: Implement model retry logic
        print("Retry model loading - to be implemented")
    }
}

/// Camera settings view for advanced options
struct CameraSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var settings = CameraSettingsManager.shared
    
    var body: some View {
        NavigationView {
            Form {
                Section("Detection Features") {
                    Toggle("Object Detection", isOn: $settings.enableObjectDetection)
                        .accessibilityHint("Enables or disables real-time object detection overlays")
                    
                    Toggle("Scene Description", isOn: $settings.enableSceneDescription)
                        .accessibilityHint("Enables or disables scene classification and description")
                    
                    Toggle("Audio Descriptions", isOn: $settings.enableAudioDescriptions)
                        .accessibilityHint("Enables spoken descriptions of detected objects and scenes")
                }
                
                Section("Camera Controls") {
                    Toggle("Autofocus", isOn: $settings.enableAutofocus)
                        .accessibilityHint("When enabled, camera automatically focuses. When disabled, tap the screen to focus manually")
                }
                
                Section("Detection Sensitivity") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Confidence Threshold")
                            .font(.subheadline)
                        
                        HStack {
                            Text("Low")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Slider(value: $settings.detectionSensitivity, in: 0.1...0.9, step: 0.1)
                                .accessibilityLabel("Detection sensitivity")
                                .accessibilityValue("\(Int(settings.detectionSensitivity * 100)) percent")
                                .accessibilityHint("Adjusts how confident the system must be before showing a detection")
                            
                            Text("High")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Text("Higher values show fewer but more confident detections")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Section("Update Frequency") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Scene Description Updates")
                            .font(.subheadline)
                        
                        HStack {
                            Text("Fast\n(0.5s)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                            
                            Slider(value: $settings.sceneUpdateFrequency, in: 0.5...5.0, step: 0.5)
                                .accessibilityLabel("Scene update frequency")
                                .accessibilityValue("\(settings.sceneUpdateFrequency, specifier: "%.1f") seconds")
                                .accessibilityHint("Controls how often the scene description text updates")
                            
                            Text("Slow\n(5.0s)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        
                        Text("Current: \(settings.sceneUpdateFrequency, specifier: "%.1f") seconds between updates")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("Slower updates are easier to read but less responsive")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Section("Accessibility") {
                    NavigationLink("Voice Settings") {
                        VoiceSettingsView()
                    }
                    .accessibilityHint("Configure voice and speech settings for audio descriptions")
                    
                    NavigationLink("Visual Settings") {
                        VisualSettingsView()
                    }
                    .accessibilityHint("Configure visual overlays and display options")
                }
                
                Section("About") {
                    HStack {
                        Text("Model Version")
                        Spacer()
                        Text("YOLOv3Tiny")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Privacy")
                        Spacer()
                        Text("On-Device Only")
                            .foregroundColor(.green)
                    }
                    .accessibilityLabel("Privacy: All processing happens on device only")
                }
                
                Section("Model Management") {
                    // NavigationLink("Browse Model Store") {
                    //     ModelManagementView()
                    // }
                    // .accessibilityHint("Browse and download additional ML models")
                    
                    // NavigationLink("Current Models") {
                    //     CurrentModelsView()
                    // }
                    // .accessibilityHint("View and manage currently loaded models")
                }
                
                Section("Reset") {
                    Button("Reset to Defaults") {
                        resetSettings()
                    }
                    .foregroundColor(.red)
                    .accessibilityLabel("Reset all settings to defaults")
                    .accessibilityHint("Resets all camera and detection settings to their original values")
                }
            }
            .navigationTitle("Camera Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Camera Settings")
    }
    
    // MARK: - Helper Methods
    
    /// Resets all camera settings to their default values
    private func resetSettings() {
        settings.resetToDefaults()
        
        // Provide haptic feedback for the reset action
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
                    print("Camera settings reset by user")
    }
}

/// Voice settings for audio descriptions
struct VoiceSettingsView: View {
    @State private var speechRate: Double = 0.5
    @State private var speechVolume: Double = 1.0
    @State private var selectedVoice = "Default"
    
    var body: some View {
        Form {
            Section("Speech Rate") {
                HStack {
                    Text("Slow")
                        .font(.caption)
                    Slider(value: $speechRate, in: 0.1...1.0)
                        .accessibilityLabel("Speech rate")
                        .accessibilityValue("\(Int(speechRate * 100)) percent")
                    Text("Fast")
                        .font(.caption)
                }
            }
            
            Section("Volume") {
                HStack {
                    Text("Quiet")
                        .font(.caption)
                    Slider(value: $speechVolume, in: 0.1...1.0)
                        .accessibilityLabel("Speech volume")
                        .accessibilityValue("\(Int(speechVolume * 100)) percent")
                    Text("Loud")
                        .font(.caption)
                }
            }
        }
        .navigationTitle("Voice Settings")
        .navigationBarTitleDisplayMode(.inline)
    }
}

/// Visual settings for camera overlays
struct VisualSettingsView: View {
    @State private var showBoundingBoxes = true
    @State private var showConfidenceScores = true
    @State private var overlayOpacity: Double = 0.8
    
    var body: some View {
        Form {
            Section("Overlays") {
                Toggle("Bounding Boxes", isOn: $showBoundingBoxes)
                    .accessibilityHint("Shows rectangular boxes around detected objects")
                
                Toggle("Confidence Scores", isOn: $showConfidenceScores)
                    .accessibilityHint("Shows percentage confidence for each detection")
            }
            
            Section("Appearance") {
                VStack(alignment: .leading) {
                    Text("Overlay Opacity")
                    Slider(value: $overlayOpacity, in: 0.1...1.0)
                        .accessibilityLabel("Overlay opacity")
                        .accessibilityValue("\(Int(overlayOpacity * 100)) percent")
                }
            }
        }
        .navigationTitle("Visual Settings")
        .navigationBarTitleDisplayMode(.inline)
    }
} 