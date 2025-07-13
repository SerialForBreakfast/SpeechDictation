
import Foundation
import Vision
import CoreML
import ImageIO

/// A protocol defining a model capable of describing scenes from CVPixelBuffer input.
/// Implementations should handle ML model loading and inference asynchronously.
protocol SceneDescribingModel {
    /// Performs scene classification on a pixel buffer and returns a label string asynchronously.
    /// - Parameters:
    ///   - pixelBuffer: The input image as a CVPixelBuffer.
    ///   - orientation: The image orientation for proper coordinate transformation.
    /// - Returns: A string label describing the scene (e.g., "Indoor", "Beach").
    /// - Throws: Vision framework errors if classification fails.
    /// - Note: This method should be implemented asynchronously to avoid blocking the main thread.
    func classifyScene(from pixelBuffer: CVPixelBuffer, orientation: CGImagePropertyOrientation) async throws -> String
    
    /// Legacy method for backward compatibility
    /// - Parameter pixelBuffer: The input image as a CVPixelBuffer.
    /// - Returns: A string label describing the scene based on actual image analysis.
    func classifyScene(from pixelBuffer: CVPixelBuffer) async throws -> String
}
