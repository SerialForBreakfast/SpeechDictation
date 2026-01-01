import Foundation
import CoreML
import CryptoKit
import UIKit

/// Advanced download manager specifically designed for ML model downloads
/// Features progress tracking, validation, background downloads, and model verification
@MainActor
final class ModelDownloadManager: NSObject, ObservableObject {
    static let shared = ModelDownloadManager()
    
    @Published private(set) var activeDownloads: [String: ModelDownloadProgress] = [:]
    @Published private(set) var downloadQueue: [String] = []
    @Published private(set) var isDownloading = false
    
    private var urlSession: URLSession!
    private let maxConcurrentDownloads = 2
    private let fileManager = FileManager.default
    private let modelCatalog = ModelCatalog.shared
    
    // Storage paths
    private let tempDownloadsDirectory: URL
    private let modelsDirectory: URL
    
    /// Progress information for a model download
    struct ModelDownloadProgress {
        let modelId: String
        let modelName: String
        var bytesDownloaded: Int64 = 0
        var totalBytes: Int64 = 0
        var progress: Double { totalBytes > 0 ? Double(bytesDownloaded) / Double(totalBytes) : 0.0 }
        var downloadSpeed: Double = 0.0 // bytes per second
        var estimatedTimeRemaining: TimeInterval = 0.0
        var startTime: Date = Date()
        var lastUpdate: Date = Date()
        
        var formattedProgress: String {
            let formatter = ByteCountFormatter()
            formatter.countStyle = .file
            let downloaded = formatter.string(fromByteCount: bytesDownloaded)
            let total = formatter.string(fromByteCount: totalBytes)
            return "\(downloaded) / \(total)"
        }
        
        var formattedSpeed: String {
            let formatter = ByteCountFormatter()
            formatter.countStyle = .file
            return "\(formatter.string(fromByteCount: Int64(downloadSpeed)))/s"
        }
        
        var formattedTimeRemaining: String {
            if estimatedTimeRemaining == 0 { return "Calculating..." }
            
            let minutes = Int(estimatedTimeRemaining / 60)
            let seconds = Int(estimatedTimeRemaining.truncatingRemainder(dividingBy: 60))
            
            if minutes > 0 {
                return "\(minutes)m \(seconds)s"
            } else {
                return "\(seconds)s"
            }
        }
    }
    
    /// Download result with detailed information
    enum DownloadResult {
        case success(modelId: String, localURL: URL)
        case failure(modelId: String, error: ModelDownloadError)
    }
    
    /// Specific errors for model downloads
    enum ModelDownloadError: LocalizedError {
        case modelNotFound(String)
        case invalidURL
        case downloadFailed(Error)
        case checksumMismatch
        case incompatibleModel
        case insufficientStorage
        case networkUnavailable
        case validationFailed(String)
        
        var errorDescription: String? {
            switch self {
            case .modelNotFound(let id): return "Model '\(id)' not found in catalog"
            case .invalidURL: return "Invalid download URL"
            case .downloadFailed(let error): return "Download failed: \(error.localizedDescription)"
            case .checksumMismatch: return "File integrity check failed"
            case .incompatibleModel: return "Model not compatible with this device"
            case .insufficientStorage: return "Insufficient storage space"
            case .networkUnavailable: return "Network connection unavailable"
            case .validationFailed(let reason): return "Model validation failed: \(reason)"
            }
        }
    }
    
    private override init() {
        let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        modelsDirectory = documentsDirectory.appendingPathComponent("DownloadedModels")
        tempDownloadsDirectory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first!
            .appendingPathComponent("ModelDownloads")
        
        super.init()
        
        setupURLSession()
        setupDirectories()
    }
    
    // MARK: - Public Interface
    
