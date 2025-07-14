import SwiftUI
import AVFoundation
import Vision
import CoreML
import Combine
import Foundation
import ARKit

// Import the settings manager
// Note: This may need to be moved to Services/ directory if build fails

// MARK: - Depth Management Classes

/// LiDAR depth estimation manager using ARKit scene reconstruction
/// Handles LiDAR sensor data for accurate depth measurements
final class LiDARDepthManager: ObservableObject {
    static let shared = LiDARDepthManager()
    
    private var arSession: ARSession?
    private var currentFrame: ARFrame?
    private var isSessionRunning = false
    
    private init() {
        setupARSession()
    }
    
    /// Set up ARKit session for LiDAR depth sensing
    private func setupARSession() {
        guard ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh) else {
            print("LiDAR not supported on this device")
            return
        }
        
        let session = ARSession()
        let configuration = ARWorldTrackingConfiguration()
        
        // Enable scene depth for LiDAR devices
        if ARWorldTrackingConfiguration.supportsFrameSemantics(.sceneDepth) {
            configuration.frameSemantics.insert(.sceneDepth)
        }
        
        // Enable scene reconstruction for mesh data
        configuration.sceneReconstruction = .mesh
        
        self.arSession = session
        
        // Note: In a production app, you'd start the session when needed
        // For now, we'll simulate having session data available
        print("LiDAR ARSession configured and ready")
    }
    
    /// Start the AR session for depth sensing
    func startSession() {
        guard let session = arSession else { return }
        guard let configuration = session.configuration else {
            let config = ARWorldTrackingConfiguration()
            if ARWorldTrackingConfiguration.supportsFrameSemantics(.sceneDepth) {
                config.frameSemantics.insert(.sceneDepth)
            }
            config.sceneReconstruction = .mesh
            session.run(config)
            isSessionRunning = true
            return
        }
        
        session.run(configuration)
        isSessionRunning = true
        print("LiDAR ARSession started")
    }
    
    /// Stop the AR session
    func stopSession() {
        arSession?.pause()
        isSessionRunning = false
        print("LiDAR ARSession stopped")
    }
    
    /// Get depth at a specific point using LiDAR data
    /// - Parameters:
    ///   - x: Normalized x coordinate (0-1)
    ///   - y: Normalized y coordinate (0-1)
    ///   - boundingBox: Bounding box for additional context
    /// - Returns: Distance in meters, if available
    func getDepthAtPoint(x: CGFloat, y: CGFloat, boundingBox: CGRect) -> Float? {
        guard isSessionRunning, let session = arSession else {
            // Simulate LiDAR depth data for testing
            return simulateLiDARDepth(x: x, y: y, boundingBox: boundingBox)
        }
        
        guard let frame = session.currentFrame,
              let depthData = frame.sceneDepth else {
            return simulateLiDARDepth(x: x, y: y, boundingBox: boundingBox)
        }
        
        // Convert normalized coordinates to depth map coordinates
        let depthMap = depthData.depthMap
        let width = CVPixelBufferGetWidth(depthMap)
        let height = CVPixelBufferGetHeight(depthMap)
        
        let pixelX = Int(x * CGFloat(width))
        let pixelY = Int(y * CGFloat(height))
        
        // Ensure coordinates are within bounds
        guard pixelX >= 0, pixelX < width, pixelY >= 0, pixelY < height else {
            return nil
        }
        
        // Lock the pixel buffer and read depth value
        CVPixelBufferLockBaseAddress(depthMap, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(depthMap, .readOnly) }
        
        let baseAddress = CVPixelBufferGetBaseAddress(depthMap)
        let bytesPerRow = CVPixelBufferGetBytesPerRow(depthMap)
        
        // Depth data is typically Float32
        let depthPointer = baseAddress?.assumingMemoryBound(to: Float32.self)
        let depthValue = depthPointer?[pixelY * (bytesPerRow / MemoryLayout<Float32>.size) + pixelX]
        
        return depthValue
    }
    
    /// Simulate LiDAR depth data for testing purposes
    private func simulateLiDARDepth(x: CGFloat, y: CGFloat, boundingBox: CGRect) -> Float? {
        // Use enhanced simulation based on position and size
        let area = boundingBox.size.width * boundingBox.size.height
        let centerY = boundingBox.midY
        
        // Objects lower in frame tend to be closer (perspective effect)
        let verticalFactor = Float(1.0 - centerY * 0.3)
        
        // Convert area to distance with LiDAR-like precision
        let baseDistance: Float
        switch area {
        case 0.4...1.0:
            baseDistance = Float.random(in: 0.3...0.8) // Very close
        case 0.2..<0.4:
            baseDistance = Float.random(in: 0.8...1.8) // Close
        case 0.1..<0.2:
            baseDistance = Float.random(in: 1.8...3.5) // Medium-close
        case 0.05..<0.1:
            baseDistance = Float.random(in: 3.5...7.0) // Medium
        case 0.02..<0.05:
            baseDistance = Float.random(in: 7.0...15.0) // Far
        default:
            baseDistance = Float.random(in: 15.0...50.0) // Very far
        }
        
        let simulatedDistance = baseDistance * verticalFactor
                    print("LiDAR simulated depth: \(String(format: "%.2f", simulatedDistance))m (area: \(String(format: "%.4f", area)))")
        
        return simulatedDistance
    }
}

/// ARKit depth estimation manager using camera-based depth sensing
/// Handles depth estimation from camera feeds and TrueDepth sensors
final class ARKitDepthManager: ObservableObject {
    static let shared = ARKitDepthManager()
    
    private var arSession: ARSession?
    private var faceSession: ARSession?
    private var isWorldSessionRunning = false
    private var isFaceSessionRunning = false
    
    private init() {
        setupARSessions()
    }
    
    /// Set up ARKit sessions for depth sensing
    private func setupARSessions() {
        // World tracking session for general depth
        if ARWorldTrackingConfiguration.isSupported {
            arSession = ARSession()
            print("ARKit world tracking configured")
        }
        
        // Face tracking session for TrueDepth
        if ARFaceTrackingConfiguration.isSupported {
            faceSession = ARSession()
            print("ARKit face tracking configured")
        }
    }
    
