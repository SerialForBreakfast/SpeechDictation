import Foundation
import Vision
import CoreML
import ImageIO

/// An enhanced scene describer implementation with temporal analysis and improved accuracy
/// Features confidence tracking, scene transition detection, and multi-result analysis
final class Places365SceneDescriber: SceneDescribingModel {
    
    // MARK: - Temporal Analysis Properties
    private var previousScenes: [String] = []
    private var sceneConfidences: [Float] = []
    private var sceneTimestamps: [Date] = []
    private let maxHistorySize = 10
    private let stabilityThreshold: Float = 0.6
    private let transitionThreshold: Float = 0.4
    
    // MARK: - Scene Categories
    private let sceneCategories = [
        "indoor": ["living_room", "kitchen", "bedroom", "bathroom", "office", "restaurant", "classroom"],
        "outdoor": ["street", "park", "garden", "beach", "mountain", "forest", "parking_lot"],
        "transportation": ["car", "bus", "train", "airplane", "subway"],
        "commercial": ["store", "mall", "market", "bank", "hospital"]
    ]
    
    init() {
        // Initialize temporal analysis arrays
        previousScenes.reserveCapacity(maxHistorySize)
        sceneConfidences.reserveCapacity(maxHistorySize)
        sceneTimestamps.reserveCapacity(maxHistorySize)
    }
    
    /// Performs enhanced scene classification with temporal analysis and confidence tracking
    /// - Parameters:
    ///   - pixelBuffer: The input image as a CVPixelBuffer
    ///   - orientation: The image orientation for proper coordinate transformation
    /// - Returns: A string label describing the scene with enhanced accuracy
    /// - Throws: Vision framework errors if classification fails
    /// - Note: Uses temporal analysis to reduce flickering and improve stability
    func classifyScene(from pixelBuffer: CVPixelBuffer, orientation: CGImagePropertyOrientation = .right) async throws -> String {
        return try await withCheckedThrowingContinuation { continuation in
            let request = VNClassifyImageRequest { request, error in
                if let error = error {
                    print("🚨 Enhanced scene classification error: \(error)")
                    continuation.resume(throwing: error)
                    return
                }
                
                // Get multiple classification results for better analysis
                guard let results = request.results as? [VNClassificationObservation],
                      !results.isEmpty else {
                    print("⚠️ No scene classification results found")
                    continuation.resume(returning: self.getStableScene() ?? "Unknown Scene")
                    return
                }
                
                // Process top results for enhanced analysis
                let topResults = Array(results.prefix(5))
                let currentScene = self.analyzeSceneResults(topResults)
                
                // Update temporal analysis
                self.updateSceneHistory(currentScene.scene, confidence: currentScene.confidence)
                
                // Get stabilized scene result
                let finalScene = self.getStabilizedScene(currentScene)
                
                print("🎯 Enhanced scene detected: \(finalScene) (confidence: \(Int(currentScene.confidence * 100))%)")
                
                continuation.resume(returning: finalScene)
            }
            
            // Configure request for better scene classification
            request.revision = VNClassifyImageRequestRevision1
            
            // Set the image orientation correctly for camera input
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
    
    // MARK: - Enhanced Scene Analysis Methods
    
    /// Analyzes multiple scene results to determine the best scene classification
    /// - Parameter results: Array of VNClassificationObservation results
    /// - Returns: A tuple containing the scene name and confidence
    private func analyzeSceneResults(_ results: [VNClassificationObservation]) -> (scene: String, confidence: Float) {
        guard let topResult = results.first else {
            return ("Unknown Scene", 0.0)
        }
        
        // Clean up the primary result
        let cleanedScene = cleanSceneIdentifier(topResult.identifier)
        
        // Check for contextual improvements using multiple results
        let contextualScene = enhanceSceneWithContext(cleanedScene, results: results)
        
        // Apply scene categorization
        let categorizedScene = categorizeScene(contextualScene)
        
        return (categorizedScene, topResult.confidence)
    }
    
    /// Enhances scene detection with contextual analysis from multiple results
    /// - Parameters:
    ///   - primaryScene: The primary scene classification
    ///   - results: All classification results for context
    /// - Returns: Enhanced scene description with context
    private func enhanceSceneWithContext(_ primaryScene: String, results: [VNClassificationObservation]) -> String {
        // Look for supporting evidence in other results
        let supportingScenes = results.dropFirst().compactMap { result in
            cleanSceneIdentifier(result.identifier)
        }
        
        // Check for common patterns or related scenes
        if supportingScenes.contains(where: { $0.contains("kitchen") || $0.contains("dining") }) &&
           primaryScene.contains("room") {
            return "Kitchen/Dining Area"
        }
        
        if supportingScenes.contains(where: { $0.contains("outdoor") || $0.contains("street") }) &&
           primaryScene.contains("building") {
            return "Outdoor Building/Street"
        }
        
        // Return original if no contextual enhancement found
        return primaryScene
    }
    
    /// Categorizes scenes into broader categories for better understanding
    /// - Parameter scene: The scene to categorize
    /// - Returns: Categorized scene description
    private func categorizeScene(_ scene: String) -> String {
        let lowerScene = scene.lowercased()
        
        for (category, keywords) in sceneCategories {
            if keywords.contains(where: { lowerScene.contains($0) }) {
                return "\(scene) (\(category.capitalized))"
            }
        }
        
        return scene
    }
    
    /// Updates the scene history for temporal analysis
    /// - Parameters:
    ///   - scene: The detected scene
    ///   - confidence: The confidence of the detection
    private func updateSceneHistory(_ scene: String, confidence: Float) {
        let currentTime = Date()
        
        // Add to history
        previousScenes.append(scene)
        sceneConfidences.append(confidence)
        sceneTimestamps.append(currentTime)
        
        // Maintain maximum history size
        if previousScenes.count > maxHistorySize {
            previousScenes.removeFirst()
            sceneConfidences.removeFirst()
            sceneTimestamps.removeFirst()
        }
    }
    
    /// Gets a stabilized scene result using temporal analysis
    /// - Parameter currentScene: The current scene detection result
    /// - Returns: Stabilized scene description
    private func getStabilizedScene(_ currentScene: (scene: String, confidence: Float)) -> String {
        // If we don't have enough history, return current scene
        guard previousScenes.count >= 3 else {
            return currentScene.scene
        }
        
        // Check for scene stability (same scene detected multiple times)
        let recentScenes = Array(previousScenes.suffix(5))
        let currentSceneCount = recentScenes.filter { $0 == currentScene.scene }.count
        
        // If current scene is stable and confident, use it
        if currentSceneCount >= 3 && currentScene.confidence >= stabilityThreshold {
            return currentScene.scene
        }
        
        // Check for consistent alternative scene
        let sceneCounts = Dictionary(grouping: recentScenes, by: { $0 }).mapValues { $0.count }
        if let mostCommonScene = sceneCounts.max(by: { $0.value < $1.value }),
           mostCommonScene.value >= 3 {
            return mostCommonScene.key
        }
        
        // Fall back to current scene
        return currentScene.scene
    }
    
    /// Gets the most stable scene from history when current detection fails
    /// - Returns: The most stable scene from recent history
    private func getStableScene() -> String? {
        guard !previousScenes.isEmpty else { return nil }
        
        // Return the most recent scene with high confidence
        let recentIndices = max(0, previousScenes.count - 3)..<previousScenes.count
        
        for i in recentIndices.reversed() {
            if sceneConfidences[i] >= stabilityThreshold {
                return previousScenes[i]
            }
        }
        
        // Fall back to most recent scene
        return previousScenes.last
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
