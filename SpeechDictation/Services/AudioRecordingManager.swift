//
//  AudioRecordingManager.swift
//  SpeechDictation
//
//  Created by AI Assistant on 12/19/24.
//
//  Enhanced audio recording manager with secure storage capabilities for private recordings.
//  Supports both standard recording and secure recording with complete file protection.
//

import Foundation
import AVFoundation

/// Audio quality settings for recording
/// Temporarily defined here to resolve compilation issues
struct AudioQualitySettings: Codable {
    let sampleRate: Double
    let bitDepth: Int
    let channels: Int
    let compressionQuality: Float
    
    static let highQuality = AudioQualitySettings(
        sampleRate: 44100.0,
        bitDepth: 16,
        channels: 1,
        compressionQuality: 0.8
    )
    
    static let standardQuality = AudioQualitySettings(
        sampleRate: 22050.0,
        bitDepth: 16,
        channels: 1,
        compressionQuality: 0.6
    )
    
    static let lowQuality = AudioQualitySettings(
        sampleRate: 11025.0,
        bitDepth: 16,
        channels: 1,
        compressionQuality: 0.4
    )
}

/// Recording mode for different security requirements
enum RecordingMode {
    case standard    // Standard documents directory storage
    case secure      // Secure storage with complete file protection
}

/// Service responsible for high-quality audio recording and storage
/// Handles audio capture, compression, and file management with configurable quality settings
/// Supports both standard and secure recording modes for different privacy requirements
/// Uses AudioQualitySettings from TimingData.swift for quality configuration
class AudioRecordingManager: ObservableObject {
    static let shared = AudioRecordingManager()
    
    @Published private(set) var isRecording = false
    @Published private(set) var recordingDuration: TimeInterval = 0
    @Published private(set) var currentAudioFileURL: URL?
    @Published private(set) var currentRecordingMode: RecordingMode = .standard
    
    private var audioEngine: AVAudioEngine?
    private var audioFile: AVAudioFile?
    private var recordingStartTime: Date?
    private var recordingTimer: Timer?
    private let recordingQueue = DispatchQueue(label: "audioRecordingQueue", qos: .userInitiated)
    
    /// Handler for broadcasting audio buffers to other consumers (e.g. SpeechRecognizer)
    var audioBufferHandler: ((AVAudioPCMBuffer) -> Void)?
    
    // AudioQualitySettings is defined in TimingData.swift
    private var qualitySettings: AudioQualitySettings = .standardQuality
    private let documentsDirectory: URL
    
    private init() {
        documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        setupAudioSession()
    }
    
    // MARK: - Recording Control
    
    /// Starts audio recording with specified quality settings
    /// - Parameter quality: Audio quality settings (defaults to standard quality)
    /// - Returns: URL to the audio file being recorded, or nil if failed
    func startRecording(quality: AudioQualitySettings = .standardQuality) -> URL? {
        return startRecording(mode: .standard, quality: quality, sessionId: nil)
    }
    
    /// Starts secure audio recording with complete file protection
    /// - Parameters:
    ///   - quality: Audio quality settings (defaults to standard quality)
    ///   - sessionId: Optional session identifier for grouping recordings
    /// - Returns: URL to the securely stored audio file being recorded, or nil if failed
    func startSecureRecording(quality: AudioQualitySettings = .standardQuality, sessionId: String? = nil) -> URL? {
        return startRecording(mode: .secure, quality: quality, sessionId: sessionId)
    }
    