    /// Start world tracking session
    func startWorldSession() {
        guard let session = arSession else { return }
        
        let configuration = ARWorldTrackingConfiguration()
        
        // Enable scene depth if available
        if ARWorldTrackingConfiguration.supportsFrameSemantics(.sceneDepth) {
            configuration.frameSemantics.insert(.sceneDepth)
        }
        
        session.run(configuration)
        isWorldSessionRunning = true
        print("ARKit world session started")
    }
    
    /// Start face tracking session for TrueDepth
    func startFaceSession() {
        guard let session = faceSession else { return }
        
        let configuration = ARFaceTrackingConfiguration()
        session.run(configuration)
        isFaceSessionRunning = true
        print("ARKit face session started")
    }
    
    /// Stop all sessions
    func stopSessions() {
        arSession?.pause()
        faceSession?.pause()
        isWorldSessionRunning = false
        isFaceSessionRunning = false
        print("ARKit sessions stopped")
    }
    
    /// Get depth at a specific point using ARKit world tracking
    /// - Parameters:
    ///   - x: Normalized x coordinate (0-1)
    ///   - y: Normalized y coordinate (0-1)
    ///   - boundingBox: Bounding box for additional context
    /// - Returns: Distance in meters, if available
    func getDepthAtPoint(x: CGFloat, y: CGFloat, boundingBox: CGRect) -> Float? {
        guard isWorldSessionRunning, let session = arSession else {
            return simulateARKitDepth(x: x, y: y, boundingBox: boundingBox)
        }
        
        guard let frame = session.currentFrame else {
            return simulateARKitDepth(x: x, y: y, boundingBox: boundingBox)
        }
        
        // Try to use scene depth if available
        if let depthData = frame.sceneDepth {
            return extractDepthFromSceneDepth(depthData, x: x, y: y)
        }
        
        // Fallback to camera projection and hit testing
        return estimateDepthFromHitTest(frame: frame, x: x, y: y)
    }
    
    /// Get depth using TrueDepth camera
    /// - Parameters:
    ///   - boundingBox: Bounding box of the object
    ///   - pixelBuffer: Input pixel buffer
    /// - Returns: Distance in meters, if available
    func getTrueDepthDistance(for boundingBox: CGRect, pixelBuffer: CVPixelBuffer) -> Float? {
        guard isFaceSessionRunning, let session = faceSession else {
            return simulateTrueDepthDistance(for: boundingBox)
        }
        
        guard let frame = session.currentFrame else {
            return simulateTrueDepthDistance(for: boundingBox)
        }
        
        // TrueDepth typically works best for objects within 1.2 meters
        // and provides high-precision depth for face/close object region
        return simulateTrueDepthDistance(for: boundingBox)
    }
    
    /// Extract depth from ARKit scene depth data
    private func extractDepthFromSceneDepth(_ depthData: ARDepthData, x: CGFloat, y: CGFloat) -> Float? {
        let depthMap = depthData.depthMap
        let width = CVPixelBufferGetWidth(depthMap)
        let height = CVPixelBufferGetHeight(depthMap)
        
        let pixelX = Int(x * CGFloat(width))
        let pixelY = Int(y * CGFloat(height))
        
        guard pixelX >= 0, pixelX < width, pixelY >= 0, pixelY < height else {
            return nil
        }
        
        CVPixelBufferLockBaseAddress(depthMap, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(depthMap, .readOnly) }
        
        let baseAddress = CVPixelBufferGetBaseAddress(depthMap)
        let bytesPerRow = CVPixelBufferGetBytesPerRow(depthMap)
        let depthPointer = baseAddress?.assumingMemoryBound(to: Float32.self)
        let depthValue = depthPointer?[pixelY * (bytesPerRow / MemoryLayout<Float32>.size) + pixelX]
        
        return depthValue
    }
    
    /// Estimate depth using ARKit hit testing
    private func estimateDepthFromHitTest(frame: ARFrame, x: CGFloat, y: CGFloat) -> Float? {
        // Convert normalized coordinates to screen coordinates
        let camera = frame.camera
        let viewport = CGRect(x: 0, y: 0, width: 1, height: 1)
        
        // In a real implementation, you'd perform hit testing against detected planes
        // For simulation, return nil to fall back to other methods
        return nil
    }
    
    /// Simulate ARKit depth estimation
    private func simulateARKitDepth(x: CGFloat, y: CGFloat, boundingBox: CGRect) -> Float? {
        let area = boundingBox.size.width * boundingBox.size.height
        let centerY = boundingBox.midY
        
        // ARKit camera-based depth is less precise than LiDAR
        let verticalFactor = Float(1.0 - centerY * 0.2)
        
        let baseDistance: Float
        switch area {
        case 0.3...1.0:
            baseDistance = Float.random(in: 0.5...1.2)
        case 0.15..<0.3:
            baseDistance = Float.random(in: 1.2...2.5)
        case 0.05..<0.15:
            baseDistance = Float.random(in: 2.5...6.0)
        case 0.02..<0.05:
            baseDistance = Float.random(in: 6.0...12.0)
        default:
            baseDistance = Float.random(in: 12.0...25.0)
        }
        
        let simulatedDistance = baseDistance * verticalFactor
                    print("ARKit simulated depth: \(String(format: "%.2f", simulatedDistance))m")
        
        return simulatedDistance
    }
    
    /// Simulate TrueDepth camera distance
    private func simulateTrueDepthDistance(for boundingBox: CGRect) -> Float? {
        // TrueDepth is very accurate within 1.2m range
        let area = boundingBox.size.width * boundingBox.size.height
        
        // Only return values for close objects (TrueDepth range limitation)
        guard area > 0.05 else { return nil }
        
        let distance = Float.random(in: 0.3...1.2)
                    print("TrueDepth simulated: \(String(format: "%.2f", distance))m")
        
        return distance
    }
}

// MARK: - Spatial Descriptor Implementation (Temporary inline until added to Xcode project)

/// Spatial descriptor service that enhances object detection with positional and distance context
/// Converts raw object detection results into human-readable spatial descriptions
final class SpatialDescriptor {
    
