import SwiftUI
import AVFoundation
import Vision
import CoreML
import Combine
import Foundation

// Import the settings manager
// Note: This may need to be moved to Services/ directory if build fails

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
    
    // MARK: - Enhanced Object Description
    
    /// Enhanced object detection result with spatial context
    struct SpatialObjectDescription {
        let identifier: String
        let confidence: Float
        let horizontalPosition: HorizontalPosition
        let verticalPosition: VerticalPosition
        let objectSize: ObjectSize
        let boundingBox: CGRect
        
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
            
            // Add size/distance context for more descriptive output
            if objectSize == .veryClose || objectSize == .close {
                return "\(identifier) \(positionDescription), \(objectSize.description)"
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
                )
            )
        }
    }
    
    /// Determines horizontal position based on bounding box center
    /// - Parameter boundingBox: Normalized bounding box (0-1 coordinates)
    /// - Returns: Horizontal position category
    private static func determineHorizontalPosition(from boundingBox: CGRect) -> HorizontalPosition {
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
    private static func determineVerticalPosition(from boundingBox: CGRect) -> VerticalPosition {
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
    private static func determineObjectSize(from boundingBox: CGRect) -> ObjectSize {
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
    }
    
    // MARK: - Sample Buffer Processing
    
    /// Processes a sample buffer from the camera feed
    /// - Parameter sampleBuffer: The camera sample buffer to process
    /// - Note: This method is designed to be called from the camera capture callback
    func processSampleBuffer(_ sampleBuffer: CMSampleBuffer) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
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
                    
                    // Enhance with spatial descriptions
                    self.spatialDescriptions = SpatialDescriptor.enhanceWithSpatialContext(detectedObjects)
                    self.spatialSummary = SpatialDescriptor.formatSpatialDescription(self.spatialDescriptions)
                    
                    print("📦 Updated bounding boxes with \(detectedObjects.count) new detections")
                    print("🗺️ Spatial summary: \(self.spatialSummary)")
                } else {
                    // No new detections - check if we should clear stale detections
                    let timeSinceLastDetection = currentTime.timeIntervalSince(self.lastObjectDetectionTime)
                    if timeSinceLastDetection > self.objectDetectionTimeout {
                        // Clear stale detections after timeout
                        if !self.detectedObjects.isEmpty {
                            self.detectedObjects = []
                            self.spatialDescriptions = []
                            self.spatialSummary = "No objects detected"
                            print("🕐 Cleared stale bounding boxes and spatial descriptions after \(self.objectDetectionTimeout)s timeout")
                        }
                    } else {
                        // Keep existing detections visible (spatial descriptions remain unchanged)
                        print("🔄 Keeping \(self.detectedObjects.count) existing bounding boxes and spatial descriptions visible")
                    }
                }
            } else {
                // Object detection is disabled - clear any existing detections and spatial descriptions
                if !self.detectedObjects.isEmpty || !self.spatialDescriptions.isEmpty {
                    self.detectedObjects = []
                    self.spatialDescriptions = []
                    self.spatialSummary = "Object detection disabled"
                    print("🚫 Cleared bounding boxes and spatial descriptions - object detection disabled")
                }
            }
            
            // Only update scene label if scene description is enabled and we processed a new description
            if settings.enableSceneDescription {
                if let newSceneDescription = sceneDescription {
                    self.sceneLabel = newSceneDescription
                }
            } else {
                // Scene description is disabled - clear any existing label
                if self.sceneLabel != nil {
                    self.sceneLabel = nil
                    print("🚫 Cleared scene label - scene description disabled")
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
            print("⚠️ No object detector available")
            return [] 
        }
        
        do {
            let results = try await objectDetector.detectObjects(from: pixelBuffer, orientation: orientation)
            print("📱 Object detection returned \(results.count) objects")
            return results
        } catch {
            print("❌ Object detection error: \(error)")
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
