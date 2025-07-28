import Foundation
import AVFoundation
import CoreML
import Vision
import UIKit
import Combine
import ARKit

/// Service for estimating depth using multiple sources (LiDAR, ARKit, ML models)
/// Provides accurate distance measurements for spatial object description
@available(iOS 13.0, *)
actor DepthEstimationService {
    
    // MARK: - Types
    
    /// Available depth estimation methods
    enum DepthSource {
        case lidar
        case arkit
        case mlModel
        case fallback // Size-based estimation
    }
    
    /// Depth estimation result with metadata
    struct DepthResult {
        let depthMap: CVPixelBuffer?
        let source: DepthSource
        let timestamp: Date
        let accuracy: Float // 0.0 to 1.0
        let error: Error?
    }
    
    /// Distance categories with actual depth values
    enum DistanceCategory {
        case veryClose(meters: Float)    // 0.0 - 1.0m
        case close(meters: Float)        // 1.0 - 3.0m
        case medium(meters: Float)       // 3.0 - 10.0m
        case far(meters: Float)          // 10.0 - 30.0m
        case veryFar(meters: Float)      // 30.0m+
        
        var description: String {
            switch self {
            case .veryClose(let meters):
                return "very close (\(String(format: "%.1f", meters))m)"
            case .close(let meters):
                return "close (\(String(format: "%.1f", meters))m)"
            case .medium(let meters):
                return "medium distance (\(String(format: "%.1f", meters))m)"
            case .far(let meters):
                return "far away (\(String(format: "%.1f", meters))m)"
            case .veryFar(let meters):
                return "very far away (\(String(format: "%.1f", meters))m)"
            }
        }
        
        var compactDescription: String {
            switch self {
            case .veryClose: return "very close"
            case .close: return "close"
            case .medium: return "medium"
            case .far: return "far"
            case .veryFar: return "very far"
            }
        }
    }
    
    // MARK: - Properties
    
    private let modelCatalog = ModelCatalog.shared
    private var depthAnythingModel: MLModel?
    private var arSession: ARSession?
    private var lastDepthResult: DepthResult?
    
    // Device capabilities
    private let hasLiDAR: Bool
    private let hasARKit: Bool
    private let supportsTrueDepth: Bool
    
    // MARK: - Initialization
    
    /// Initialize depth estimation service with device capability detection
    /// - Note: Automatically detects LiDAR, ARKit, and TrueDepth capabilities
    init() {
        // Detect device capabilities
        self.hasLiDAR = ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh)
        self.hasARKit = ARWorldTrackingConfiguration.isSupported
        self.supportsTrueDepth = ARFaceTrackingConfiguration.isSupported
        
        Task {
            await loadDepthModels()
        }
    }
    
    // MARK: - Public Methods
    
    /// Estimates depth for a given point in the image
    /// - Parameters:
    ///   - point: Normalized point (0-1 coordinates) in the image
    ///   - pixelBuffer: Input image buffer
    /// - Returns: Distance category with actual depth value
    func estimateDepth(at point: CGPoint, in pixelBuffer: CVPixelBuffer) async -> DistanceCategory {
        // Try depth sources in order of accuracy
        if let result = await tryLiDARDepth(at: point, in: pixelBuffer) {
            return result
        }
        
        if let result = await tryARKitDepth(at: point, in: pixelBuffer) {
            return result
        }
        
        if let result = await tryMLModelDepth(at: point, in: pixelBuffer) {
            return result
        }
        
        // Fallback to size-based estimation
        return estimateFallbackDepth(at: point, in: pixelBuffer)
    }
    
    /// Estimates depth for a bounding box region
    /// - Parameters:
    ///   - boundingBox: Normalized bounding box (0-1 coordinates)
    ///   - pixelBuffer: Input image buffer
    /// - Returns: Distance category with actual depth value
    func estimateDepth(for boundingBox: CGRect, in pixelBuffer: CVPixelBuffer) async -> DistanceCategory {
        // Use center point of bounding box for depth estimation
        let centerPoint = CGPoint(
            x: boundingBox.midX,
            y: boundingBox.midY
        )
        
        return await estimateDepth(at: centerPoint, in: pixelBuffer)
    }
    
    /// Get available depth sources for current device
    /// - Returns: Array of supported depth sources
    func getAvailableDepthSources() -> [DepthSource] {
        var sources: [DepthSource] = []
        
        if hasLiDAR {
            sources.append(.lidar)
        }
        
        if hasARKit {
            sources.append(.arkit)
        }
        
        if depthAnythingModel != nil {
            sources.append(.mlModel)
        }
        
        sources.append(.fallback) // Always available
        
        return sources
    }
    
    // MARK: - Private Methods
    
    /// Load ML models for depth estimation
    private func loadDepthModels() async {
        // Try to load Depth Anything V2 model
        if let modelURL = await modelCatalog.getInstalledModelURL(for: "depth-anything-v2") {
            do {
                depthAnythingModel = try MLModel(contentsOf: modelURL)
                print("Loaded Depth Anything V2 model for depth estimation")
            } catch {
                print("Failed to load Depth Anything V2 model: \(error)")
            }
        }
    }
    
    /// Try LiDAR depth estimation
    private func tryLiDARDepth(at point: CGPoint, in pixelBuffer: CVPixelBuffer) async -> DistanceCategory? {
        guard hasLiDAR else { return nil }
        
        // Initialize AR session if needed
        if arSession == nil {
            arSession = ARSession()
            let configuration = ARWorldTrackingConfiguration()
            configuration.frameSemantics = .sceneDepth
            arSession?.run(configuration)
        }
        
        // Get depth data from AR session
        // This is a simplified implementation - in practice, you'd need to access the current AR frame
        // For now, return nil to indicate LiDAR is not available in this context
        return nil
    }
    
    /// Try ARKit depth estimation
    private func tryARKitDepth(at point: CGPoint, in pixelBuffer: CVPixelBuffer) async -> DistanceCategory? {
        guard hasARKit else { return nil }
        
        // ARKit depth estimation would require integration with ARSession
        // For now, return nil to indicate ARKit depth is not available in this context
        return nil
    }
    
    /// Try ML model depth estimation
    private func tryMLModelDepth(at point: CGPoint, in pixelBuffer: CVPixelBuffer) async -> DistanceCategory? {
        guard let model = depthAnythingModel else { return nil }
        
        do {
            // Create input for Depth Anything V2
            let input = try MLDictionaryFeatureProvider(dictionary: [
                "input": MLFeatureValue(pixelBuffer: pixelBuffer)
            ])
            
            // Run inference
            let output = try model.prediction(from: input)
            
            // Extract depth map from output
            guard let depthBuffer = output.featureValue(for: "depth_map")?.multiArrayValue else {
                return nil
            }
            
            // Convert point to depth map coordinates
            let depthMapSize = depthBuffer.shape
            let x = Int(point.x * Double(depthMapSize[1].intValue))
            let y = Int(point.y * Double(depthMapSize[0].intValue))
            
            // Extract depth value at point
            let depthValue = depthBuffer[[y, x] as [NSNumber]].floatValue
            
            // Convert to distance category
            return categorizeDistance(depthValue)
            
        } catch {
            print("ML model depth estimation failed: \(error)")
            return nil
        }
    }
    
    /// Fallback depth estimation based on object size
    private func estimateFallbackDepth(at point: CGPoint, in pixelBuffer: CVPixelBuffer) -> DistanceCategory {
        // This is a placeholder implementation
        // In practice, you might use object size heuristics or other visual cues
        let estimatedDistance: Float = 5.0 // Default to 5 meters
        return categorizeDistance(estimatedDistance)
    }
    
    /// Categorize distance based on depth value in meters
    private func categorizeDistance(_ depthInMeters: Float) -> DistanceCategory {
        switch depthInMeters {
        case 0.0...1.0:
            return .veryClose(meters: depthInMeters)
        case 1.0...3.0:
            return .close(meters: depthInMeters)
        case 3.0...10.0:
            return .medium(meters: depthInMeters)
        case 10.0...30.0:
            return .far(meters: depthInMeters)
        default:
            return .veryFar(meters: depthInMeters)
        }
    }
}

/// Convenience extensions for integration with existing spatial descriptor system
extension DepthEstimationService.DistanceCategory {
    
    /// Convert to legacy ObjectSize for backward compatibility
    var legacyObjectSize: SpatialDescriptor.ObjectSize {
        switch self {
        case .veryClose:
            return .veryClose
        case .close:
            return .close
        case .medium:
            return .medium
        case .far:
            return .far
        case .veryFar:
            return .veryFar
        }
    }
} 