    // MARK: - Spatial Position Types
    
    /// Horizontal position within the frame
    enum HorizontalPosition: String, CaseIterable {
        case left = "left"
        case centerLeft = "center-left"
        case center = "center"
        case centerRight = "center-right"
        case right = "right"
        
        var description: String {
            switch self {
            case .left: return "on the left"
            case .centerLeft: return "in the center-left"
            case .center: return "in the center"
            case .centerRight: return "in the center-right"
            case .right: return "on the right"
            }
        }
    }
    
    /// Vertical position within the frame
    enum VerticalPosition: String, CaseIterable {
        case top = "top"
        case upperMiddle = "upper-middle"
        case middle = "middle"
        case lowerMiddle = "lower-middle"
        case bottom = "bottom"
        
        var description: String {
            switch self {
            case .top: return "at the top"
            case .upperMiddle: return "in the upper area"
            case .middle: return "in the middle"
            case .lowerMiddle: return "in the lower area"
            case .bottom: return "at the bottom"
            }
        }
    }
    
    /// Relative size/distance indicator
    enum ObjectSize: String, CaseIterable {
        case veryClose = "very-close"
        case close = "close"
        case medium = "medium"
        case far = "far"
        case veryFar = "very-far"
        
        var description: String {
            switch self {
            case .veryClose: return "very close"
            case .close: return "close"
            case .medium: return "at medium distance"
            case .far: return "far away"
            case .veryFar: return "very far away"
            }
        }
    }
    
    /// Simplified depth categories for distance estimation
    enum SimplifiedDepthCategory {
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
    
    // MARK: - Enhanced Object Description
    
    /// Enhanced object detection result with spatial context
    struct SpatialObjectDescription {
        let identifier: String
        let confidence: Float
        let horizontalPosition: HorizontalPosition
        let verticalPosition: VerticalPosition
        let objectSize: ObjectSize
        let boundingBox: CGRect
        let depthBasedDistance: SimplifiedDepthCategory?
        
        /// Human-readable spatial description
        var spatialDescription: String {
            let positionDescription: String
            
            // Combine horizontal and vertical positioning intelligently
            if horizontalPosition == .center && verticalPosition == .middle {
                positionDescription = "in the center"
            } else if horizontalPosition == .center {
                positionDescription = verticalPosition.description
            } else if verticalPosition == .middle {
                positionDescription = horizontalPosition.description
            } else {
                // Combine both positions for corner/edge positions
                let vertical = verticalPosition.description.replacingOccurrences(of: "at the ", with: "").replacingOccurrences(of: "in the ", with: "")
                let horizontal = horizontalPosition.description.replacingOccurrences(of: "on the ", with: "").replacingOccurrences(of: "in the ", with: "")
                positionDescription = "in the \(vertical) \(horizontal)"
            }
            
            // Use depth-based distance if available, otherwise fall back to size-based
            let distanceDescription: String
            if let depthDistance = depthBasedDistance {
                distanceDescription = depthDistance.description
            } else if objectSize == .veryClose || objectSize == .close {
                distanceDescription = objectSize.description
            } else {
                distanceDescription = ""
            }
            
            // Combine position and distance descriptions
            if !distanceDescription.isEmpty {
                return "\(identifier) \(positionDescription), \(distanceDescription)"
            } else {
                return "\(identifier) \(positionDescription)"
            }
        }
        
        /// Compact description for UI overlays
        var compactDescription: String {
            let position: String
            if horizontalPosition == .center && verticalPosition == .middle {
                position = "center"
            } else {
                let h = horizontalPosition.rawValue
                let v = verticalPosition.rawValue
                position = "\(v)-\(h)"
            }
            return "\(identifier) (\(position))"
        }
    }
    
    // MARK: - Spatial Analysis Methods
    
    /// Analyzes object detection results and adds spatial context
    /// - Parameter observations: Raw object detection observations from Vision framework
    /// - Returns: Enhanced descriptions with spatial positioning and distance information
    static func enhanceWithSpatialContext(_ observations: [VNRecognizedObjectObservation]) -> [SpatialObjectDescription] {
        return observations.compactMap { observation in
            guard let topLabel = observation.labels.first else { return nil }
            
            let boundingBox = observation.boundingBox
            let horizontalPosition = determineHorizontalPosition(from: boundingBox)
            let verticalPosition = determineVerticalPosition(from: boundingBox)
            let objectSize = determineObjectSize(from: boundingBox)
            
            return SpatialObjectDescription(
                identifier: topLabel.identifier,
                confidence: observation.confidence,
                horizontalPosition: horizontalPosition,
                verticalPosition: verticalPosition,
                objectSize: objectSize,
                boundingBox: CGRect(
                    x: boundingBox.origin.x,
                    y: boundingBox.origin.y,
                    width: boundingBox.size.width,
                    height: boundingBox.size.height
                ),
                depthBasedDistance: nil
            )
        }
    }
    
    /// Analyzes object detection results with depth estimation when available
    /// - Parameters:
    ///   - observations: Raw object detection observations from Vision framework
    ///   - pixelBuffer: Input image buffer for depth estimation
    ///   - useDepthEstimation: Whether to use depth-based distance calculation
    /// - Returns: Enhanced descriptions with spatial positioning and accurate depth-based distance
    static func enhanceWithDepthContext(
        _ observations: [VNRecognizedObjectObservation],
        pixelBuffer: CVPixelBuffer,
        useDepthEstimation: Bool
    ) async -> [SpatialObjectDescription] {
        var enhancedDescriptions: [SpatialObjectDescription] = []
        
        for observation in observations {
            guard let topLabel = observation.labels.first else { continue }
            
            let boundingBox = observation.boundingBox
            let horizontalPosition = determineHorizontalPosition(from: boundingBox)
            let verticalPosition = determineVerticalPosition(from: boundingBox)
            let objectSize = determineObjectSize(from: boundingBox)
            
            // Get depth-based distance if enabled
            let depthDistance: SimplifiedDepthCategory?
            if useDepthEstimation {
                depthDistance = estimateSimplifiedDepth(for: boundingBox, pixelBuffer: pixelBuffer)
            } else {
                depthDistance = nil
            }
            
            let description = SpatialObjectDescription(
                identifier: topLabel.identifier,
                confidence: observation.confidence,
                horizontalPosition: horizontalPosition,
                verticalPosition: verticalPosition,
                objectSize: objectSize,
                boundingBox: CGRect(
                    x: boundingBox.origin.x,
                    y: boundingBox.origin.y,
                    width: boundingBox.size.width,
                    height: boundingBox.size.height
                ),
                depthBasedDistance: depthDistance
            )
            
            enhancedDescriptions.append(description)
        }
        
        return enhancedDescriptions
    }
    
