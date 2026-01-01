import Foundation
import Vision
import CoreML
import Combine

/// A concrete implementation of `ObjectDetectionModel` using the YOLOv3Tiny CoreML model.
/// This class handles object detection using the YOLOv3Tiny model with proper concurrency management.
/// Uses configurable confidence threshold from CameraSettingsManager for high-confidence detection.
@available(iOS 15.0, *)
final class YOLOv3Model: ObjectDetectionModel {
    private let model: VNCoreMLModel
    
    // State tracking for logging
    private var lastDetectionCount: Int = -1
    private var lastDetectionState: String = ""
    
    /// Initialize the YOLOv3Model with the YOLOv3Tiny CoreML model
    /// - Note: This initializer is failable and returns nil if the model cannot be loaded
    init?() {
        do {
            let config = MLModelConfiguration()
            config.computeUnits = .all // Use both CPU and GPU for better performance
            
            // Load the YOLOv3Tiny model from the bundle
            guard let modelURL = Bundle.main.url(forResource: "YOLOv3Tiny", withExtension: "mlmodelc") else {
                AppLog.error(.models, "YOLOv3Tiny model not found in bundle")
                return nil
            }
            
            let mlModel = try MLModel(contentsOf: modelURL, configuration: config)
            self.model = try VNCoreMLModel(for: mlModel)
            AppLog.info(.models, "YOLOv3Tiny model loaded successfully")
        } catch {
            AppLog.error(.models, "YOLOv3Model initialization failed: \(error)")
            return nil
        }
    }
    
    /// Detects objects in the given pixel buffer using the YOLOv3Tiny model
    /// - Parameters:
    ///   - pixelBuffer: The pixel buffer containing the image data
    ///   - orientation: The image orientation for proper coordinate transformation
    /// - Returns: Array of detected objects with their bounding boxes and confidence scores
    /// - Note: Uses configurable confidence threshold from CameraSettingsManager for high-confidence detection
    func detectObjects(from pixelBuffer: CVPixelBuffer, orientation: CGImagePropertyOrientation = .right) async throws -> [VNRecognizedObjectObservation] {
        return try await withCheckedThrowingContinuation { continuation in
            let request = VNCoreMLRequest(model: model) { request, error in
                if let error = error {
                    AppLog.error(.camera, "YOLOv3 object detection failed: \(error)")
                    continuation.resume(throwing: error)
                    return
                }
                
                // Extract detected objects from the request results
                let detectedObjects = request.results?.compactMap { result in
                    result as? VNRecognizedObjectObservation
                } ?? []
                
                // Get configurable confidence threshold from settings
                let confidenceThreshold = Float(CameraSettingsManager.shared.detectionSensitivity)
                
                // TEMPORARY: Lower threshold for testing
                let testThreshold = min(confidenceThreshold, 0.1) // Use 10% for testing
                
                // Filter by configurable confidence threshold for high-confidence detection
                let filteredObjects = detectedObjects.filter { $0.confidence > testThreshold }
                
                // Only log when detection state changes
                let currentDetectionCount = filteredObjects.count
                let currentDetectionState = currentDetectionCount == 0 ? "no_objects" : "\(currentDetectionCount)_objects"
                
                if currentDetectionCount != self.lastDetectionCount || currentDetectionState != self.lastDetectionState {
                    if currentDetectionCount == 0 {
                        AppLog.debug(.camera, "No objects detected", dedupeInterval: 1, verboseOnly: true)
                    } else {
                        AppLog.debug(
                            .camera,
                            "YOLOv3 detected \(currentDetectionCount) objects with >\(Int(testThreshold * 100))% confidence",
                            verboseOnly: true
                        )
                        // Log detected objects
                        for (index, object) in filteredObjects.enumerated() {
                            let topLabel = object.labels.first
                            AppLog.debug(
                                .camera,
                                "  \(index + 1). \(topLabel?.identifier ?? "Unknown") - \(Int(object.confidence * 100))%",
                                verboseOnly: true
                            )
                        }
                    }
                    
                    self.lastDetectionCount = currentDetectionCount
                    self.lastDetectionState = currentDetectionState
                }
                
                continuation.resume(returning: filteredObjects)
            }
            
            // Configure request for optimal object detection
            request.imageCropAndScaleOption = .scaleFit // Better for object detection than scaleFill
            
            // Set the image orientation correctly for camera input based on device orientation
            let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: orientation, options: [:])
            
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    try handler.perform([request])
                } catch {
                    AppLog.error(.camera, "YOLOv3 request handler failed: \(error)")
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    /// Legacy method for backward compatibility
    /// - Parameter pixelBuffer: The pixel buffer containing the image data
    /// - Returns: Array of detected objects with their bounding boxes and confidence scores
    func detectObjects(from pixelBuffer: CVPixelBuffer) async throws -> [VNRecognizedObjectObservation] {
        return try await detectObjects(from: pixelBuffer, orientation: .right)
    }
}