    /// Starts audio recording with specified mode and quality
    /// - Parameters:
    ///   - mode: Recording mode (standard or secure)
    ///   - quality: Audio quality settings
    ///   - sessionId: Optional session identifier for secure recordings
    /// - Returns: URL to the audio file being recorded, or nil if failed
    private func startRecording(mode: RecordingMode, quality: AudioQualitySettings, sessionId: String?) -> URL? {
        guard !isRecording else {
            AppLog.notice(.recording, "Start ignored; already recording")
            return nil
        }
        
        qualitySettings = quality
        currentRecordingMode = mode
        
        // Reconfigure the audio session each time to recover from playback-only states.
        let configured = AudioSessionManager.shared.configureForRecordingSync()
        if !configured {
            AppLog.notice(.recording, "Audio session configuration for recording failed via manager")
            do {
                let session = AVAudioSession.sharedInstance()
                try session.setCategory(.playAndRecord, mode: .default, options: [])
                try session.setActive(true, options: .notifyOthersOnDeactivation)
                AppLog.info(.recording, "Audio session configured with fallback settings")
            } catch {
                AppLog.error(.recording, "Audio session fallback configuration failed: \(error.localizedDescription)")
                return nil
            }
        }
        
        do {
            try setupAudioEngine(mode: mode, sessionId: sessionId)
            try startAudioCapture()
            
            isRecording = true
            recordingStartTime = Date()
            recordingDuration = 0
            
            startRecordingTimer()
            
            let modeDescription = mode == .secure ? "secure" : "standard"
            AppLog.info(.recording, "Started \(modeDescription) recording (\(quality.sampleRate)Hz, \(quality.bitDepth)bit)")
            return currentAudioFileURL
        } catch {
            AppLog.error(.recording, "Failed to start recording: \(error.localizedDescription)")
            return nil
        }
    }

    /// Stops the current audio recording
    /// - Returns: URL to the recorded audio file, or nil if no recording was active
    func stopRecording() -> URL? {
        guard isRecording else {
            AppLog.notice(.recording, "Stop ignored; no active recording")
            return nil
        }
        
        stopRecordingTimer()
        
        do {
            try stopAudioCapture()
            
            // For secure recordings, ensure file protection is properly applied
            if currentRecordingMode == .secure, let fileURL = currentAudioFileURL {
                validateSecureFileProtection(at: fileURL)
            }
            
            isRecording = false
            
            let audioFileURL = currentAudioFileURL
            currentAudioFileURL = nil
            recordingStartTime = nil
            currentRecordingMode = .standard
            
            AppLog.info(.recording, "Stopped audio recording")
            return audioFileURL
        } catch {
            AppLog.error(.recording, "Failed to stop recording: \(error.localizedDescription)")
            return nil
        }
    }
    
    /// Pauses the current recording (maintains file but stops capture)
    func pauseRecording() {
        guard isRecording else { return }
        
        stopRecordingTimer()
        audioEngine?.pause()
        AppLog.info(.recording, "Paused audio recording")
    }
    
