import Foundation
import CoreML
import Vision

/// Dynamic model loader for runtime switching between embedded and downloaded models
/// Supports both object detection and scene classification models with hot-swapping capabilities
@MainActor
final class DynamicModelLoader: ObservableObject {
    static let shared = DynamicModelLoader()
    
    @Published private(set) var loadedObjectModels: [String: ObjectDetectionModel] = [:]
    @Published private(set) var loadedSceneModels: [String: SceneDescribingModel] = [:]
    @Published private(set) var currentObjectModel: ObjectDetectionModel?
    @Published private(set) var currentSceneModel: SceneDescribingModel?
    @Published private(set) var isLoading = false
    @Published private(set) var loadingProgress: Double = 0.0
    
    private let modelCatalog = ModelCatalog.shared
    private let modelCache = NSCache<NSString, AnyObject>()
    private let fileManager = FileManager.default
    
    // Model loading queue for thread safety
    private let loadingQueue = DispatchQueue(label: "DynamicModelLoader.loading", qos: .userInitiated)
    
    // Performance monitoring
    private var modelLoadTimes: [String: TimeInterval] = [:]
    private var modelMemoryUsage: [String: Int64] = [:]
    
    /// Result of a model loading operation
    enum LoadResult {
        case success(modelId: String)
        case failure(modelId: String, error: ModelLoadingError)
    }
    
    /// Errors that can occur during model loading
    enum ModelLoadingError: LocalizedError {
        case modelNotFound(String)
        case modelNotDownloaded(String)
        case incompatibleFormat
        case insufficientMemory
        case loadingFailed(Error)
        case validationFailed(String)
        case unsupportedModelType
        
        var errorDescription: String? {
            switch self {
            case .modelNotFound(let id): return "Model '\(id)' not found"
            case .modelNotDownloaded(let id): return "Model '\(id)' not downloaded"
            case .incompatibleFormat: return "Incompatible model format"
            case .insufficientMemory: return "Insufficient memory to load model"
            case .loadingFailed(let error): return "Loading failed: \(error.localizedDescription)"
            case .validationFailed(let reason): return "Validation failed: \(reason)"
            case .unsupportedModelType: return "Unsupported model type"
            }
        }
    }
    
    private init() {
        setupModelCache()
        loadEmbeddedModels()
    }
    
    // MARK: - Public Interface
    
    /// Loads a model by ID and makes it available for use
    /// - Parameters:
    ///   - modelId: The ID of the model to load
    ///   - setCurrent: Whether to set this as the current active model
    /// - Returns: Load result
    func loadModel(_ modelId: String, setCurrent: Bool = true) async -> LoadResult {
        // Check if already loaded
        if isModelLoaded(modelId) {
            if setCurrent {
                await setCurrentModel(modelId)
            }
            return .success(modelId: modelId)
        }
        
        // Get model metadata
        guard let metadata = modelCatalog.model(withId: modelId) else {
            return .failure(modelId: modelId, error: .modelNotFound(modelId))
        }
        
        // Check if model is installed
        guard modelCatalog.installationState(for: modelId).isInstalled else {
            return .failure(modelId: modelId, error: .modelNotDownloaded(modelId))
        }
        
        await MainActor.run {
            isLoading = true
            loadingProgress = 0.0
        }
        
        let startTime = Date()
        
        do {
            let model = try await loadModelFromDisk(metadata)
            let loadTime = Date().timeIntervalSince(startTime)
            
            await MainActor.run {
                // Store the loaded model
                switch metadata.type {
                case .objectDetection:
                    if let objectModel = model as? ObjectDetectionModel {
                        loadedObjectModels[modelId] = objectModel
                        if setCurrent {
                            currentObjectModel = objectModel
                        }
                    }
                case .sceneClassification:
                    if let sceneModel = model as? SceneDescribingModel {
                        loadedSceneModels[modelId] = sceneModel
                        if setCurrent {
                            currentSceneModel = sceneModel
                        }
                    }
                default:
                    break
                }
                
                // Store performance metrics
                modelLoadTimes[modelId] = loadTime
                modelMemoryUsage[modelId] = estimateModelMemoryUsage(metadata)
                
                isLoading = false
                loadingProgress = 1.0
            }
            
            print("Loaded model '\(metadata.name)' in \(String(format: "%.2f", loadTime))s")
            return .success(modelId: modelId)
            
        } catch {
            await MainActor.run {
                isLoading = false
                loadingProgress = 0.0
            }
            return .failure(modelId: modelId, error: .loadingFailed(error))
        }
    }
    