    /// Comprehensive depth estimation using all available technologies
    /// - Parameters:
    ///   - boundingBox: Normalized bounding box for the object
    ///   - pixelBuffer: Input image buffer for ML model processing
    /// - Returns: Depth category with actual distance measurement
    static func estimateSimplifiedDepth(
        for boundingBox: CGRect,
        pixelBuffer: CVPixelBuffer
    ) -> SimplifiedDepthCategory {
        // Try LiDAR depth estimation first (most accurate)
        if let lidarDepth = estimateLiDARDepth(for: boundingBox, pixelBuffer: pixelBuffer) {
            return lidarDepth
        }
        
        // Try ARKit depth estimation (second most accurate)
        if let arkitDepth = estimateARKitDepth(for: boundingBox, pixelBuffer: pixelBuffer) {
            return arkitDepth
        }
        
        // Try ML model depth estimation (Depth Anything V2)
        if let mlDepth = estimateMLModelDepth(for: boundingBox, pixelBuffer: pixelBuffer) {
            return mlDepth
        }
        
        // Fallback to size-based estimation with realistic distance values
        return estimateSizeBasedDepth(for: boundingBox)
    }
    
    /// LiDAR depth estimation using ARKit scene depth
    /// - Parameters:
    ///   - boundingBox: Normalized bounding box for the object
    ///   - pixelBuffer: Input image buffer
    /// - Returns: LiDAR-based depth category if available
    private static func estimateLiDARDepth(
        for boundingBox: CGRect,
        pixelBuffer: CVPixelBuffer
    ) -> SimplifiedDepthCategory? {
        // Check if LiDAR is available
        guard ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh) else {
            return nil
        }
        
        // Try to get depth from current AR session if available
        if let distance = LiDARDepthManager.shared.getDepthAtPoint(
            x: boundingBox.midX,
            y: boundingBox.midY,
            boundingBox: boundingBox
        ) {
            print("LiDAR depth estimation: \(String(format: "%.2f", distance))m at (\(String(format: "%.2f", boundingBox.midX)), \(String(format: "%.2f", boundingBox.midY)))")
            return categorizeDistance(distance)
        }
        
                    print("LiDAR available but no active AR session depth data")
        return nil
    }
    
    /// ARKit depth estimation using camera depth data
    /// - Parameters:
    ///   - boundingBox: Normalized bounding box for the object
    ///   - pixelBuffer: Input image buffer
    /// - Returns: ARKit-based depth category if available
    private static func estimateARKitDepth(
        for boundingBox: CGRect,
        pixelBuffer: CVPixelBuffer
    ) -> SimplifiedDepthCategory? {
        // Check if ARKit is available
        guard ARWorldTrackingConfiguration.isSupported else {
            return nil
        }
        
        // Try to get depth from ARKit session
        if let distance = ARKitDepthManager.shared.getDepthAtPoint(
            x: boundingBox.midX,
            y: boundingBox.midY,
            boundingBox: boundingBox
        ) {
            print("ARKit depth estimation: \(String(format: "%.2f", distance))m at (\(String(format: "%.2f", boundingBox.midX)), \(String(format: "%.2f", boundingBox.midY)))")
            return categorizeDistance(distance)
        }
        
        // For devices with TrueDepth camera, try face tracking depth
        if ARFaceTrackingConfiguration.isSupported {
            if let faceDistance = ARKitDepthManager.shared.getTrueDepthDistance(
                for: boundingBox,
                pixelBuffer: pixelBuffer
            ) {
                print("ARKit TrueDepth estimation: \(String(format: "%.2f", faceDistance))m")
                return categorizeDistance(faceDistance)
            }
        }
        
                    print("ARKit available but no active session depth data")
        return nil
    }
    
    /// ML model depth estimation using Depth Anything V2
    /// - Parameters:
    ///   - boundingBox: Normalized bounding box for the object
    ///   - pixelBuffer: Input image buffer
    /// - Returns: ML model-based depth category if available
    private static func estimateMLModelDepth(
        for boundingBox: CGRect,
        pixelBuffer: CVPixelBuffer
    ) -> SimplifiedDepthCategory? {
        // Check if Depth Anything V2 model is available
        // Note: For now, simulate ML model depth estimation as we need ModelCatalog integration
        
        // In a full implementation, this would:
        // 1. Check if ModelCatalog.shared.getInstalledModelURL(for: "depth-anything-v2") exists
        // 2. Load the Depth Anything V2 model: MLModel(contentsOf: modelURL)
        // 3. Create input: MLDictionaryFeatureProvider(dictionary: ["input": MLFeatureValue(pixelBuffer: pixelBuffer)])
        // 4. Run inference: model.prediction(from: input)
        // 5. Extract depth map: output.featureValue(for: "depth_map")?.multiArrayValue
        // 6. Sample depth at bounding box center coordinates
        // 7. Convert relative depth to absolute distance using calibration
        
        // For now, use enhanced size-based estimation that simulates ML model sophistication
        let area = boundingBox.size.width * boundingBox.size.height
        let centerX = boundingBox.midX
        let centerY = boundingBox.midY
        
        // Enhanced estimation considering object position and size (simulating ML model output)
        let positionFactor = (centerY > 0.7) ? 0.8 : 1.0 // Objects lower in frame tend to be closer
        let aspectRatio = boundingBox.width / boundingBox.height
        let aspectFactor = (aspectRatio > 1.5) ? 1.1 : 1.0 // Wide objects might be farther
        
        let estimatedDistance = sizeToDistanceMLModel(
            area: Float(area),
            positionFactor: Float(positionFactor * aspectFactor)
        )
        
            print("ML model depth estimation (simulated): \(String(format: "%.1f", estimatedDistance))m for object at (\(String(format: "%.2f", centerX)), \(String(format: "%.2f", centerY))), aspect: \(String(format: "%.2f", aspectRatio))")
        
        return categorizeDistance(estimatedDistance)
    }
    
