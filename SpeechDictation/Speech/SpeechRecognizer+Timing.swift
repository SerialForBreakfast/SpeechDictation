//
//  SpeechRecognizer+Timing.swift
//  SpeechDictation
//
//  Created by AI Assistant on 12/19/24.
//

import Foundation
import Speech
import AVFoundation

/// Extension to SpeechRecognizer for capturing timing data with millisecond precision
/// Integrates with TimingDataManager to store transcription segments with precise timing information
extension SpeechRecognizer {
    
    /// Starts transcription with timing data capture
    /// - Parameter sessionId: Optional session ID for timing data management
    func startTranscribingWithTiming(sessionId: String? = nil) {
        print("Starting transcription with timing data...")
        
        // Start timing data session on main queue since TimingDataManager is @MainActor
        DispatchQueue.main.async {
            _ = TimingDataManager.shared.startSession(sessionId: sessionId)
        }
        
        // If a monitoring engine is already running, stop and reset it before starting a
        // fresh engine configured for speech recognition.
        if let engine = audioEngine {
            engine.stop()
            engine.inputNode.removeTap(onBus: 0)
        }

        audioEngine = AVAudioEngine()
        
        speechRecognizer = SFSpeechRecognizer()
        request = SFSpeechAudioBufferRecognitionRequest()
        
        guard let request = request else {
            print("Unable to create a SFSpeechAudioBufferRecognitionRequest object")
            return
        }
        
        guard let inputNode = audioEngine?.inputNode else {
            print("Audio engine has no input node")
            return
        }
        
        request.shouldReportPartialResults = true
        if #available(iOS 16.0, *) {
            request.addsPunctuation = true
        }
        // SECURITY: Enforce on-device recognition for privacy and security
        // This ensures all speech processing happens locally on the device
        request.requiresOnDeviceRecognition = true
        
        // Store session start time for timing calculations
        let sessionStartTime = Date()
        
        recognitionTask = speechRecognizer?.recognitionTask(with: request) { [weak self] result, error in
            if let result = result {
                DispatchQueue.main.async {
                    self?.transcribedText = result.bestTranscription.formattedString
                    self?.processTimingData(result: result, sessionStartTime: sessionStartTime)
                    print("Transcription result with timing: \(result.bestTranscription.formattedString)")
                }
            }
            
            if let error = error {
                let nsError = error as NSError
                print("Recognition error: \(error)")
                print("Error domain: \(nsError.domain), code: \(nsError.code)")
                
                // Specific handling for error 1101 (service unavailable)
                if nsError.domain == "kAFAssistantErrorDomain" && nsError.code == 1101 {
                    DispatchQueue.main.async {
                        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
                        print("CRITICAL: Speech recognition service unavailable (Error 1101)")
                        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
                        print("Possible causes:")
                        print("  1. Language pack not downloaded for on-device recognition")
                        print("  2. Speech recognition service crashed")
                        print("  3. Low device storage (service disabled)")
                        print("  4. iOS bug - device needs restart")
                        print("")
                        print("Solution:")
                        print("  Go to: Settings > General > Keyboard > Dictation")
                        print("  Enable: 'On-Device Dictation'")
                        print("  Download: Language pack for your language")
                        print("  Alternative: Restart device to reset speech service")
                        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
                    }
                }
                
                self?.stopTranscribingWithTiming()
            }
        }
        
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        
        // Validate the format is supported before installing tap
        guard recordingFormat.sampleRate > 0 && recordingFormat.channelCount > 0 else {
            print("Invalid recording format detected: sampleRate=\(recordingFormat.sampleRate), channels=\(recordingFormat.channelCount)")
            print("Skipping audio tap installation due to invalid format")
            return
        }
        
        inputNode.removeTap(onBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, time in
            self.processAudioBuffer(buffer: buffer)
            self.request?.append(buffer)
        }
        
        audioEngine?.prepare()
        