    /// Downloads a model by ID
    /// - Parameters:
    ///   - modelId: The ID of the model to download
    ///   - priority: Download priority (higher numbers are processed first)
    /// - Returns: Download result
    func downloadModel(_ modelId: String, priority: Int = 0) async -> DownloadResult {
        // Check if model exists in catalog
        guard let model = modelCatalog.model(withId: modelId) else {
            return .failure(modelId: modelId, error: .modelNotFound(modelId))
        }
        
        // Check device compatibility
        guard model.isCompatible else {
            return .failure(modelId: modelId, error: .incompatibleModel)
        }
        
        // Check available storage
        guard hasEnoughStorage(for: model) else {
            return .failure(modelId: modelId, error: .insufficientStorage)
        }
        
        // Check if already downloading
        if activeDownloads[modelId] != nil {
            AppLog.notice(.download, "Model \(modelId) is already downloading", dedupeInterval: 2)
            return await waitForDownload(modelId)
        }
        
        // Add to queue if too many active downloads
        if activeDownloads.count >= maxConcurrentDownloads {
            addToQueue(modelId, priority: priority)
            return await waitForDownload(modelId)
        }
        
        return await performDownload(model)
    }
    
    /// Cancels a model download
    /// - Parameter modelId: The ID of the model to cancel
    func cancelDownload(_ modelId: String) {
        guard let progress = activeDownloads[modelId] else { return }
        
        // Find and cancel the download task
        urlSession.getAllTasks { tasks in
            for task in tasks {
                if let url = task.originalRequest?.url,
                   url.absoluteString.contains(modelId) {
                    task.cancel()
                    break
                }
            }
        }
        
        // Clean up temporary files
        cleanupTempFiles(for: modelId)
        
        // Update state
        activeDownloads.removeValue(forKey: modelId)
        downloadQueue.removeAll { $0 == modelId }
        
        // Update model state
        modelCatalog.updateModelState(modelId, state: .notInstalled)
        
        // Process next in queue
        processQueue()
        
        AppLog.info(.download, "Cancelled download for model: \(modelId)")
    }
    
    /// Pauses all downloads
    func pauseAllDownloads() {
        urlSession.getAllTasks { tasks in
            for task in tasks {
                task.suspend()
            }
        }
        isDownloading = false
    }
    
    /// Resumes all downloads
    func resumeAllDownloads() {
        urlSession.getAllTasks { tasks in
            for task in tasks {
                task.resume()
            }
        }
        isDownloading = !activeDownloads.isEmpty
    }
    
    /// Gets download progress for a specific model
    /// - Parameter modelId: The model ID
    /// - Returns: Download progress or nil if not downloading
    func downloadProgress(for modelId: String) -> ModelDownloadProgress? {
        return activeDownloads[modelId]
    }
    
    /// Checks if a model is currently downloading
    /// - Parameter modelId: The model ID
    /// - Returns: True if downloading
    func isDownloading(_ modelId: String) -> Bool {
        return activeDownloads[modelId] != nil
    }
    
    // MARK: - Private Implementation
    
    /// Sets up the URL session for background downloads
    private func setupURLSession() {
        let config = URLSessionConfiguration.background(withIdentifier: "com.speechdictation.modeldownloads")
        config.isDiscretionary = false
        config.sessionSendsLaunchEvents = true
        config.allowsCellularAccess = true
        urlSession = URLSession(configuration: config, delegate: self, delegateQueue: nil)
    }
    
    /// Sets up storage directories
    private func setupDirectories() {
        do {
            try fileManager.createDirectory(at: modelsDirectory, withIntermediateDirectories: true)
            try fileManager.createDirectory(at: tempDownloadsDirectory, withIntermediateDirectories: true)
        } catch {
            AppLog.error(.download, "Failed to create directories: \(error)")
        }
    }
    
