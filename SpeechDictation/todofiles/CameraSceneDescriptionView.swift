import SwiftUI
import AVFoundation
import Vision

/// View that displays a live camera feed with object detection and scene description overlays.
/// Features two separate text overlays and navigation controls with full dark/light mode support
struct CameraSceneDescriptionView: View {
    @StateObject private var viewModel: CameraSceneDescriptionViewModel
    @State private var showingSettings = false
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @ObservedObject private var settings = CameraSettingsManager.shared
    private let cameraManager = LiveCameraView()

    init(objectDetector: ObjectDetectionModel, sceneDescriber: SceneDescribingModel) {
        _viewModel = StateObject(wrappedValue: CameraSceneDescriptionViewModel(
            objectDetector: objectDetector,
            sceneDescriber: sceneDescriber
        ))
    }

    var body: some View {
        ZStack {
            // Camera preview background
            CameraPreview(session: cameraManager.session, cameraManager: cameraManager)
                .edgesIgnoringSafeArea(.all)
                .onAppear {
                    cameraManager.setSampleBufferHandler(viewModel.processSampleBuffer)
                    cameraManager.startSession()
                }
                .onDisappear {
                    cameraManager.stopSession()
                }

            // Object detection bounding boxes
            ForEach(viewModel.detectedObjects, id: \.uuid) { object in
                if let topLabel = object.labels.first {
                    ObjectBoundingBoxView(boundingBox: object.boundingBox, label: topLabel.identifier, confidence: topLabel.confidence)
                }
            }
            
            // UI Overlays
            VStack {
                // Navigation controls
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 32))
                            .foregroundColor(.white)
                            .background(Color.black.opacity(0.5))
                            .clipShape(Circle())
                            .accessibilityLabel("Close camera")
                            .accessibilityHint("Returns to the previous screen")
                    }
                    
                    Spacer()
                    
                    Button(action: { showingSettings = true }) {
                        Image(systemName: "gear.circle.fill")
                            .font(.system(size: 32))
                            .foregroundColor(.white)
                            .background(Color.black.opacity(0.5))
                            .clipShape(Circle())
                            .accessibilityLabel("Camera settings")
                            .accessibilityHint("Opens camera and detection settings")
                    }
                }
                .padding()
                .padding(.top, 44) // Account for status bar
                
                Spacer()
                
                // Always visible overlay information - conditionally show based on settings
                VStack(spacing: 12) {
                    // Scene Description Overlay - Only show when enabled
                    if settings.enableSceneDescription {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Scene Environment")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(sceneOverlayTextColor)
                            
                            Text(viewModel.sceneLabel ?? "Analyzing scene...")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(sceneOverlayTextColor)
                                .lineLimit(2)
                                .multilineTextAlignment(.leading)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(sceneOverlayBackgroundColor)
                        .cornerRadius(12)
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("Scene: \(viewModel.sceneLabel ?? "Analyzing")")
                        .accessibilityHint("Current environment classification")
                    }
                    
                    // Detected Objects Overlay - Only show when enabled
                    if settings.enableObjectDetection {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Detected Objects")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(objectOverlayTextColor)
                            
                            Text(formatDetectedObjectsWithSpatialContext())
                                .font(adaptiveObjectFont)
                                .fontWeight(.medium)
                                .foregroundColor(objectOverlayTextColor)
                                .lineLimit(adaptiveObjectLineLimit)
                                .multilineTextAlignment(.leading)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, adaptiveObjectPadding)
                        .background(objectOverlayBackgroundColor)
                        .cornerRadius(12)
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("Objects: \(viewModel.spatialSummary)")
                        .accessibilityHint("Currently detected objects with spatial positioning")
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 34) // Account for home indicator
            }

            // Error overlay
            if let error = viewModel.errorMessage {
                VStack {
                    Text("⚠️ \(error)")
                        .font(.subheadline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(errorOverlayBackgroundColor)
                        .cornerRadius(12)
                        .accessibilityLabel("Error: \(error)")
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.top, 80)
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showingSettings) {
            CameraSettingsView()
        }
    }
    
    // MARK: - Helper Methods
    
    /// Formats detected objects into a readable string with proper undetected state
    /// - Returns: Formatted string of detected objects with confidence or undetected message
    private func formatDetectedObjects() -> String {
        guard !viewModel.detectedObjects.isEmpty else {
            return "No objects detected"
        }
        
        let objectStrings = viewModel.detectedObjects.compactMap { object -> String? in
            guard let topLabel = object.labels.first else { return nil }
            let confidence = Int(topLabel.confidence * 100)
            return "\(topLabel.identifier.capitalized) (\(confidence)%)"
        }
        
        // Show more objects for high-confidence detection (up to 6 objects)
        // This supports the user's request for multiple high-confidence object detection
        let maxObjects = min(objectStrings.count, 6)
        let displayedObjects = Array(objectStrings.prefix(maxObjects))
        
        // Format with line breaks for better readability when showing multiple objects
        if displayedObjects.count > 3 {
            return displayedObjects.joined(separator: "\n")
        } else {
            return displayedObjects.joined(separator: ", ")
        }
    }
    
    /// Formats detected objects with spatial context into a readable string
    /// - Returns: Formatted string of detected objects with spatial positioning
    private func formatDetectedObjectsWithSpatialContext() -> String {
        guard !viewModel.spatialDescriptions.isEmpty else {
            return viewModel.spatialSummary.isEmpty ? "No objects detected" : viewModel.spatialSummary
        }
        
        // Use the compact list format for UI display (limit to 4 objects for better readability)
        let limitedDescriptions = Array(viewModel.spatialDescriptions.prefix(4))
        return limitedDescriptions
            .map { $0.spatialDescription }
            .joined(separator: "\n")
    }
    
    // MARK: - Dark/Light Mode Color Helpers
    
    /// Adaptive font size for object display based on number of objects
    private var adaptiveObjectFont: Font {
        return viewModel.detectedObjects.count > 3 ? .caption : .subheadline
    }
    
    /// Adaptive line limit for object display based on number of objects
    private var adaptiveObjectLineLimit: Int {
        return viewModel.detectedObjects.count > 3 ? 6 : 3
    }
    
    /// Adaptive padding for object display based on number of objects
    private var adaptiveObjectPadding: CGFloat {
        return viewModel.detectedObjects.count > 3 ? 16 : 12
    }
    
    /// Scene overlay background color that adapts to dark/light mode - Always blue
    private var sceneOverlayBackgroundColor: Color {
        switch colorScheme {
        case .dark:
            return Color.blue.opacity(0.9)
        case .light:
            return Color.blue.opacity(0.8)
        @unknown default:
            return Color.blue.opacity(0.8)
        }
    }
    
    /// Scene overlay text color that adapts to dark/light mode
    private var sceneOverlayTextColor: Color {
        return .white // White text works well on blue backgrounds in both modes
    }
    
    /// Object overlay background color that adapts to dark/light mode - Always green
    private var objectOverlayBackgroundColor: Color {
        switch colorScheme {
        case .dark:
            return Color.green.opacity(0.9)
        case .light:
            return Color.green.opacity(0.8)
        @unknown default:
            return Color.green.opacity(0.8)
        }
    }
    
    /// Object overlay text color that adapts to dark/light mode
    private var objectOverlayTextColor: Color {
        return .white // White text works well on green backgrounds in both modes
    }
    
    /// Error overlay background color that adapts to dark/light mode
    private var errorOverlayBackgroundColor: Color {
        switch colorScheme {
        case .dark:
            return Color.red.opacity(0.9)
        case .light:
            return Color.red.opacity(0.8)
        @unknown default:
            return Color.red.opacity(0.8)
        }
    }
}

