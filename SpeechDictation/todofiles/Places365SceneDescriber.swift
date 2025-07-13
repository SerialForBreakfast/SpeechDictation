import Foundation
import CoreML
import Vision

/// A scene classification implementation using Vision framework's built-in scene classifier
/// This provides real scene analysis instead of placeholder random descriptions
@available(iOS 15.0, *)
final class Places365SceneDescriber: SceneDescribingModel {
    
    /// Initialize the Places365SceneDescriber
    /// Uses Vision framework's built-in scene classification capabilities
    init() {
        // Using Vision framework's built-in scene classification
    }
    
    /// Performs real scene classification on a pixel buffer using Vision framework
    /// - Parameter pixelBuffer: The input image as a CVPixelBuffer
    /// - Returns: A string label describing the scene based on actual image analysis
    /// - Throws: Vision framework errors if classification fails
    /// - Note: This implementation uses Vision's VNClassifyImageRequest for real scene analysis
    func classifyScene(from pixelBuffer: CVPixelBuffer) async throws -> String {
        return try await withCheckedThrowingContinuation { continuation in
            let request = VNClassifyImageRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let observations = request.results as? [VNClassificationObservation] else {
                    continuation.resume(returning: "Unknown Scene")
                    return
                }
                
                // Filter for high-confidence classifications (>30%) and get the top result
                let highConfidenceObservations = observations.filter { $0.confidence > 0.3 }
                
                if let topObservation = highConfidenceObservations.first {
                    // Clean up the identifier to make it more readable
                    let cleanedIdentifier = self.cleanSceneIdentifier(topObservation.identifier)
                    let confidencePercent = Int(topObservation.confidence * 100)
                    continuation.resume(returning: "\(cleanedIdentifier) (\(confidencePercent)%)")
                } else if let fallbackObservation = observations.first {
                    // Use lower confidence result as fallback
                    let cleanedIdentifier = self.cleanSceneIdentifier(fallbackObservation.identifier)
                    let confidencePercent = Int(fallbackObservation.confidence * 100)
                    continuation.resume(returning: "\(cleanedIdentifier) (\(confidencePercent)%)")
                } else {
                    continuation.resume(returning: "Unknown Scene")
                }
            }
            
            // Configure request for better scene classification
            request.revision = VNClassifyImageRequestRevision1
            
            // Set the image orientation correctly for camera input (portrait mode)
            let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .right)
            
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
    
    /// Cleans up scene identifiers to make them more human-readable
    /// - Parameter identifier: Raw identifier from Vision framework
    /// - Returns: Cleaned, human-readable scene description
    private func cleanSceneIdentifier(_ identifier: String) -> String {
        // Remove technical prefixes and clean up common scene identifiers
        var cleaned = identifier
            .replacingOccurrences(of: "_", with: " ")
            .replacingOccurrences(of: "-", with: " ")
            .capitalized
        
        // Handle common Vision framework scene classifications
        if cleaned.lowercased().contains("indoor") {
            cleaned = cleaned.replacingOccurrences(of: "Indoor", with: "Indoor:")
        }
        if cleaned.lowercased().contains("outdoor") {
            cleaned = cleaned.replacingOccurrences(of: "Outdoor", with: "Outdoor:")
        }
        
        return cleaned
    }
}
