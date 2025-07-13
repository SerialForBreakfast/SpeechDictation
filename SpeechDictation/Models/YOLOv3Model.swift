import Foundation
import Vision
import CoreML

/// A concrete implementation of `ObjectDetectionModel` using the YOLOv3Tiny CoreML model.
/// This class handles object detection using the YOLOv3Tiny model with proper concurrency management.
@available(iOS 15.0, *)
final class YOLOv3Model: ObjectDetectionModel {
    private let model: VNCoreMLModel
    
    /// Initialize the YOLOv3Model with the YOLOv3Tiny CoreML model
    /// - Note: This initializer is failable and returns nil if the model cannot be loaded
    init?() {
        do {
            let config = MLModelConfiguration()
            config.computeUnits = .all // Use both CPU and GPU for better performance
            let mlModel = try YOLOv3Tiny(configuration: config)
            self.model = try VNCoreMLModel(for: mlModel.model)
            
            print("✅ YOLOv3Model successfully initialized")
        } catch {
            print("❌ Failed to initialize YOLOv3Model: \(error)")
            return nil
        }
    }
    
    /// Performs object detection on a pixel buffer asynchronously
    /// - Parameter pixelBuffer: The input image as a CVPixelBuffer
    /// - Returns: An array of VNRecognizedObjectObservation representing detected objects
    /// - Throws: Vision framework errors if detection fails
    /// - Note: This method runs on a background queue to avoid blocking the main thread
    func detectObjects(from pixelBuffer: CVPixelBuffer) async throws -> [VNRecognizedObjectObservation] {
        return try await withCheckedThrowingContinuation { continuation in
            let request = VNCoreMLRequest(model: model) { request, error in
                if let error = error {
                    print("❌ YOLOv3 detection error: \(error)")
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let results = request.results as? [VNRecognizedObjectObservation] else {
                    print("⚠️ YOLOv3 returned no valid results")
                    continuation.resume(returning: [])
                    return
                }
                
                // Filter results by confidence threshold (25% minimum)
                let confidenceThreshold: Float = 0.25
                let filteredResults = results.filter { observation in
                    guard let topLabel = observation.labels.first else { return false }
                    return topLabel.confidence >= confidenceThreshold
                }
                
                print("🔍 YOLOv3 detected \(results.count) total objects, \(filteredResults.count) above \(Int(confidenceThreshold * 100))% confidence")
                
                // Debug: Print detected objects
                for (index, observation) in filteredResults.prefix(5).enumerated() {
                    if let topLabel = observation.labels.first {
                        print("   Object \(index + 1): \(topLabel.identifier) (\(Int(topLabel.confidence * 100))%)")
                    }
                }
                
                continuation.resume(returning: filteredResults)
            }
            
            // Configure request for optimal object detection
            request.imageCropAndScaleOption = .scaleFit // Better for object detection than scaleFill
            
            // Set the image orientation correctly for camera input (portrait mode)
            let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .right, options: [:])
            
            do {
                try handler.perform([request])
            } catch {
                print("❌ YOLOv3 request execution failed: \(error)")
                continuation.resume(throwing: error)
            }
        }
    }
}
