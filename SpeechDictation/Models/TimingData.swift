//
//  TimingData.swift
//  SpeechDictation
//
//  Created by AI Assistant on 12/19/24.
//

import Foundation
import Speech

/// Represents a single transcribed segment with precise timing information
struct TranscriptionSegment: Codable, Identifiable {
    var id = UUID()
    let text: String
    let startTime: TimeInterval
    let endTime: TimeInterval
    let confidence: Float
    
    /// Duration of this segment in seconds
    var duration: TimeInterval {
        return endTime - startTime
    }
    
    /// Formatted start time for display (HH:MM:SS.mmm)
    var formattedStartTime: String {
        return formatTime(startTime)
    }
    
    /// Formatted end time for display (HH:MM:SS.mmm)
    var formattedEndTime: String {
        return formatTime(endTime)
    }
    
    /// Formatted duration for display
    var formattedDuration: String {
        return formatTime(duration)
    }
    
    private func formatTime(_ timeInterval: TimeInterval) -> String {
        let hours = Int(timeInterval) / 3600
        let minutes = (Int(timeInterval) % 3600) / 60
        let seconds = Int(timeInterval) % 60
        let milliseconds = Int((timeInterval.truncatingRemainder(dividingBy: 1)) * 1000)
        
        if hours > 0 {
            return String(format: "%02d:%02d:%03d", hours, minutes, seconds, milliseconds)
        } else {
            return String(format: "%02d:%02d.%03d", minutes, seconds, milliseconds)
        }
    }
}

/// Represents a complete audio recording session with timing data
struct AudioRecordingSession: Codable, Identifiable {
    var id = UUID()
    let sessionId: String
    let startTime: Date
    let endTime: Date?
    let audioFileURL: URL?
    let segments: [TranscriptionSegment]
    let totalDuration: TimeInterval
    let wordCount: Int
    
    /// Session duration in seconds
    var sessionDuration: TimeInterval {
        if let endTime = endTime {
            return endTime.timeIntervalSince(startTime)
        }
        return Date().timeIntervalSince(startTime)
    }
    
    /// Average words per minute
    var wordsPerMinute: Double {
        let durationInMinutes = sessionDuration / 60.0
        return durationInMinutes > 0 ? Double(wordCount) / durationInMinutes : 0.0
    }
    
    /// Full transcription text
    var fullText: String {
        return segments.map { $0.text }.joined(separator: " ")
    }
    
    /// Formatted session duration
    var formattedDuration: String {
        let hours = Int(sessionDuration) / 3600
        let minutes = (Int(sessionDuration) % 3600) / 60
        let seconds = Int(sessionDuration) % 60
        
        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
}

/// Playback state for synchronized audio/text playback
enum PlaybackState {
    case stopped
    case playing
    case paused
    case seeking
}

/// Playback speed options
enum PlaybackSpeed: Double, CaseIterable {
    case slow = 0.5
    case normal = 1.0
    case fast = 1.5
    case veryFast = 2.0
    
    var displayName: String {
        switch self {
        case .slow: return "0.5x"
        case .normal: return "1.0x"
        case .fast: return "1.5x"
        case .veryFast: return "2.0x"
        }
    }
} 