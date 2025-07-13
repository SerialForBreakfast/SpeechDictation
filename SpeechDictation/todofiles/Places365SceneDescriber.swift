import Foundation
import Vision
import CoreML
import ImageIO

/// A real scene describer implementation using Vision framework's built-in scene classification
/// Replaces the previous placeholder implementation that returned random descriptions
final class Places365SceneDescriber: SceneDescribingModel {
    init() {
        // No initialization needed - using Vision framework's built-in scene classification
    }
    
    /// Performs real scene classification on a pixel buffer using Vision framework
    /// - Parameters:
    ///   - pixelBuffer: The input image as a CVPixelBuffer
    ///   - orientation: The image orientation for proper coordinate transformation
    /// - Returns: A string label describing the scene based on actual image analysis
    /// - Throws: Vision framework errors if classification fails
    /// - Note: This implementation uses Vision's VNClassifyImageRequest for real scene analysis
    func classifyScene(from pixelBuffer: CVPixelBuffer, orientation: CGImagePropertyOrientation = .right) async throws -> String {
        return try await withCheckedThrowingContinuation { continuation in
            let request = VNClassifyImageRequest { request, error in
                if let error = error {
                    print("🚨 Scene classification error: \(error)")
                    continuation.resume(throwing: error)
                    return
                }
                
                // Get the most confident scene classification
                guard let results = request.results as? [VNClassificationObservation],
                      let topResult = results.first else {
                    print("⚠️ No scene classification results found")
                    continuation.resume(returning: "Unknown Scene")
                    return
                }
                
                // Clean up the identifier for better readability
                let cleanedIdentifier = self.cleanSceneIdentifier(topResult.identifier)
                let confidencePercentage = Int(topResult.confidence * 100)
                
                print("🎯 Scene detected: \(cleanedIdentifier) (\(confidencePercentage)% confidence)")
                
                // Return the cleaned scene description
                continuation.resume(returning: cleanedIdentifier)
            }
            
            // Configure request for better scene classification
            request.revision = VNClassifyImageRequestRevision1
            
            // Set the image orientation correctly for camera input based on device orientation
            let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: orientation)
            
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
    
    /// Legacy method for backward compatibility
    /// - Parameter pixelBuffer: The input image as a CVPixelBuffer
    /// - Returns: A string label describing the scene based on actual image analysis
    func classifyScene(from pixelBuffer: CVPixelBuffer) async throws -> String {
        return try await classifyScene(from: pixelBuffer, orientation: .right)
    }
    
    /// Cleans up scene identifiers to make them more human-readable
    /// - Parameter identifier: Raw identifier from Vision framework
    /// - Returns: Cleaned, human-readable description
    private func cleanSceneIdentifier(_ identifier: String) -> String {
        // Remove prefixes like "n02" or similar scientific notation
        let cleanedBase = identifier.replacingOccurrences(of: "^n?\\d+_?", with: "", options: .regularExpression)
        
        // Replace underscores with spaces and capitalize appropriately
        let withSpaces = cleanedBase.replacingOccurrences(of: "_", with: " ")
        
        // Capitalize the first letter of each word
        let components = withSpaces.components(separatedBy: " ")
        let capitalizedComponents = components.map { component in
            guard !component.isEmpty else { return component }
            return component.prefix(1).uppercased() + component.dropFirst().lowercased()
        }
        
        return capitalizedComponents.joined(separator: " ")
    }
}