/// View that displays bounding boxes for detected objects with dark/light mode support
struct ObjectBoundingBoxView: View {
    let boundingBox: CGRect
    let label: String
    let confidence: VNConfidence
    
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        GeometryReader { geometry in
            let transformedRect = transformBoundingBox(boundingBox, to: geometry.size)
            
            ZStack(alignment: .topLeading) {
                // Bounding box rectangle
                Rectangle()
                    .stroke(boundingBoxStrokeColor, lineWidth: 2)
                    .frame(width: transformedRect.width, height: transformedRect.height)
                    .position(x: transformedRect.midX, y: transformedRect.midY)

                // Object label
                Text("\(label.capitalized) \(String(format: "%.0f", confidence * 100))%")
                    .font(.caption2)
                    .fontWeight(.medium)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(boundingBoxLabelBackgroundColor)
                    .foregroundColor(boundingBoxLabelTextColor)
                    .cornerRadius(4)
                    .position(x: transformedRect.minX + 4, y: transformedRect.minY - 8)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label) detected with \(Int(confidence * 100))% confidence")
    }
    
    /// Transforms Vision framework bounding box coordinates to SwiftUI view coordinates
    /// - Parameters:
    ///   - boundingBox: The bounding box from Vision framework (normalized coordinates)
    ///   - viewSize: The size of the view to transform to
    /// - Returns: CGRect in view coordinates
    private func transformBoundingBox(_ boundingBox: CGRect, to viewSize: CGSize) -> CGRect {
        // Vision framework uses bottom-left origin (0,0), SwiftUI uses top-left origin
        // Since we set camera orientation to .right, we need to account for the coordinate transformation
        
        // For .right orientation, the coordinates are rotated 90 degrees clockwise
        // Original Vision coords: (x, y) -> Rotated coords: (y, 1-x)
        let rotatedX = boundingBox.origin.y
        let rotatedY = 1 - boundingBox.origin.x - boundingBox.size.width
        let rotatedWidth = boundingBox.size.height
        let rotatedHeight = boundingBox.size.width
        
        // Transform to view coordinates
        let x = rotatedX * viewSize.width
        let y = rotatedY * viewSize.height
        let width = rotatedWidth * viewSize.width
        let height = rotatedHeight * viewSize.height
        
        return CGRect(x: x, y: y, width: width, height: height)
    }
    
    // MARK: - Dark/Light Mode Color Helpers
    
    /// Bounding box stroke color that adapts to dark/light mode
    private var boundingBoxStrokeColor: Color {
        switch colorScheme {
        case .dark:
            return Color.green.opacity(0.9)
        case .light:
            return Color.green.opacity(0.8)
        @unknown default:
            return Color.green.opacity(0.8)
        }
    }
    
    /// Bounding box label background color that adapts to dark/light mode
    private var boundingBoxLabelBackgroundColor: Color {
        switch colorScheme {
        case .dark:
            return Color.green.opacity(0.95)
        case .light:
            return Color.green.opacity(0.9)
        @unknown default:
            return Color.green.opacity(0.9)
        }
    }
    
    /// Bounding box label text color that adapts to dark/light mode
    private var boundingBoxLabelTextColor: Color {
        return .white // White text works well on green backgrounds in both modes
    }
}

#Preview {
    CameraSceneDescriptionView(
        objectDetector: YOLOv3Model()!,
        sceneDescriber: Places365SceneDescriber()
    )
}
