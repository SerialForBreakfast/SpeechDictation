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
            let actualSessionId = TimingDataManager.shared.startSession(sessionId: sessionId)
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
                print("Recognition error: \(error)")
                self?.stopTranscribingWithTiming()
            }
        }
        
        let recordingFormat = inputNode.outputFormat(forBus: 0)
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