        do {
            try audioEngine?.start()
            print("Audio engine started with timing data capture")
        } catch {
            print("Audio engine failed to start: \(error)")
            #if targetEnvironment(simulator)
            // In simulator, we'll continue anyway for testing even if audio engine fails
            print("Continuing in simulator despite audio engine failure")
            #else
            // On real device, this is a critical error
            print("Audio engine failure on real device")
            #endif
        }
        
        adjustVolume()
    }
    
    /// Stops transcription and saves timing data
    /// - Parameter audioFileURL: URL to the recorded audio file (optional)
    func stopTranscribingWithTiming(audioFileURL: URL? = nil) {
        print("Stopping transcription with timing data...")
        
        audioEngine?.stop()
        audioEngine?.inputNode.removeTap(onBus: 0)
        
        request?.endAudio()
        recognitionTask?.cancel()
        
        request = nil
        recognitionTask = nil
        audioEngine = nil
        
        // Stop timing data session on main queue since TimingDataManager is @MainActor
        DispatchQueue.main.async {
            TimingDataManager.shared.stopSession(audioFileURL: audioFileURL)
        }
    }
    
    /// Processes timing data from speech recognition results
    /// - Parameters:
    ///   - result: Speech recognition result
    ///   - sessionStartTime: Start time of the recording session
    private func processTimingData(result: SFSpeechRecognitionResult, sessionStartTime: Date) {
        let transcription = result.bestTranscription
        
        // Process each segment with timing information
        for segment in transcription.segments {
            let startTime = segment.timestamp
            let endTime = segment.timestamp + segment.duration
            let confidence = segment.confidence
            let text = segment.substring
            
            // Add segment to timing data manager on main queue since TimingDataManager is @MainActor
            DispatchQueue.main.async {
                TimingDataManager.shared.addSegment(
                    text: text,
                    startTime: startTime,
                    endTime: endTime,
                    confidence: confidence
                )
            }
        }
    }
    
    /// Gets the current session from timing data manager
    /// - Returns: Current audio recording session, or nil if none active
    func getCurrentSession() -> AudioRecordingSession? {
        return TimingDataManager.shared.currentSession
    }
    
    /// Gets all segments for the current session
    /// - Returns: Array of transcription segments with timing data
    func getCurrentSegments() -> [TranscriptionSegment] {
        return TimingDataManager.shared.segments
    }
    
    /// Gets the segment at a specific time position
    /// - Parameter time: Time in seconds from session start
    /// - Returns: The segment at that time, or nil if not found
    func getSegmentAtTime(_ time: TimeInterval) -> TranscriptionSegment? {
        return TimingDataManager.shared.getSegmentAtTime(time)
    }
    
    /// Gets all segments within a time range
    /// - Parameters:
    ///   - startTime: Start time in seconds
    ///   - endTime: End time in seconds
    /// - Returns: Array of segments within the time range
    func getSegmentsInRange(startTime: TimeInterval, endTime: TimeInterval) -> [TranscriptionSegment] {
        return TimingDataManager.shared.getSegmentsInRange(startTime: startTime, endTime: endTime)
    }
    
    /// Exports timing data in the specified format
    /// - Parameters:
    ///   - session: The session to export
    ///   - format: The export format
    /// - Returns: The exported content as a string
    func exportTimingData(session: AudioRecordingSession, format: ExportManager.TimingExportFormat) -> String {
        return TimingDataManager.shared.exportTimingData(session: session, format: format)
    }
    
    /// Gets all saved sessions
    /// - Returns: Array of all saved sessions
    func getAllSessions() -> [AudioRecordingSession] {
        return TimingDataManager.shared.getAllSessions()
    }
    
    /// Loads a session from persistent storage
    /// - Parameter sessionId: The session ID to load
    /// - Returns: The loaded session, or nil if not found
    func loadSession(sessionId: String) -> AudioRecordingSession? {
        return TimingDataManager.shared.loadSession(sessionId: sessionId)
    }
    
    /// Deletes a session
    /// - Parameter sessionId: The session ID to delete
    /// - Returns: True if deletion was successful
    func deleteSession(sessionId: String) -> Bool {
        return TimingDataManager.shared.deleteSession(sessionId: sessionId)
    }
} 