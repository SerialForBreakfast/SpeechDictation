import SwiftUI
import AVFoundation
import Vision

/// View that displays a live camera feed with object detection and scene description overlays.
/// Features two separate text overlays and navigation controls
struct CameraSceneDescriptionView: View {
    @StateObject private var viewModel: CameraSceneDescriptionViewModel
    @State private var showingSettings = false
    @Environment(\.dismiss) private var dismiss
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
                // Top bar with navigation and settings
                HStack {
                    // Back button
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.white)
                            .padding(12)
                            .background(Color.black.opacity(0.6))
                            .clipShape(Circle())
                    }
                    .accessibilityLabel("Back")
                    .accessibilityHint("Returns to the previous screen")
                    
                    Spacer()
                    
                    // Settings button
                    Button(action: { showingSettings = true }) {
                        Image(systemName: "gear")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.white)
                            .padding(12)
                            .background(Color.black.opacity(0.6))
                            .clipShape(Circle())
                    }
                    .accessibilityLabel("Settings")
                    .accessibilityHint("Opens camera detection and display settings")
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                
                Spacer()
                
                // Bottom overlays
                VStack(spacing: 12) {
                    // Scene Description Overlay
                    if let scene = viewModel.sceneLabel {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Scene Environment")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.white.opacity(0.8))
                            
                            Text(scene)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                                .lineLimit(2)
                                .multilineTextAlignment(.leading)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Color.blue.opacity(0.8))
                        .cornerRadius(12)
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("Scene: \(scene)")
                        .accessibilityHint("Current environment classification")
                    }
                    
                    // Detected Objects Overlay
                    if !viewModel.detectedObjects.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Detected Objects")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.white.opacity(0.8))
                            
                            Text(formatDetectedObjects())
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                                .lineLimit(3)
                                .multilineTextAlignment(.leading)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Color.green.opacity(0.8))
                        .cornerRadius(12)
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("Objects: \(formatDetectedObjects())")
                        .accessibilityHint("Currently detected objects in the scene")
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
                        .background(Color.red.opacity(0.8))
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
    
    /// Formats detected objects into a readable string
    /// - Returns: Formatted string of detected objects with confidence
    private func formatDetectedObjects() -> String {
        let objectStrings = viewModel.detectedObjects.compactMap { object -> String? in
            guard let topLabel = object.labels.first else { return nil }
            let confidence = Int(topLabel.confidence * 100)
            return "\(topLabel.identifier.capitalized) (\(confidence)%)"
        }
        
        // Show top 3 objects to prevent overlay from being too long
        let topObjects = Array(objectStrings.prefix(3))
        return topObjects.joined(separator: ", ")
    }
}

/// View that displays bounding boxes for detected objects
struct ObjectBoundingBoxView: View {
    let boundingBox: CGRect
    let label: String
    let confidence: VNConfidence

    var body: some View {
        GeometryReader { geometry in
            let transformedRect = transformBoundingBox(boundingBox, to: geometry.size)
            
            ZStack(alignment: .topLeading) {
                // Bounding box rectangle
                Rectangle()
                    .stroke(Color.green, lineWidth: 2)
                    .frame(width: transformedRect.width, height: transformedRect.height)
                    .position(x: transformedRect.midX, y: transformedRect.midY)

                // Object label
                Text("\(label.capitalized) \(String(format: "%.0f", confidence * 100))%")
                    .font(.caption2)
                    .fontWeight(.medium)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(Color.green.opacity(0.9))
                    .foregroundColor(.white)
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
}

#Preview {
    CameraSceneDescriptionView(
        objectDetector: YOLOv3Model()!,
        sceneDescriber: Places365SceneDescriber()
    )
}