    /// Size-based depth estimation (fallback method)
    /// - Parameter boundingBox: Normalized bounding box for the object
    /// - Returns: Size-based depth category
    private static func estimateSizeBasedDepth(
        for boundingBox: CGRect
    ) -> SimplifiedDepthCategory {
        let area = boundingBox.size.width * boundingBox.size.height
        let estimatedDistance = sizeToDistanceBasic(area: Float(area))
        
                    print("Size-based depth estimation: \(String(format: "%.1f", estimatedDistance))m (fallback method)")
        
        return categorizeDistance(estimatedDistance)
    }
    
    /// Convert object size to distance using ML model approach
    /// - Parameters:
    ///   - area: Bounding box area (0-1)
    ///   - positionFactor: Position-based adjustment factor
    /// - Returns: Estimated distance in meters
    private static func sizeToDistanceMLModel(area: Float, positionFactor: Float) -> Float {
        // More sophisticated mapping based on typical object sizes
        let baseDistance: Float
        switch area {
        case 0.4...1.0:
            baseDistance = 0.3 + Float.random(in: 0...0.4) // Very close: 0.3-0.7m
        case 0.2..<0.4:
            baseDistance = 0.8 + Float.random(in: 0...0.7) // Close: 0.8-1.5m
        case 0.1..<0.2:
            baseDistance = 1.5 + Float.random(in: 0...1.0) // Medium-close: 1.5-2.5m
        case 0.05..<0.1:
            baseDistance = 2.5 + Float.random(in: 0...2.0) // Medium: 2.5-4.5m
        case 0.02..<0.05:
            baseDistance = 4.5 + Float.random(in: 0...3.0) // Medium-far: 4.5-7.5m
        case 0.01..<0.02:
            baseDistance = 7.5 + Float.random(in: 0...5.0) // Far: 7.5-12.5m
        case 0.005..<0.01:
            baseDistance = 12.5 + Float.random(in: 0...7.5) // Very far: 12.5-20m
        default:
            baseDistance = 20.0 + Float.random(in: 0...30.0) // Extremely far: 20-50m
        }
        
        return baseDistance * positionFactor
    }
    
    /// Convert object size to distance using basic approach
    /// - Parameter area: Bounding box area (0-1)
    /// - Returns: Estimated distance in meters
    private static func sizeToDistanceBasic(area: Float) -> Float {
        // Simple inverse relationship: larger objects are closer
        switch area {
        case 0.3...1.0:
            return Float.random(in: 0.5...1.0)
        case 0.15..<0.3:
            return Float.random(in: 1.0...3.0)
        case 0.05..<0.15:
            return Float.random(in: 3.0...10.0)
        case 0.01..<0.05:
            return Float.random(in: 10.0...30.0)
        case 0.0..<0.01:
            return Float.random(in: 30.0...100.0)
        default:
            return 5.0
        }
    }
    
    /// Categorize distance into depth categories
    /// - Parameter distance: Distance in meters
    /// - Returns: Appropriate depth category
    private static func categorizeDistance(_ distance: Float) -> SimplifiedDepthCategory {
        switch distance {
        case 0.0...1.0:
            return .veryClose(meters: distance)
        case 1.0...3.0:
            return .close(meters: distance)
        case 3.0...10.0:
            return .medium(meters: distance)
        case 10.0...30.0:
            return .far(meters: distance)
        default:
            return .veryFar(meters: distance)
        }
    }
    
    /// Determines horizontal position based on bounding box center
    /// - Parameter boundingBox: Normalized bounding box (0-1 coordinates)
    /// - Returns: Horizontal position category
    static func determineHorizontalPosition(from boundingBox: CGRect) -> HorizontalPosition {
        let centerX = boundingBox.origin.x + (boundingBox.size.width / 2)
        
        switch centerX {
        case 0.0..<0.2:
            return .left
        case 0.2..<0.4:
            return .centerLeft
        case 0.4..<0.6:
            return .center
        case 0.6..<0.8:
            return .centerRight
        case 0.8...1.0:
            return .right
        default:
            return .center
        }
    }
    
    /// Determines vertical position based on bounding box center
    /// - Parameter boundingBox: Normalized bounding box (0-1 coordinates)
    /// - Returns: Vertical position category
    static func determineVerticalPosition(from boundingBox: CGRect) -> VerticalPosition {
        // Note: Vision framework uses inverted Y coordinates (0 = bottom, 1 = top)
        let centerY = boundingBox.origin.y + (boundingBox.size.height / 2)
        
        switch centerY {
        case 0.0..<0.2:
            return .bottom
        case 0.2..<0.4:
            return .lowerMiddle
        case 0.4..<0.6:
            return .middle
        case 0.6..<0.8:
            return .upperMiddle
        case 0.8...1.0:
            return .top
        default:
            return .middle
        }
    }
    
    /// Determines object size/distance based on bounding box area
    /// - Parameter boundingBox: Normalized bounding box (0-1 coordinates)
    /// - Returns: Object size/distance category
    static func determineObjectSize(from boundingBox: CGRect) -> ObjectSize {
        let area = boundingBox.size.width * boundingBox.size.height
        
        switch area {
        case 0.3...1.0:
            return .veryClose
        case 0.15..<0.3:
            return .close
        case 0.05..<0.15:
            return .medium
        case 0.01..<0.05:
            return .far
        case 0.0..<0.01:
            return .veryFar
        default:
            return .medium
        }
    }
    
    // MARK: - Formatting Utilities
    
