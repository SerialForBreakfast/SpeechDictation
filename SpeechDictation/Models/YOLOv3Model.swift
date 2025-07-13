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
            let mlModel = try YOLOv3Tiny(configuration: config)
            self.model = try VNCoreMLModel(for: mlModel.model)
        } catch {
            print("Failed to initialize YOLOv3Model: \(error)")
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
                    continuation.resume(throwing: error)
                    return
                }
                
                let results = request.results as? [VNRecognizedObjectObservation] ?? []
                continuation.resume(returning: results)
            }
            
            request.imageCropAndScaleOption = .scaleFill
            let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .up)
            
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
}