    /// Performs the actual download
    private func performDownload(_ model: ModelMetadata) async -> DownloadResult {
        let tempURL = tempDownloadsDirectory.appendingPathComponent("\(model.id).mlmodel.tmp")
        let finalURL = modelsDirectory.appendingPathComponent("\(model.id).mlmodel")
        
        // Initialize progress tracking
        var progress = ModelDownloadProgress(
            modelId: model.id,
            modelName: model.name,
            totalBytes: model.fileSize
        )
        
        await MainActor.run {
            activeDownloads[model.id] = progress
            modelCatalog.updateModelState(model.id, state: .downloading(progress: 0.0))
            isDownloading = true
        }
        
        do {
            // Create download task
            let task = urlSession.downloadTask(with: model.downloadURL)
            
            // Start download
            task.resume()
            
            // Wait for completion
            let result = await withCheckedContinuation { continuation in
                downloadCompletions[model.id] = continuation
            }
            
            switch result {
            case .success(let downloadedURL):
                // Validate and install the model
                return await validateAndInstallModel(model, from: downloadedURL, to: finalURL)
                
            case .failure(let error):
                await MainActor.run {
                    activeDownloads.removeValue(forKey: model.id)
                    modelCatalog.updateModelState(model.id, state: .failed(error: error.localizedDescription))
                }
                cleanupTempFiles(for: model.id)
                return .failure(modelId: model.id, error: .downloadFailed(error))
            }
            
        } catch {
            await MainActor.run {
                activeDownloads.removeValue(forKey: model.id)
                modelCatalog.updateModelState(model.id, state: .failed(error: error.localizedDescription))
            }
            cleanupTempFiles(for: model.id)
            return .failure(modelId: model.id, error: .downloadFailed(error))
        }
    }
    
    /// Validates and installs a downloaded model
    private func validateAndInstallModel(_ model: ModelMetadata, from tempURL: URL, to finalURL: URL) async -> DownloadResult {
        await MainActor.run {
            modelCatalog.updateModelState(model.id, state: .installing)
        }
        
        do {
            // Verify checksum
            guard verifyChecksum(fileURL: tempURL, expectedChecksum: model.checksumSHA256) else {
                return .failure(modelId: model.id, error: .checksumMismatch)
            }
            
            // Validate CoreML model
            _ = try MLModel(contentsOf: tempURL)
            
            // Move to final location
            if fileManager.fileExists(atPath: finalURL.path) {
                try fileManager.removeItem(at: finalURL)
            }
            try fileManager.moveItem(at: tempURL, to: finalURL)
            
            // Save version information
            let versionURL = modelsDirectory.appendingPathComponent("\(model.id).version")
            try model.version.write(to: versionURL, atomically: true, encoding: .utf8)
            
            await MainActor.run {
                activeDownloads.removeValue(forKey: model.id)
                modelCatalog.updateModelState(model.id, state: .installed(version: model.version))
                processQueue()
            }
            
            AppLog.info(.download, "Successfully installed model: \(model.name)")
            return .success(modelId: model.id, localURL: finalURL)
            
        } catch {
            await MainActor.run {
                activeDownloads.removeValue(forKey: model.id)
                modelCatalog.updateModelState(model.id, state: .failed(error: error.localizedDescription))
            }
            cleanupTempFiles(for: model.id)
            return .failure(modelId: model.id, error: .validationFailed(error.localizedDescription))
        }
    }
    
    /// Verifies file checksum
    private func verifyChecksum(fileURL: URL, expectedChecksum: String) -> Bool {
        do {
            let data = try Data(contentsOf: fileURL)
            let hash = SHA256.hash(data: data)
            let hashString = hash.compactMap { String(format: "%02x", $0) }.joined()
            return hashString.lowercased() == expectedChecksum.lowercased()
        } catch {
            AppLog.error(.download, "Checksum verification failed: \(error)")
            return false
        }
    }
    
    /// Checks if device has enough storage
    private func hasEnoughStorage(for model: ModelMetadata) -> Bool {
        guard let systemAttributes = try? fileManager.attributesOfFileSystem(forPath: NSHomeDirectory()),
              let freeSpace = systemAttributes[.systemFreeSize] as? Int64 else {
            return false
        }
        
        // Require 2x the model size as free space
        return freeSpace > (model.fileSize * 2)
    }
    
