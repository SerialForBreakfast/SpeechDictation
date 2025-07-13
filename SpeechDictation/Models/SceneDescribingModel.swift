
import Foundation
import Vision
import CoreML

/// A protocol defining a model capable of describing scenes from CVPixelBuffer input.
/// Implementations should handle ML model loading and inference asynchronously.
protocol SceneDescribingModel {
    /// Performs scene classification on a pixel buffer and returns a label string asynchronously.
    /// - Parameter pixelBuffer: The input image as a CVPixelBuffer.
    /// - Returns: A string label describing the scene (e.g., "Indoor", "Beach").
    /// - Throws: Vision framework errors if classification fails.
    /// - Note: This method should be implemented asynchronously to avoid blocking the main thread.
    func classifyScene(from pixelBuffer: CVPixelBuffer) async throws -> String
}