    /// Unloads a model to free memory
    /// - Parameter modelId: The ID of the model to unload
    func unloadModel(_ modelId: String) {
        loadedObjectModels.removeValue(forKey: modelId)
        loadedSceneModels.removeValue(forKey: modelId)
        modelCache.removeObject(forKey: NSString(string: modelId))
        modelMemoryUsage.removeValue(forKey: modelId)
        
        // If this was the current model, clear it
        if let currentObject = currentObjectModel as? DownloadableObjectDetectionModel,
           currentObject.modelId == modelId {
            currentObjectModel = nil
        }
        
        if let currentScene = currentSceneModel as? DownloadableSceneDescriber,
           currentScene.modelId == modelId {
            currentSceneModel = nil
        }
        
                    print("Unloaded model: \(modelId)")
    }
    
    /// Sets the current active model for a given type
    /// - Parameter modelId: The ID of the model to set as current
    func setCurrentModel(_ modelId: String) async {
        guard let metadata = modelCatalog.model(withId: modelId) else { return }
        
        switch metadata.type {
        case .objectDetection:
            if let model = loadedObjectModels[modelId] {
                currentObjectModel = model
                print("Switched to object detection model: \(metadata.name)")
            }
        case .sceneClassification:
            if let model = loadedSceneModels[modelId] {
                currentSceneModel = model
                print("Switched to scene classification model: \(metadata.name)")
            }
        default:
            break
        }
    }
    
    /// Gets all loaded models of a specific type
    /// - Parameter type: The model type to filter by
    /// - Returns: Array of model IDs
    func loadedModels(ofType type: ModelType) -> [String] {
        switch type {
        case .objectDetection:
            return Array(loadedObjectModels.keys)
        case .sceneClassification:
            return Array(loadedSceneModels.keys)
        default:
            return []
        }
    }
    
    /// Checks if a model is currently loaded
    /// - Parameter modelId: The model ID to check
    /// - Returns: True if loaded
    func isModelLoaded(_ modelId: String) -> Bool {
        return loadedObjectModels[modelId] != nil || loadedSceneModels[modelId] != nil
    }
    
    /// Gets performance metrics for a loaded model
    /// - Parameter modelId: The model ID
    /// - Returns: Performance metrics tuple (load time, memory usage)
    func modelPerformance(_ modelId: String) -> (loadTime: TimeInterval?, memoryMB: Int64?) {
        let loadTime = modelLoadTimes[modelId]
        let memoryUsage = modelMemoryUsage[modelId]
        return (loadTime, memoryUsage)
    }
    
    /// Gets total memory usage of all loaded models
    /// - Returns: Total memory usage in MB
    func totalMemoryUsage() -> Int64 {
        return modelMemoryUsage.values.reduce(0, +)
    }
    
    /// Preloads models for better performance
    /// - Parameter modelIds: Array of model IDs to preload
    func preloadModels(_ modelIds: [String]) async {
        for modelId in modelIds {
            _ = await loadModel(modelId, setCurrent: false)
        }
    }
    
    /// Clears all loaded models to free memory
    func clearAllModels() {
        loadedObjectModels.removeAll()
        loadedSceneModels.removeAll()
        modelCache.removeAllObjects()
        modelMemoryUsage.removeAll()
        currentObjectModel = nil
        currentSceneModel = nil
        
                    print("Cleared all loaded models")
    }
    
    // MARK: - Private Implementation
    
    /// Sets up the model cache with memory limits
    private func setupModelCache() {
        modelCache.countLimit = 10 // Maximum 10 cached models
        modelCache.totalCostLimit = 500 * 1024 * 1024 // 500MB memory limit
    }
    
    /// Loads embedded models that come with the app
    private func loadEmbeddedModels() {
        Task {
            // Load embedded YOLOv3Tiny model
            if let yoloModel = YOLOv3Model() {
                loadedObjectModels["embedded_yolo3"] = yoloModel
                currentObjectModel = yoloModel
            }
            
            // Load embedded Places365 model
            let places365Model = Places365SceneDescriber()
            loadedSceneModels["embedded_places365"] = places365Model
            currentSceneModel = places365Model
            
            print("Loaded embedded models")
        }
    }
    