    /// Adds model to download queue
    private func addToQueue(_ modelId: String, priority: Int) {
        if priority > 0 {
            downloadQueue.insert(modelId, at: 0)
        } else {
            downloadQueue.append(modelId)
        }
    }
    
    /// Processes next item in download queue
    private func processQueue() {
        guard !downloadQueue.isEmpty,
              activeDownloads.count < maxConcurrentDownloads else { return }
        
        let nextModelId = downloadQueue.removeFirst()
        
        Task {
            _ = await downloadModel(nextModelId)
        }
    }
    
    /// Waits for a download to complete
    private func waitForDownload(_ modelId: String) async -> DownloadResult {
        // Implementation would wait for download completion
        // This is a simplified version
        return .failure(modelId: modelId, error: .networkUnavailable)
    }
    
    /// Cleans up temporary files
    private func cleanupTempFiles(for modelId: String) {
        let tempURL = tempDownloadsDirectory.appendingPathComponent("\(modelId).mlmodel.tmp")
        if fileManager.fileExists(atPath: tempURL.path) {
            try? fileManager.removeItem(at: tempURL)
        }
    }
    
    // MARK: - Download Completion Tracking
    private var downloadCompletions: [String: CheckedContinuation<Result<URL, Error>, Never>] = [:]
    
    private func completeDownload(_ modelId: String, result: Result<URL, Error>) {
        if let continuation = downloadCompletions.removeValue(forKey: modelId) {
            continuation.resume(returning: result)
        }
    }
}

// MARK: - URLSessionDownloadDelegate

extension ModelDownloadManager: URLSessionDownloadDelegate {
    
    nonisolated func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        // Extract model ID from URL or task identifier
        guard let originalURL = downloadTask.originalRequest?.url,
              let modelId = extractModelId(from: originalURL) else { return }
        
        Task { @MainActor in
            completeDownload(modelId, result: .success(location))
        }
    }
    
    nonisolated func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        guard let originalURL = downloadTask.originalRequest?.url,
              let modelId = extractModelId(from: originalURL) else { return }
        
        Task { @MainActor in
            updateDownloadProgress(modelId: modelId, bytesWritten: totalBytesWritten, totalBytes: totalBytesExpectedToWrite)
        }
    }
    
    nonisolated func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didCompleteWithError error: Error?) {
        guard let originalURL = downloadTask.originalRequest?.url,
              let modelId = extractModelId(from: originalURL) else { return }
        
        if let error = error {
            Task { @MainActor in
                completeDownload(modelId, result: .failure(error))
            }
        }
    }
    
    private func extractModelId(from url: URL) -> String? {
        // Extract model ID from download URL
        return url.lastPathComponent.replacingOccurrences(of: ".mlmodel", with: "")
    }
    
    @MainActor
    private func updateDownloadProgress(modelId: String, bytesWritten: Int64, totalBytes: Int64) {
        guard var progress = activeDownloads[modelId] else { return }
        
        let currentTime = Date()
        let timeDelta = currentTime.timeIntervalSince(progress.lastUpdate)
        let bytesDelta = bytesWritten - progress.bytesDownloaded
        
        progress.bytesDownloaded = bytesWritten
        progress.totalBytes = totalBytes
        progress.lastUpdate = currentTime
        
        // Calculate download speed
        if timeDelta > 0 {
            progress.downloadSpeed = Double(bytesDelta) / timeDelta
        }
        
        // Calculate estimated time remaining
        if progress.downloadSpeed > 0 {
            let remainingBytes = totalBytes - bytesWritten
            progress.estimatedTimeRemaining = Double(remainingBytes) / progress.downloadSpeed
        }
        
        activeDownloads[modelId] = progress
        
        // Update model catalog state
        modelCatalog.updateModelState(modelId, state: .downloading(progress: progress.progress))
    }
} 
