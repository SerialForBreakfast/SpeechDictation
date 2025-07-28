//
//  AudioRecordingManager.swift
//  SpeechDictation
//
//  Created by AI Assistant on 12/19/24.
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

/// Service responsible for high-quality audio recording and storage
/// Handles audio capture, compression, and file management with configurable quality settings
/// Uses AudioQualitySettings from TimingData.swift for quality configuration
class AudioRecordingManager: ObservableObject {
    static let shared = AudioRecordingManager()
    
    @Published private(set) var isRecording = false
    @Published private(set) var recordingDuration: TimeInterval = 0
    @Published private(set) var currentAudioFileURL: URL?
    
    private var audioEngine: AVAudioEngine?
    private var audioFile: AVAudioFile?
    private var recordingStartTime: Date?
    private var recordingTimer: Timer?
    private let recordingQueue = DispatchQueue(label: "audioRecordingQueue", qos: .userInitiated)
    
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
        guard !isRecording else {
            print("Already recording")
            return nil
        }
        
        qualitySettings = quality
        
        do {
            try setupAudioEngine()
            try startAudioCapture()
            
            isRecording = true
            recordingStartTime = Date()
            recordingDuration = 0
            
            startRecordingTimer()
            
            print("Started audio recording with quality: \(quality.sampleRate)Hz, \(quality.bitDepth)bit")
            return currentAudioFileURL
        } catch {
            print("Failed to start recording: \(error)")
            return nil
        }
    }
    
    /// Stops the current audio recording
    /// - Returns: URL to the recorded audio file, or nil if no recording was active
    func stopRecording() -> URL? {
        guard isRecording else {
            print("No active recording to stop")
            return nil
        }
        
        stopRecordingTimer()
        
        do {
            try stopAudioCapture()
            isRecording = false
            
            let audioFileURL = currentAudioFileURL
            currentAudioFileURL = nil
            recordingStartTime = nil
            
            print("Stopped audio recording")
            return audioFileURL
        } catch {
            print("Error stopping recording: \(error)")
            return nil
        }
    }
    
    /// Pauses the current recording (maintains file but stops capture)
    func pauseRecording() {
        guard isRecording else { return }
        
        stopRecordingTimer()
        audioEngine?.pause()
        print("Paused audio recording")
    }
    
    /// Resumes a paused recording
    func resumeRecording() {
        guard isRecording else { return }
        
        do {
            try audioEngine?.start()
            startRecordingTimer()
            print("Resumed audio recording")
        } catch {
            print("Error resuming recording: \(error)")
        }
    }
    
    // MARK: - Audio Session Setup
    
    #if os(iOS)
    /// Configures the audio session for recording with iPad-specific optimizations
    /// Handles device-specific audio configuration and provides robust fallbacks
    private func setupAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            
            // Check if session is already active before trying to deactivate
            if session.isOtherAudioPlaying {
                print("Other audio is playing, will configure without deactivation")
            } else {
                // Only deactivate if not already inactive
                if session.category != .playAndRecord {
                    try session.setActive(false, options: .notifyOthersOnDeactivation)
                }
            }
            
            #if targetEnvironment(simulator)
            // Use simpler configuration for simulator
            try session.setCategory(.playAndRecord, mode: .default, options: [])
            #else
            // Device-specific configuration with iPad optimizations
            let options: AVAudioSession.CategoryOptions = [.defaultToSpeaker, .allowBluetooth]
            
            // Try measurement mode first for better speech recognition
            do {
                try session.setCategory(.playAndRecord, mode: .measurement, options: options)
                print("Audio session configured with measurement mode")
            } catch {
                print("Measurement mode failed, trying default mode: \(error)")
                // Fallback to default mode if measurement fails
                try session.setCategory(.playAndRecord, mode: .default, options: options)
                print("Audio session configured with default mode")
            }
            #endif
            
            // Activate session with proper options
            try session.setActive(true, options: .notifyOthersOnDeactivation)
            print("Audio session configured for recording")
            
        } catch {
            print("Error setting up audio session: \(error)")
            // Try a simpler configuration as fallback
            do {
                let session = AVAudioSession.sharedInstance()
                // Don't try to deactivate again if it failed before
                try session.setCategory(.playAndRecord, mode: .default, options: [])
                try session.setActive(true, options: .notifyOthersOnDeactivation)
                print("Audio session configured with fallback settings")
            } catch {
                print("Failed to configure audio session even with fallback: \(error)")
            }
        }
    }
    #else
    /// Audio session is only relevant on iOS. On macOS builds we provide a no-op implementation.
    private func setupAudioSession() {
        print("Audio session setup skipped – not available on this platform.")
    }
    #endif
    
    private func setupAudioEngine() throws {
        audioEngine = AVAudioEngine()
        
        guard let inputNode = audioEngine?.inputNode else {
            throw AudioRecordingError.noInputNode
        }
        
        // Get the input node's native format first
        let nativeFormat = inputNode.inputFormat(forBus: 0)
        print("Native input format: \(nativeFormat)")
        
        // CRITICAL: Validate native format before proceeding
        guard nativeFormat.sampleRate > 0, nativeFormat.channelCount > 0 else {
            print("ERROR: Invalid native audio format detected: sampleRate=\(nativeFormat.sampleRate), channels=\(nativeFormat.channelCount)")
            print("This typically indicates a hardware audio configuration issue on the device.")
            throw AudioRecordingError.invalidFormat
        }
        
        // IMPORTANT: Use the native format to avoid format mismatch crashes
        // The hardware format (e.g., 24000 Hz) must match what we use for the tap
        let recordingFormat = nativeFormat
        
        print("Using recording format: \(recordingFormat)")
        
        // Create audio file for recording
        let fileName = "recording_\(formattedTimestamp()).m4a"
        let audioFileURL = documentsDirectory.appendingPathComponent(fileName)
        
        do {
            audioFile = try AVAudioFile(
                forWriting: audioFileURL,
                settings: recordingFormat.settings,
                commonFormat: .pcmFormatFloat32,
                interleaved: false
            )
        } catch {
            print("Failed to create audio file with format: \(recordingFormat.settings). Falling back to 44.1 kHz mono.")
            // Fallback to a simpler format if the preferred one is unsupported
            let fallbackFormat = AVAudioFormat(standardFormatWithSampleRate: 44_100, channels: 1)!
            audioFile = try AVAudioFile(
                forWriting: audioFileURL,
                settings: fallbackFormat.settings,
                commonFormat: .pcmFormatFloat32,
                interleaved: false
            )
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
        print("Starting audio capture in simulator (may not record actual audio)")
        #endif
        
        do {
            try audioEngine?.start()
        } catch {
            print("Failed to start audio engine: \(error)")
            #if targetEnvironment(simulator)
            // In simulator, we'll continue anyway for testing
            print("Continuing in simulator despite audio engine failure")
            #else
            // On real device, this is a critical error that should be reported
            print("CRITICAL: Audio engine failed to start on device. This may indicate a hardware issue.")
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
        guard let audioFile = audioFile else { return }
        
        do {
            try audioFile.write(from: buffer)
        } catch {
            print("Error writing audio buffer: \(error)")
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
            return fileURLs.filter { $0.pathExtension == "m4a" }.sorted { $0.lastPathComponent > $1.lastPathComponent }
        } catch {
            print("Error getting audio files: \(error)")
            return []
        }
    }
    
    /// Deletes an audio file
    /// - Parameter url: URL of the audio file to delete
    /// - Returns: True if deletion was successful
    func deleteAudioFile(url: URL) -> Bool {
        do {
            try FileManager.default.removeItem(at: url)
            print("Deleted audio file: \(url.lastPathComponent)")
            return true
        } catch {
            print("Error deleting audio file: \(error)")
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
            print("Error getting file size: \(error)")
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
            print("Error getting audio duration: \(error)")
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