    /// Loads a model from disk
    private func loadModelFromDisk(_ metadata: ModelMetadata) async throws -> Any {
        guard let localURL = modelCatalog.localURL(for: metadata.id) else {
            throw ModelLoadingError.modelNotDownloaded(metadata.id)
        }
        
        // Check if model is in cache
        if let cachedModel = modelCache.object(forKey: NSString(string: metadata.id)) {
            await updateLoadingProgress(0.8)
            return cachedModel
        }
        
        await updateLoadingProgress(0.2)
        
        // Load CoreML model
        let mlModel = try MLModel(contentsOf: localURL)
        
        await updateLoadingProgress(0.6)
        
        // Create appropriate wrapper based on model type
        let wrappedModel: Any
        switch metadata.type {
        case .objectDetection:
            wrappedModel = DownloadableObjectDetectionModel(
                modelId: metadata.id,
                metadata: metadata,
                mlModel: mlModel
            )
        case .sceneClassification:
            wrappedModel = DownloadableSceneDescriber(
                modelId: metadata.id,
                metadata: metadata,
                mlModel: mlModel
            )
        default:
            throw ModelLoadingError.unsupportedModelType
        }
        
        await updateLoadingProgress(0.9)
        
        // Cache the model
        modelCache.setObject(wrappedModel as AnyObject, forKey: NSString(string: metadata.id))
        
        await updateLoadingProgress(1.0)
        
        return wrappedModel
    }
    
    /// Updates loading progress
    private func updateLoadingProgress(_ progress: Double) async {
        await MainActor.run {
            loadingProgress = progress
        }
    }
    
    /// Estimates memory usage for a model
    private func estimateModelMemoryUsage(_ metadata: ModelMetadata) -> Int64 {
        // Rough estimation: file size * 1.5 (for runtime overhead)
        return (metadata.fileSize * 3) / (2 * 1024 * 1024) // Convert to MB
    }
}

// MARK: - Downloadable Model Wrappers

/// Wrapper for downloadable object detection models
final class DownloadableObjectDetectionModel: ObjectDetectionModel {
    let modelId: String
    let metadata: ModelMetadata
    private let visionModel: VNCoreMLModel
    
    init(modelId: String, metadata: ModelMetadata, mlModel: MLModel) throws {
        self.modelId = modelId
        self.metadata = metadata
        self.visionModel = try VNCoreMLModel(for: mlModel)
    }
    
    func detectObjects(from pixelBuffer: CVPixelBuffer, orientation: CGImagePropertyOrientation) async throws -> [VNRecognizedObjectObservation] {
        return try await withCheckedThrowingContinuation { continuation in
            let request = VNCoreMLRequest(model: visionModel) { request, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                let results = request.results?.compactMap { $0 as? VNRecognizedObjectObservation } ?? []
                continuation.resume(returning: results)
            }
            
            let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: orientation)
            
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    try handler.perform([request])
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    func detectObjects(from pixelBuffer: CVPixelBuffer) async throws -> [VNRecognizedObjectObservation] {
        return try await detectObjects(from: pixelBuffer, orientation: .right)
    }
}

/// Wrapper for downloadable scene description models
final class DownloadableSceneDescriber: SceneDescribingModel {
    let modelId: String
    let metadata: ModelMetadata
    private let visionModel: VNCoreMLModel
    
    init(modelId: String, metadata: ModelMetadata, mlModel: MLModel) throws {
        self.modelId = modelId
        self.metadata = metadata
        self.visionModel = try VNCoreMLModel(for: mlModel)
    }
    
    func classifyScene(from pixelBuffer: CVPixelBuffer, orientation: CGImagePropertyOrientation) async throws -> String {
        return try await withCheckedThrowingContinuation { continuation in
            let request = VNCoreMLRequest(model: visionModel) { request, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let results = request.results as? [VNClassificationObservation],
                      let topResult = results.first else {
                    continuation.resume(returning: "Unknown Scene")
                    return
                }
                
                continuation.resume(returning: topResult.identifier)
            }
            
            let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: orientation)
            
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    try handler.perform([request])
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    func classifyScene(from pixelBuffer: CVPixelBuffer) async throws -> String {
        return try await classifyScene(from: pixelBuffer, orientation: .right)
    }
} 