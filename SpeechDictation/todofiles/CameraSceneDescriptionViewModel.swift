import SwiftUI
import AVFoundation
import Vision
import CoreML
import Combine

/// ViewModel for managing camera scene description and object detection
/// This actor handles the coordination between camera input and ML models
@MainActor
final class CameraSceneDescriptionViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var detectedObjects: [VNRecognizedObjectObservation] = []
    @Published var sceneLabel: String? = nil
    @Published var errorMessage: String? = nil
    @Published var isProcessing = false
    
    // MARK: - Private Properties
    private let objectDetector: ObjectDetectionModel?
    private let sceneDescriber: SceneDescribingModel?
    private let processingQueue = DispatchQueue(label: "CameraSceneDescriptionViewModel.processingQueue", qos: .userInitiated)
    private var cancellables = Set<AnyCancellable>()
    private let sampleBufferProcessor = SampleBufferProcessor()
    
    // MARK: - Initialization
    
    /// Initialize the ViewModel with ML models
    /// - Parameters:
    ///   - objectDetector: Model for object detection (optional)
    ///   - sceneDescriber: Model for scene description (optional)
    init(objectDetector: ObjectDetectionModel?, sceneDescriber: SceneDescribingModel?) {
        self.objectDetector = objectDetector
        self.sceneDescriber = sceneDescriber
    }
    
    // MARK: - Sample Buffer Processing
    
    /// Processes a sample buffer from the camera feed
    /// - Parameter sampleBuffer: The camera sample buffer to process
    /// - Note: This method is designed to be called from the camera capture callback
    func processSampleBuffer(_ sampleBuffer: CMSampleBuffer) {
        guard !isProcessing else { return }
        
        // Extract pixel buffer from sample buffer
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            Task { @MainActor in
                self.errorMessage = "Failed to get pixel buffer from sample"
            }
            return
        }
        
        // Process on background queue to avoid blocking the camera
        Task {
            await processPixelBuffer(pixelBuffer)
        }
    }
    
    /// Processes a pixel buffer using the configured ML models
    /// - Parameter pixelBuffer: The pixel buffer to process
    private func processPixelBuffer(_ pixelBuffer: CVPixelBuffer) async {
        await MainActor.run {
            self.isProcessing = true
            self.errorMessage = nil
        }
        
        // Process object detection and scene description concurrently
        async let objectDetectionTask = processObjectDetection(pixelBuffer)
        async let sceneDescriptionTask = processSceneDescription(pixelBuffer)
        
        // Wait for both tasks to complete
        let (detectedObjects, sceneDescription) = await (objectDetectionTask, sceneDescriptionTask)
        
        // Update UI on main thread
        await MainActor.run {
            self.detectedObjects = detectedObjects
            self.sceneLabel = sceneDescription
            self.isProcessing = false
        }
    }
    
    /// Processes object detection on the pixel buffer
    /// - Parameter pixelBuffer: The pixel buffer to analyze
    /// - Returns: Array of detected objects
    private func processObjectDetection(_ pixelBuffer: CVPixelBuffer) async -> [VNRecognizedObjectObservation] {
        guard let objectDetector = objectDetector else { return [] }
        
        do {
            return try await objectDetector.detectObjects(from: pixelBuffer)
        } catch {
            await MainActor.run {
                self.errorMessage = "Object detection failed: \(error.localizedDescription)"
            }
            return []
        }
    }
    
    /// Processes scene description on the pixel buffer
    /// - Parameter pixelBuffer: The pixel buffer to analyze
    /// - Returns: Scene description string or nil
    private func processSceneDescription(_ pixelBuffer: CVPixelBuffer) async -> String? {
        guard let sceneDescriber = sceneDescriber else { return nil }
        
        do {
            return try await sceneDescriber.classifyScene(from: pixelBuffer)
        } catch {
            await MainActor.run {
                self.errorMessage = "Scene description failed: \(error.localizedDescription)"
            }
            return nil
        }
    }
    
    // MARK: - Error Handling
    
    /// Clears the current error message
    func clearError() {
        errorMessage = nil
    }
}

// MARK: - Supporting Types

/// Helper class for processing sample buffers
/// This class handles the conversion from CMSampleBuffer to CVPixelBuffer
private class SampleBufferProcessor {
    
    /// Extracts a CVPixelBuffer from a CMSampleBuffer
    /// - Parameter sampleBuffer: The sample buffer to process
    /// - Returns: The extracted pixel buffer or nil if extraction fails
    func extractPixelBuffer(from sampleBuffer: CMSampleBuffer) -> CVPixelBuffer? {
        return CMSampleBufferGetImageBuffer(sampleBuffer)
    }
}