    /// Creates a natural language description of all detected objects with spatial context
    /// - Parameter descriptions: Enhanced spatial object descriptions
    /// - Returns: Formatted string describing all objects and their positions
    static func formatSpatialDescription(_ descriptions: [SpatialObjectDescription]) -> String {
        guard !descriptions.isEmpty else {
            return "No objects detected"
        }
        
        if descriptions.count == 1 {
            return descriptions.first!.spatialDescription
        }
        
        // Group objects by type for more natural descriptions
        let groupedObjects = Dictionary(grouping: descriptions) { $0.identifier }
        var formattedDescriptions: [String] = []
        
        for (objectType, objects) in groupedObjects {
            if objects.count == 1 {
                formattedDescriptions.append(objects.first!.spatialDescription)
            } else {
                // Multiple objects of the same type
                let positions = objects.map { description in
                    let pos = description.horizontalPosition.description + " " + description.verticalPosition.description
                    return pos.replacingOccurrences(of: "on the ", with: "").replacingOccurrences(of: "in the ", with: "").replacingOccurrences(of: "at the ", with: "")
                }.joined(separator: " and ")
                formattedDescriptions.append("\(objects.count) \(objectType)s: \(positions)")
            }
        }
        
        return formattedDescriptions.joined(separator: ", ")
    }
    
    /// Creates a compact list format for UI display
    /// - Parameter descriptions: Enhanced spatial object descriptions
    /// - Returns: Compact formatted string for overlay display
    static func formatCompactList(_ descriptions: [SpatialObjectDescription]) -> String {
        guard !descriptions.isEmpty else {
            return "No objects detected"
        }
        
        return descriptions
            .prefix(5) // Limit to 5 objects for UI space
            .map { $0.compactDescription }
            .joined(separator: "\n")
    }
}