    /// Resumes a paused recording
    func resumeRecording() {
        guard isRecording else { return }
        
        do {
            try audioEngine?.start()
            startRecordingTimer()
            AppLog.info(.recording, "Resumed audio recording")
        } catch {
            AppLog.error(.recording, "Failed to resume recording: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Audio Session Setup
    
    #if os(iOS)
    /// Configures the audio session for recording with iPad-specific optimizations
    /// Handles device-specific audio configuration and provides robust fallbacks
    private func setupAudioSession() {
        // Concurrency: Called from a synchronous initializer, so we must block until configuration completes
        // to avoid a race where recording begins before the audio session is ready.
        let success = AudioSessionManager.shared.configureForRecordingSync()
        guard success else {
            AppLog.notice(.recording, "Audio session setup for recording failed via manager")
            // Try a simpler configuration as fallback
            do {
                let session = AVAudioSession.sharedInstance()
                // Don't try to deactivate again if it failed before
                try session.setCategory(.playAndRecord, mode: .default, options: [])
                try session.setActive(true, options: .notifyOthersOnDeactivation)
                AppLog.info(.recording, "Audio session configured with fallback settings")
            } catch {
                AppLog.error(.recording, "Audio session fallback configuration failed: \(error.localizedDescription)")
            }
            return
        }
    }
    #else
    /// Audio session is only relevant on iOS. On macOS builds we provide a no-op implementation.
    private func setupAudioSession() {
        AppLog.debug(.recording, "Audio session setup skipped on this platform")
    }
    #endif
    
    private func setupAudioEngine(mode: RecordingMode, sessionId: String?) throws {
        audioEngine = AVAudioEngine()
        
        guard let inputNode = audioEngine?.inputNode else {
            throw AudioRecordingError.noInputNode
        }
        
        // Get the input node's native format first
        let nativeFormat = inputNode.inputFormat(forBus: 0)
        AppLog.debug(.recording, "Native input format: \(nativeFormat)", verboseOnly: true)
        
        // CRITICAL: Validate native format before proceeding
        guard nativeFormat.sampleRate > 0, nativeFormat.channelCount > 0 else {
            AppLog.error(
                .recording,
                "Invalid native audio format: sampleRate=\(nativeFormat.sampleRate), channels=\(nativeFormat.channelCount)"
            )
            throw AudioRecordingError.invalidFormat
        }
        
        // IMPORTANT: Use the native format to avoid format mismatch crashes
        // The hardware format (e.g., 24000 Hz) must match what we use for the tap
        let recordingFormat = nativeFormat
        
        AppLog.debug(.recording, "Using recording format: \(recordingFormat)", verboseOnly: true)
        
        // Create audio file for recording
        // We currently write PCM buffers directly via `AVAudioFile.write(from:)`.
        // Use a container/extension that matches the underlying PCM data so AVAudioPlayer can load it reliably.
        let fileName = "recording_\(formattedTimestamp()).caf"
        let audioFileURL: URL
        
        if mode == .secure {
            audioFileURL = CacheManager.shared.getSecureFileURL(fileName: fileName, sessionId: sessionId)
        } else {
            audioFileURL = documentsDirectory.appendingPathComponent(fileName)
        }
        
        do {
            audioFile = try AVAudioFile(
                forWriting: audioFileURL,
                settings: recordingFormat.settings,
                commonFormat: .pcmFormatFloat32,
                interleaved: false
            )
        } catch {
            AppLog.notice(
                .recording,
                "Failed to create file with format \(recordingFormat.settings). Falling back to 44.1 kHz mono."
            )
            // Fallback to a simpler format if the preferred one is unsupported
            let fallbackFormat = AVAudioFormat(standardFormatWithSampleRate: 44_100, channels: 1)!
            audioFile = try AVAudioFile(
                forWriting: audioFileURL,
                settings: fallbackFormat.settings,
                commonFormat: .pcmFormatFloat32,
                interleaved: false
            )
        }
        
        // For secure recordings, apply complete file protection immediately
        if mode == .secure {
            do {
                try FileManager.default.setAttributes(
                    [.protectionKey: FileProtectionType.complete],
                    ofItemAtPath: audioFileURL.path
                )
                AppLog.info(.recording, "Applied complete file protection: \(audioFileURL.lastPathComponent)")
            } catch {
                AppLog.notice(.recording, "Failed to apply file protection: \(error.localizedDescription)")
                // Continue recording even if protection fails, but log the issue
            }
        }
        
        currentAudioFileURL = audioFileURL
        
        // Install a tap on the input node so we can capture audio buffers
        inputNode.removeTap(onBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
            self?.processAudioBuffer(buffer)
        }
        
        audioEngine?.prepare()
    }
    
    private func startAudioCapture() throws {
        #if targetEnvironment(simulator)
        // In simulator, we might not be able to actually record audio
        // but we can still set up the engine for testing purposes
        AppLog.debug(.recording, "Starting audio capture in simulator (audio may be unavailable)", dedupeInterval: 5)
        #endif
        
        do {
            try audioEngine?.start()
        } catch {
            AppLog.error(.recording, "Failed to start audio engine: \(error.localizedDescription)")
            #if targetEnvironment(simulator)
            // In simulator, we'll continue anyway for testing
            AppLog.notice(.recording, "Continuing in simulator despite audio engine failure", dedupeInterval: 5)
            #else
            // On real device, this is a critical error that should be reported
            AppLog.fault(.recording, "Audio engine failed to start on device")
            throw error
            #endif
        }
    }
    
    private func stopAudioCapture() throws {
        audioEngine?.stop()
        audioEngine?.inputNode.removeTap(onBus: 0)
        audioFile = nil
        audioEngine = nil
    }
    
    // MARK: - Audio Processing
    
    private func processAudioBuffer(_ buffer: AVAudioPCMBuffer) {
        // Broadcast buffer to listeners (e.g. SpeechRecognizer)
        audioBufferHandler?(buffer)
        
        guard let audioFile = audioFile else { return }
        
        do {
            try audioFile.write(from: buffer)
        } catch {
            AppLog.error(.recording, "Failed to write audio buffer: \(error.localizedDescription)", dedupeInterval: 2)
        }
    }
    
    // MARK: - Timer Management
    
    private func startRecordingTimer() {
        recordingTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            DispatchQueue.main.async {
                self?.updateRecordingDuration()
            }
        }
    }
    
    private func stopRecordingTimer() {
        recordingTimer?.invalidate()
        recordingTimer = nil
    }
    
    private func updateRecordingDuration() {
        guard let startTime = recordingStartTime else { return }
        recordingDuration = Date().timeIntervalSince(startTime)
    }
    
    // MARK: - File Management
    
    /// Gets all recorded audio files
    /// - Returns: Array of URLs to recorded audio files
    func getAllAudioFiles() -> [URL] {
        do {
            let fileURLs = try FileManager.default.contentsOfDirectory(at: documentsDirectory, includingPropertiesForKeys: nil)
            // Include legacy `.m4a` files (created before we corrected the container) and the current `.caf` recordings.
            return fileURLs
                .filter { ["caf", "m4a"].contains($0.pathExtension.lowercased()) }
                .sorted { $0.lastPathComponent > $1.lastPathComponent }
        } catch {
            AppLog.error(.recording, "Failed to list audio files: \(error.localizedDescription)")
            return []
        }
    }
    
    /// Deletes an audio file
    /// - Parameter url: URL of the audio file to delete
    /// - Returns: True if deletion was successful
    func deleteAudioFile(url: URL) -> Bool {
        do {
            try FileManager.default.removeItem(at: url)
            AppLog.info(.recording, "Deleted audio file: \(url.lastPathComponent)")
            return true
        } catch {
            AppLog.error(.recording, "Failed to delete audio file: \(error.localizedDescription)")
            return false
        }
    }
    
    /// Gets file size of an audio file
    /// - Parameter url: URL of the audio file
    /// - Returns: File size in bytes, or nil if error
    func getAudioFileSize(url: URL) -> Int64? {
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
            return attributes[.size] as? Int64
        } catch {
            AppLog.error(.recording, "Failed to get file size: \(error.localizedDescription)")
            return nil
        }
    }
    
    /// Gets duration of an audio file
    /// - Parameter url: URL of the audio file
    /// - Returns: Duration in seconds, or nil if error
    func getAudioFileDuration(url: URL) -> TimeInterval? {
        do {
            let audioFile = try AVAudioFile(forReading: url)
            let format = audioFile.processingFormat
            let frameCount = Double(audioFile.length)
            return frameCount / format.sampleRate
        } catch {
            AppLog.error(.recording, "Failed to get audio duration: \(error.localizedDescription)")
            return nil
        }
    }
    
    // MARK: - Utility Methods
    
    private func formattedTimestamp() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd_HHmmss"
        return formatter.string(from: Date())
    }
    
    /// Formats file size for display
    /// - Parameter bytes: File size in bytes
    /// - Returns: Formatted string (e.g., "1.5 MB")
    func formatFileSize(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useMB, .useKB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
    
    /// Formats duration for display
    /// - Parameter duration: Duration in seconds
    /// - Returns: Formatted string (e.g., "1:23:45")
    func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        let seconds = Int(duration) % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
    
    // MARK: - Secure File Protection
    
    private func validateSecureFileProtection(at url: URL) {
        do {
            try CacheManager.shared.validateFileProtection(at: url)
            AppLog.info(.recording, "Secure file protection validated: \(url.lastPathComponent)")
        } catch {
            AppLog.error(.recording, "Secure file protection validation failed: \(error.localizedDescription)")
            // Optionally, you might want to delete the file if protection fails
            // try? FileManager.default.removeItem(at: url)
        }
    }
}

// MARK: - Error Types

enum AudioRecordingError: Error, LocalizedError {
    case noInputNode
    case invalidFormat
    case recordingFailed
    
    var errorDescription: String? {
        switch self {
        case .noInputNode:
            return "No audio input node available"
        case .invalidFormat:
            return "Invalid audio format"
        case .recordingFailed:
            return "Audio recording failed"
        }
    }
} 
