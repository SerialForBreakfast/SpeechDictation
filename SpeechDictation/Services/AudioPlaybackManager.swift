//
//  AudioPlaybackManager.swift
//  SpeechDictation
//
//  Created by AI Assistant on 12/19/24.
//

import Foundation
import AVFoundation
import Combine

/// Service responsible for synchronized audio/text playback
/// Handles audio playback with text highlighting and seek-to-text functionality
class AudioPlaybackManager: NSObject, ObservableObject { // Inherit NSObject for AVAudioPlayerDelegate conformance
    static let shared = AudioPlaybackManager()
    
    @Published private(set) var playbackState: PlaybackState = .stopped
    @Published private(set) var currentTime: TimeInterval = 0
    @Published private(set) var duration: TimeInterval = 0
    @Published private(set) var currentSegment: TranscriptionSegment?
    @Published private(set) var playbackSpeed: PlaybackSpeed = .normal
    
    private var audioPlayer: AVAudioPlayer?
    private var playbackTimer: Timer?
    private var currentSession: AudioRecordingSession?
    private var segments: [TranscriptionSegment] = []
    private var cancellables = Set<AnyCancellable>()
    
    private override init() {
        super.init()
        setupAudioSession()
    }
    
    // MARK: - Playback Control
    
    /// Loads audio file and session for playback
    /// - Parameters:
    ///   - audioURL: URL to the audio file
    ///   - session: Audio recording session with timing data
    func loadAudioForPlayback(audioURL: URL, session: AudioRecordingSession) {
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: audioURL)
            audioPlayer?.delegate = self
            audioPlayer?.prepareToPlay()
            
            currentSession = session
            segments = session.segments
            duration = audioPlayer?.duration ?? 0
            currentTime = 0
            currentSegment = nil
            
            print("Loaded audio for playback: \(audioURL.lastPathComponent)")
        } catch {
            print("Error loading audio for playback: \(error)")
        }
    }
    
    /// Starts or resumes playback
    func play() {
        guard let player = audioPlayer, !player.isPlaying else { return }
        
        do {
            try AVAudioSession.sharedInstance().setActive(true)
            player.play()
            playbackState = .playing
            startPlaybackTimer()
            print("Started audio playback")
        } catch {
            print("Error starting playback: \(error)")
        }
    }
    
    /// Pauses playback
    func pause() {
        audioPlayer?.pause()
        playbackState = .paused
        stopPlaybackTimer()
        print("Paused audio playback")
    }
    
    /// Stops playback and resets to beginning
    func stop() {
        audioPlayer?.stop()
        audioPlayer?.currentTime = 0
        playbackState = .stopped
        currentTime = 0
        currentSegment = nil
        stopPlaybackTimer()
        print("Stopped audio playback")
    }
    
    /// Seeks to a specific time position
    /// - Parameter time: Time in seconds
    func seekToTime(_ time: TimeInterval) {
        guard let player = audioPlayer else { return }
        
        let clampedTime = max(0, min(time, duration))
        player.currentTime = clampedTime
        currentTime = clampedTime
        updateCurrentSegment()
        
        print("Seeked to time: \(clampedTime)s")
    }
    
    /// Seeks to the beginning of a specific segment
    /// - Parameter segment: The segment to seek to
    func seekToSegment(_ segment: TranscriptionSegment) {
        seekToTime(segment.startTime)
    }
    
    /// Seeks to the text position (tap text to jump to audio position)
    /// - Parameter text: Text to search for
    /// - Returns: True if text was found and playback jumped to that position
    func seekToText(_ text: String) -> Bool {
        guard let segment = segments.first(where: { $0.text.localizedCaseInsensitiveContains(text) }) else {
            return false
        }
        
        seekToSegment(segment)
        return true
    }
    
    /// Sets playback speed
    /// - Parameter speed: Playback speed
    func setPlaybackSpeed(_ speed: PlaybackSpeed) {
        playbackSpeed = speed
        audioPlayer?.rate = Float(speed.rawValue)
        print("Set playback speed to: \(speed.displayName)")
    }
    
    // MARK: - Segment Navigation
    
    /// Goes to the next segment
    func nextSegment() {
        guard let currentSegment = currentSegment,
              let currentIndex = segments.firstIndex(where: { $0.id == currentSegment.id }),
              currentIndex + 1 < segments.count else {
            return
        }
        
        let nextSegment = segments[currentIndex + 1]
        seekToSegment(nextSegment)
    }
    
    /// Goes to the previous segment
    func previousSegment() {
        guard let currentSegment = currentSegment,
              let currentIndex = segments.firstIndex(where: { $0.id == currentSegment.id }),
              currentIndex > 0 else {
            return
        }
        
        let previousSegment = segments[currentIndex - 1]
        seekToSegment(previousSegment)
    }
    
    /// Gets the segment at the current playback position
    /// - Returns: Current segment, or nil if none found
    func getCurrentSegment() -> TranscriptionSegment? {
        return currentSegment
    }
    
    /// Gets all segments within the current playback window
    /// - Parameter windowSize: Size of the window in seconds (default: 10 seconds)
    /// - Returns: Array of segments within the window
    func getSegmentsInCurrentWindow(windowSize: TimeInterval = 10.0) -> [TranscriptionSegment] {
        let windowStart = max(0, currentTime - windowSize / 2)
        let windowEnd = min(duration, currentTime + windowSize / 2)
        
        return segments.filter { segment in
            segment.startTime <= windowEnd && segment.endTime >= windowStart
        }
    }
    
    // MARK: - Private Methods
    
    private func setupAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default)
            try session.setActive(true)
            print("Audio session configured for playback")
        } catch {
            print("Error setting up audio session: \(error)")
        }
    }
    
    private func startPlaybackTimer() {
        playbackTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            DispatchQueue.main.async {
                self?.updatePlaybackProgress()
            }
        }
    }
    
    private func stopPlaybackTimer() {
        playbackTimer?.invalidate()
        playbackTimer = nil
    }
    
    private func updatePlaybackProgress() {
        guard let player = audioPlayer else { return }
        
        currentTime = player.currentTime
        updateCurrentSegment()
    }
    
    private func updateCurrentSegment() {
        // Find the segment that contains the current playback time
        currentSegment = segments.first { segment in
            currentTime >= segment.startTime && currentTime <= segment.endTime
        }
    }
    
    /// Formats current time for display
    /// - Returns: Formatted time string
    func getFormattedCurrentTime() -> String {
        return formatTime(currentTime)
    }
    
    /// Formats duration for display
    /// - Returns: Formatted duration string
    func getFormattedDuration() -> String {
        return formatTime(duration)
    }
    
    /// Formats time for display
    /// - Parameter time: Time in seconds
    /// - Returns: Formatted time string
    private func formatTime(_ time: TimeInterval) -> String {
        let hours = Int(time) / 3600
        let minutes = (Int(time) % 3600) / 60
        let seconds = Int(time) % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
}

// MARK: - AVAudioPlayerDelegate

extension AudioPlaybackManager: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        DispatchQueue.main.async {
            self.playbackState = .stopped
            self.currentTime = 0
            self.currentSegment = nil
            self.stopPlaybackTimer()
            print("Audio playback finished")
        }
    }
    
    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        DispatchQueue.main.async {
            self.playbackState = .stopped
            print("Audio playback decode error: \(error?.localizedDescription ?? "Unknown error")")
        }
    }
} 