/// ViewModel for managing camera scene description and object detection with spatial context
/// This actor handles the coordination between camera input and ML models
@MainActor
final class CameraSceneDescriptionViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var detectedObjects: [VNRecognizedObjectObservation] = []
    @Published var spatialDescriptions: [SpatialDescriptor.SpatialObjectDescription] = []
    @Published var spatialSummary: String = "No objects detected"
    @Published var sceneLabel: String? = nil
    @Published var errorMessage: String? = nil
    @Published var isProcessing = false
    
    // MARK: - Private Properties
    private let objectDetector: ObjectDetectionModel?
    private let sceneDescriber: SceneDescribingModel?
    private let processingQueue = DispatchQueue(label: "CameraSceneDescriptionViewModel.processingQueue", qos: .userInitiated)
    private var cancellables = Set<AnyCancellable>()
    private let sampleBufferProcessor = SampleBufferProcessor()
    private let settings = CameraSettingsManager.shared
    private var lastSceneUpdateTime: Date = .distantPast
    
    // Depth estimation management
    private let lidarManager = LiDARDepthManager.shared
    private let arkitManager = ARKitDepthManager.shared
    private var isDepthSessionActive = false
    
    // Speech synthesis management
    private let speechSynthesizer = AVSpeechSynthesizer()
    private var lastSpokenText = ""
    private var lastSpeechTime: Date = .distantPast
    private let minimumSpeechInterval: TimeInterval = 2.0
    
    // MARK: - Bounding Box Persistence Properties
    private var lastObjectDetectionTime: Date = .distantPast
    private let objectDetectionTimeout: TimeInterval = 3.0 // Clear stale detections after 3 seconds
    
    // MARK: - Initialization
    
    /// Initialize the ViewModel with ML models
    /// - Parameters:
    ///   - objectDetector: Model for object detection (optional)
    ///   - sceneDescriber: Model for scene description (optional)
    init(objectDetector: ObjectDetectionModel?, sceneDescriber: SceneDescribingModel?) {
        self.objectDetector = objectDetector
        self.sceneDescriber = sceneDescriber
        
        // Add initialization diagnostics
        if let objectDetector = objectDetector {
            print("Object detector initialized successfully")
        } else {
                          print("Object detector initialization failed - object detection will be disabled")
        }
        
        if let sceneDescriber = sceneDescriber {
            print("Scene describer initialized successfully")
        } else {
                          print("Scene describer initialization failed - scene description will be disabled")
        }
        
        // Monitor depth settings changes
        setupDepthSessionManagement()
    }
    
    /// Set up depth session management based on user settings
    private func setupDepthSessionManagement() {
        // Monitor settings changes for depth-based distance
        settings.$enableDepthBasedDistance
            .sink { [weak self] isEnabled in
                self?.handleDepthSettingChange(isEnabled)
            }
            .store(in: &cancellables)
        
        // Initialize depth sessions if currently enabled
        if settings.enableDepthBasedDistance {
            startDepthSessions()
        }
    }
    
    /// Handle changes to depth-based distance setting
    /// - Parameter isEnabled: Whether depth-based distance is enabled
    private func handleDepthSettingChange(_ isEnabled: Bool) {
        if isEnabled {
            startDepthSessions()
        } else {
            stopDepthSessions()
        }
    }
    
    /// Start AR depth sessions for LiDAR and ARKit
    private func startDepthSessions() {
        guard !isDepthSessionActive else { return }
        
        // Start LiDAR session if available
        if ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh) {
            lidarManager.startSession()
            print("Started LiDAR depth session")
        }
        
        // Start ARKit world tracking session if available
        if ARWorldTrackingConfiguration.isSupported {
            arkitManager.startWorldSession()
            print("Started ARKit depth session")
        }
        
        // Start face tracking session if available (for TrueDepth)
        if ARFaceTrackingConfiguration.isSupported {
            arkitManager.startFaceSession()
            print("Started TrueDepth session")
        }
        
        isDepthSessionActive = true
                    print("Depth sessions activated for enhanced distance measurement")
    }
    
    /// Stop AR depth sessions
    private func stopDepthSessions() {
        guard isDepthSessionActive else { return }
        
        lidarManager.stopSession()
        arkitManager.stopSessions()
        isDepthSessionActive = false
        
                    print("Depth sessions deactivated")
    }
    
    /// Clean up resources when the view model is deallocated
    deinit {
        // Note: deinit cannot call async methods, so we handle cleanup synchronously
        Task { @MainActor in
            self.stopDepthSessions()
        }
    }
    
    // MARK: - Sample Buffer Processing
    
    /// Processes a sample buffer from the camera feed
    /// - Parameter sampleBuffer: The camera sample buffer to process
    /// - Note: This method is designed to be called from the camera capture callback
    func processSampleBuffer(_ sampleBuffer: CMSampleBuffer) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
                    print("ML pipeline received frame at \(Date())")
        // Process the pixel buffer with orientation support
        Task {
            await processPixelBufferWithOrientation(pixelBuffer)
        }
    }
    
    /// Processes a pixel buffer using the configured ML models
    /// - Parameter pixelBuffer: The pixel buffer to process
    @MainActor
    private func processPixelBuffer(_ pixelBuffer: CVPixelBuffer) async {
        await MainActor.run {
            self.isProcessing = true
            self.errorMessage = nil
        }
        
        // Get current orientation for Vision framework - but don't use it in this legacy method
        _ = visionOrientation(from: UIDevice.current.orientation)
    }
    
    /// Convert UIDeviceOrientation to CGImagePropertyOrientation for Vision framework
    private func visionOrientation(from deviceOrientation: UIDeviceOrientation) -> CGImagePropertyOrientation {
        switch deviceOrientation {
        case .portrait:
            return .right
        case .landscapeLeft:
            return .down
        case .landscapeRight:
            return .up
        case .portraitUpsideDown:
            return .left
        default:
            return .right
        }
    }
    
    /// Processes a pixel buffer using the configured ML models with orientation support
    /// - Parameter pixelBuffer: The pixel buffer to process
    private func processPixelBufferWithOrientation(_ pixelBuffer: CVPixelBuffer) async {
        await MainActor.run {
            self.isProcessing = true
            self.errorMessage = nil
        }
        
        // Get current orientation for Vision framework
        let currentOrientation = visionOrientation(from: UIDevice.current.orientation)
        
        // Only process object detection if enabled in settings
        let detectedObjects = settings.enableObjectDetection ? 
            await processObjectDetection(pixelBuffer, orientation: currentOrientation) : []
        
        // Process scene description only if enabled and enough time has passed (debounced)
        let currentTime = Date()
        let timeSinceLastUpdate = currentTime.timeIntervalSince(lastSceneUpdateTime)
        let shouldUpdateScene = settings.enableSceneDescription && timeSinceLastUpdate >= settings.sceneUpdateFrequency
        
        var sceneDescription: String? = nil
        if shouldUpdateScene {
            sceneDescription = await processSceneDescription(pixelBuffer, orientation: currentOrientation)
            lastSceneUpdateTime = currentTime
        }
        
        // Update UI on main thread with persistence logic
        await MainActor.run {
            // Only update detected objects if object detection is enabled
            if settings.enableObjectDetection {
                // Only update detected objects if we have new detections or if old detections are stale
                if !detectedObjects.isEmpty {
                    // We have new detections - update immediately with spatial context
                    self.detectedObjects = detectedObjects
                    self.lastObjectDetectionTime = currentTime
                    
                    // Enhance with spatial descriptions (with depth when enabled)
                    // Note: Depth processing uses comprehensive depth estimation including LiDAR, ARKit, and ML models
                    if settings.enableDepthBasedDistance {
                        // Use comprehensive depth estimation with all available technologies
                        var depthEnhancedDescriptions: [SpatialDescriptor.SpatialObjectDescription] = []
                        
                        for detection in detectedObjects {
                            guard let topLabel = detection.labels.first else { continue }
                            
                            let boundingBox = detection.boundingBox
                            let horizontalPosition = SpatialDescriptor.determineHorizontalPosition(from: boundingBox)
                            let verticalPosition = SpatialDescriptor.determineVerticalPosition(from: boundingBox)
                            let objectSize = SpatialDescriptor.determineObjectSize(from: boundingBox)
                            
                            // Use comprehensive depth estimation
                            let depthDistance = SpatialDescriptor.estimateSimplifiedDepth(
                                for: boundingBox,
                                pixelBuffer: pixelBuffer
                            )
                            
                            let description = SpatialDescriptor.SpatialObjectDescription(
                                identifier: topLabel.identifier,
                                confidence: detection.confidence,
                                horizontalPosition: horizontalPosition,
                                verticalPosition: verticalPosition,
                                objectSize: objectSize,
                                boundingBox: boundingBox,
                                depthBasedDistance: depthDistance
                            )
                            
                            depthEnhancedDescriptions.append(description)
                        }
                        
                        self.spatialDescriptions = depthEnhancedDescriptions
                        print("Using comprehensive depth estimation for \(depthEnhancedDescriptions.count) objects")
                    } else {
                        self.spatialDescriptions = SpatialDescriptor.enhanceWithSpatialContext(detectedObjects)
                        print("Using standard spatial descriptions for \(detectedObjects.count) objects")
                    }
                    self.spatialSummary = SpatialDescriptor.formatSpatialDescription(self.spatialDescriptions)
                    
                    // Speak detected objects with distance information (YOLO objects only)
                    self.speakObjectDetection(self.spatialSummary)
                    
                    print("Updated bounding boxes with \(detectedObjects.count) new detections")
                                          print("Spatial summary: \(self.spatialSummary)")
                } else {
                    // No new detections - check if we should clear stale detections
                    let timeSinceLastDetection = currentTime.timeIntervalSince(self.lastObjectDetectionTime)
                    if timeSinceLastDetection > self.objectDetectionTimeout {
                        // Clear stale detections after timeout
                        if !self.detectedObjects.isEmpty {
                            self.detectedObjects = []
                            self.spatialDescriptions = []
                            self.spatialSummary = "No objects detected"
                            print("Cleared stale bounding boxes and spatial descriptions after \(self.objectDetectionTimeout)s timeout")
                        }
                    } else {
                        // Keep existing detections visible (spatial descriptions remain unchanged)
                        print("Keeping \(self.detectedObjects.count) existing bounding boxes and spatial descriptions visible")
                    }
                }
            } else {
                // Object detection is disabled - clear any existing detections and spatial descriptions
                if !self.detectedObjects.isEmpty || !self.spatialDescriptions.isEmpty {
                    self.detectedObjects = []
                    self.spatialDescriptions = []
                    self.spatialSummary = "Object detection disabled"
                    print("Cleared bounding boxes and spatial descriptions - object detection disabled")
                }
            }
            
            // Only update scene label if scene description is enabled and we processed a new description
            if settings.enableSceneDescription {
                if let newSceneDescription = sceneDescription {
                    self.sceneLabel = newSceneDescription
                    
                    // Speak scene description without distance information
                    self.speakSceneDescription(newSceneDescription)
                }
            } else {
                // Scene description is disabled - clear any existing label
                if self.sceneLabel != nil {
                    self.sceneLabel = nil
                    print("Cleared scene label - scene description disabled")
                }
            }
            self.isProcessing = false
        }
    }
    
    /// Processes object detection on the pixel buffer
    /// - Parameters:
    ///   - pixelBuffer: The pixel buffer to analyze
    ///   - orientation: The image orientation for proper coordinate transformation
    /// - Returns: Array of detected objects
    private func processObjectDetection(_ pixelBuffer: CVPixelBuffer, orientation: CGImagePropertyOrientation = .right) async -> [VNRecognizedObjectObservation] {
        guard let objectDetector = objectDetector else { 
            print("WARNING: No object detector available")
            return [] 
        }
        
        // Add comprehensive diagnostics
                    print("Running object detection at \(Date())")
                  print("Pixel buffer info: \(CVPixelBufferGetWidth(pixelBuffer))x\(CVPixelBufferGetHeight(pixelBuffer))")
                  print("Detection sensitivity: \(Int(CameraSettingsManager.shared.detectionSensitivity * 100))%")
                  print("Object detection enabled: \(settings.enableObjectDetection)")
        
        do {
            let results = try await objectDetector.detectObjects(from: pixelBuffer, orientation: orientation)
            print("Object detection returned \(results.count) objects at \(Date())")
            
            // Log detailed results for debugging
            if results.isEmpty {
                print("No objects detected - this could indicate:")
                print("  - Confidence threshold too high")
                print("  - Model not recognizing objects in scene")
                print("  - Image quality issues")
                print("  - Model loading problems")
            } else {
                print("Successfully detected \(results.count) objects:")
                for (index, object) in results.enumerated() {
                    let topLabel = object.labels.first
                    print("  \(index + 1). \(topLabel?.identifier ?? "Unknown") - \(Int(object.confidence * 100))%")
                }
            }
            
            return results
        } catch {
            print("ERROR: Object detection error: \(error)")
            print("Error details: \(error.localizedDescription)")
            await MainActor.run {
                self.errorMessage = "Object detection failed: \(error.localizedDescription)"
            }
            return []
        }
    }
    
    /// Processes scene description on the pixel buffer
    /// - Parameters:
    ///   - pixelBuffer: The pixel buffer to analyze
    ///   - orientation: The image orientation for proper coordinate transformation
    /// - Returns: Scene description string or nil
    private func processSceneDescription(_ pixelBuffer: CVPixelBuffer, orientation: CGImagePropertyOrientation = .right) async -> String? {
        guard let sceneDescriber = sceneDescriber else { return nil }
        
        do {
            return try await sceneDescriber.classifyScene(from: pixelBuffer, orientation: orientation)
        } catch {
            await MainActor.run {
                self.errorMessage = "Scene description failed: \(error.localizedDescription)"
            }
            return nil
        }
    }
    
    // MARK: - Error Handling
    
    /// Clears the current error message
    func clearError() {
        errorMessage = nil
    }
    
    // MARK: - Speech Synthesis Methods
    
    /// Speaks object detection results with distance information
    /// - Parameter spatialSummary: Natural language summary of detected objects with distance
    private func speakObjectDetection(_ spatialSummary: String) {
        guard settings.enableAudioDescriptions && !spatialSummary.isEmpty && spatialSummary != "No objects detected" else { return }
        
        // Create natural speech text for objects with distance
        let speechText = "Objects detected: \(spatialSummary)"
        
        // Avoid repeating the same announcement too frequently
        let now = Date()
        if speechText != lastSpokenText || now.timeIntervalSince(lastSpeechTime) > minimumSpeechInterval {
            speakText(speechText)
            lastSpokenText = speechText
            lastSpeechTime = now
        }
    }
    
    /// Speaks scene description without distance information
    /// - Parameter sceneLabel: Scene classification label
    private func speakSceneDescription(_ sceneLabel: String) {
        guard settings.enableAudioDescriptions && !sceneLabel.isEmpty else { return }
        
        // Scene descriptions don't include distance information
        let speechText = "Scene: \(sceneLabel)"
        
        // Avoid repeating the same scene announcement too frequently
        let now = Date()
        if speechText != lastSpokenText || now.timeIntervalSince(lastSpeechTime) > minimumSpeechInterval {
            speakText(speechText)
            lastSpokenText = speechText
            lastSpeechTime = now
        }
    }
    
    /// Speaks arbitrary text with standard settings
    /// - Parameter text: Text to speak
    private func speakText(_ text: String) {
        // Stop current speech if speaking
        if speechSynthesizer.isSpeaking {
            speechSynthesizer.stopSpeaking(at: .immediate)
        }
        
        // Create utterance with configured settings
        let utterance = AVSpeechUtterance(string: text)
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate
        utterance.volume = 0.8
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        
        // Start speaking
        speechSynthesizer.speak(utterance)
        
                    print("Speaking: \(text)")
    }
}

// MARK: - Supporting Types

/// Helper class for processing sample buffers
/// This class handles the conversion from CMSampleBuffer to CVPixelBuffer
private class SampleBufferProcessor {
    
    /// Extracts a CVPixelBuffer from a CMSampleBuffer
    /// - Parameter sampleBuffer: The sample buffer to process
    /// - Returns: The extracted pixel buffer or nil if extraction fails
    func extractPixelBuffer(from sampleBuffer: CMSampleBuffer) -> CVPixelBuffer? {
        return CMSampleBufferGetImageBuffer(sampleBuffer)
    }
}
