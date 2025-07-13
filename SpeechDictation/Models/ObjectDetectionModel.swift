
import Foundation
import Vision
import CoreML

/// A protocol defining a model capable of detecting objects from CVPixelBuffer input.
/// Implementations should handle ML model loading and inference asynchronously.
protocol ObjectDetectionModel {
    /// Performs object detection on a pixel buffer and returns recognized object observations.
    /// - Parameter pixelBuffer: The input image as a CVPixelBuffer.
    /// - Returns: An array of VNRecognizedObjectObservation representing detected objects.
    /// - Throws: Vision framework errors if detection fails.
    /// - Note: This method should be implemented asynchronously to avoid blocking the main thread.
    func detectObjects(from pixelBuffer: CVPixelBuffer) async throws -> [VNRecognizedObjectObservation]
}
