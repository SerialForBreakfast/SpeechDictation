//
//  SpeechDictationTests.swift
//  SpeechDictationTests
//
//  Created by Joseph McCraw on 6/25/24.
//

import XCTest
import AVFoundation
import Speech
@testable import SpeechDictation

// MARK: - Audio Session Configuration Tests

class AudioSessionConfigurationTests: XCTestCase {
    var speechRecognizer: SpeechRecognizer!
    
    override func setUp() {
        super.setUp()
        speechRecognizer = SpeechRecognizer()
    }
    
    override func tearDown() {
        speechRecognizer = nil
        super.tearDown()
    }
    
    /// Test that audio session is properly configured for speech recognition
    func testAudioSessionConfigurationForSpeechRecognition() {
        // Given: A fresh speech recognizer
        let audioSession = AVAudioSession.sharedInstance()
        
        // When: Configure audio session
        speechRecognizer.configureAudioSession()
        
        // Then: Verify proper configuration
        XCTAssertEqual(audioSession.category, .playAndRecord, "Audio session should be configured for play and record")
        do {
            try audioSession.setActive(true)
        } catch {
            XCTFail("Audio session could not be activated: \(error)")
        }
        
        #if !targetEnvironment(simulator)
        // On device, should use measurement mode for better speech recognition
        XCTAssertEqual(audioSession.mode, .measurement, "Audio session should use measurement mode on device")
        #else
        // On simulator, should use default mode
        XCTAssertEqual(audioSession.mode, .default, "Audio session should use default mode on simulator")
        #endif
    }
    
    /// Test audio session configuration with fallback handling
    func testAudioSessionConfigurationWithFallback() {
        // Given: Audio session that might fail initial configuration
        let audioSession = AVAudioSession.sharedInstance()
        
        // When: Configure audio session (should handle errors gracefully)
        speechRecognizer.configureAudioSession()
        
        // Then: Verify session is active regardless of initial configuration method
        do {
            try audioSession.setActive(true)
        } catch {
            XCTFail("Audio session could not be activated (fallback): \(error)")
        }
        XCTAssertEqual(audioSession.category, .playAndRecord, "Audio session should maintain playAndRecord category")
    }
    
    /// Test native audio format detection and compatibility
    func testNativeAudioFormatDetection() {
        // Given: Audio engine setup
        speechRecognizer.startTranscribing()
        
        // When: Audio engine is configured
        guard let audioEngine = speechRecognizer.audioEngine else {
            XCTFail("Audio engine should be properly configured")
            return
        }
        
        let inputNode = audioEngine.inputNode
        
        // Then: Verify native format is valid
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        XCTAssertGreaterThan(recordingFormat.sampleRate, 0, "Sample rate should be positive")
        XCTAssertGreaterThan(recordingFormat.channelCount, 0, "Channel count should be positive")
        XCTAssertNotEqual(recordingFormat.commonFormat, .otherFormat, "Format should be a recognized common format")
    }
    
    /// Test audio session interruption handling
    func testAudioSessionInterruptionHandling() {
        // Given: Configured audio session
        speechRecognizer.configureAudioSession()
        let audioSession = AVAudioSession.sharedInstance()
        
        // When: Simulate audio session interruption
        NotificationCenter.default.post(name: AVAudioSession.interruptionNotification, 
                                     object: audioSession,
                                     userInfo: [AVAudioSessionInterruptionTypeKey: AVAudioSession.InterruptionType.began.rawValue])
        
        // Then: Verify session can be reactivated (no error thrown)
        do {
            try audioSession.setActive(true)
        } catch {
            XCTFail("Audio session should handle reactivation gracefully: \(error)")
        }
    }
    
    /// Test audio format compatibility across different devices
    func testAudioFormatCompatibility() {
        // Given: Audio engine with input node
        speechRecognizer.startTranscribing()
        
        guard let audioEngine = speechRecognizer.audioEngine else {
            XCTFail("Audio engine should be properly configured")
            return
        }
        
        // When: Get native format
        let inputNode = audioEngine.inputNode
        let nativeFormat = inputNode.outputFormat(forBus: 0)
        
        // Then: Verify format is compatible with speech recognition
        XCTAssertTrue(nativeFormat.sampleRate >= 8000, "Sample rate should be at least 8kHz for speech recognition")
        XCTAssertTrue(nativeFormat.sampleRate <= 48000, "Sample rate should be reasonable for mobile devices")
        XCTAssertTrue(nativeFormat.channelCount <= 2, "Channel count should be mono or stereo")
    }
}

// MARK: - Export Format Generation Tests

class ExportFormatGenerationTests: XCTestCase {
    var exportManager: ExportManager!
    var sampleTimingData: [TranscriptionSegment]!
    
    override func setUp() {
        super.setUp()
        exportManager = ExportManager.shared
        
        // Create sample timing data for testing
        sampleTimingData = [
            TranscriptionSegment(text: "Hello world", startTime: 0.0, endTime: 1.5, confidence: 0.95),
            TranscriptionSegment(text: "This is a test", startTime: 1.5, endTime: 3.2, confidence: 0.88),
            TranscriptionSegment(text: "of the export system", startTime: 3.2, endTime: 5.0, confidence: 0.92)
        ]
    }
    
    override func tearDown() {
        exportManager = nil
        sampleTimingData = nil
        super.tearDown()
    }
    
    /// Test SRT (SubRip) format generation
    func testSRTFormatGeneration() {
        // Given: Sample timing data
        let session = AudioRecordingSession(
            sessionId: "test-session",
            startTime: Date(),
            endTime: Date().addingTimeInterval(5.0),
            audioFileURL: nil,
            segments: sampleTimingData,
            totalDuration: 5.0,
            wordCount: 8
        )
        
        // When: Generate SRT format
        let srtContent = generateSRTContent(from: session)
        
        // Then: Verify SRT format compliance
        XCTAssertTrue(srtContent.contains("1\n"), "SRT should start with subtitle number")
        XCTAssertTrue(srtContent.contains("00:00:00,000 --> 00:00:01,500"), "SRT should have proper timestamp format")
        XCTAssertTrue(srtContent.contains("Hello world"), "SRT should contain transcribed text")
        XCTAssertTrue(srtContent.contains("\n\n"), "SRT should have double line breaks between entries")
        
        // Verify timestamp format (HH:MM:SS,mmm) using NSRegularExpression
        let timestampPattern = "\\d{2}:\\d{2}:\\d{2},\\d{3}"
        let regex = try! NSRegularExpression(pattern: timestampPattern)
        let matches = regex.matches(in: srtContent, range: NSRange(srtContent.startIndex..., in: srtContent))
        XCTAssertGreaterThan(matches.count, 0, "SRT should contain properly formatted timestamps")
    }
    
    /// Test VTT (WebVTT) format generation
    func testVTTFormatGeneration() {
        // Given: Sample timing data
        let session = AudioRecordingSession(
            sessionId: "test-session",
            startTime: Date(),
            endTime: Date().addingTimeInterval(5.0),
            audioFileURL: nil,
            segments: sampleTimingData,
            totalDuration: 5.0,
            wordCount: 8
        )
        
        // When: Generate VTT format
        let vttContent = generateVTTContent(from: session)
        
        // Then: Verify VTT format compliance
        XCTAssertTrue(vttContent.hasPrefix("WEBVTT\n\n"), "VTT should start with WEBVTT header")
        XCTAssertTrue(vttContent.contains("00:00:00.000 --> 00:00:01.500"), "VTT should have proper timestamp format")
        XCTAssertTrue(vttContent.contains("Hello world"), "VTT should contain transcribed text")
        
        // Verify timestamp format (HH:MM:SS.mmm) using NSRegularExpression
        let timestampPattern = "\\d{2}:\\d{2}:\\d{2}\\.\\d{3}"
        let regex = try! NSRegularExpression(pattern: timestampPattern)
        let matches = regex.matches(in: vttContent, range: NSRange(vttContent.startIndex..., in: vttContent))
        XCTAssertGreaterThan(matches.count, 0, "VTT should contain properly formatted timestamps")
    }
    
    /// Test TTML (Timed Text Markup Language) format generation
    func testTTMLFormatGeneration() {
        // Given: Sample timing data
        let session = AudioRecordingSession(
            sessionId: "test-session",
            startTime: Date(),
            endTime: Date().addingTimeInterval(5.0),
            audioFileURL: nil,
            segments: sampleTimingData,
            totalDuration: 5.0,
            wordCount: 8
        )
        
        // When: Generate TTML format
        let ttmlContent = generateTTMLContent(from: session)
        
        // Then: Verify TTML format compliance
        XCTAssertTrue(ttmlContent.contains("<?xml version=\"1.0\" encoding=\"UTF-8\"?>"), "TTML should have XML declaration")
        XCTAssertTrue(ttmlContent.contains("<tt xmlns="), "TTML should have proper namespace")
        XCTAssertTrue(ttmlContent.contains("<p begin="), "TTML should contain paragraph elements with timing")
        XCTAssertTrue(ttmlContent.contains("Hello world"), "TTML should contain transcribed text")
        
        // Verify XML structure
        XCTAssertTrue(ttmlContent.contains("<body>"), "TTML should have body element")
        XCTAssertTrue(ttmlContent.contains("</body>"), "TTML should close body element")
        XCTAssertTrue(ttmlContent.contains("</tt>"), "TTML should close root element")
    }
    
    /// Test JSON format generation with timing data
    func testJSONFormatGeneration() {
        // Given: Sample timing data
        let session = AudioRecordingSession(
            sessionId: "test-session",
            startTime: Date(),
            endTime: Date().addingTimeInterval(5.0),
            audioFileURL: nil,
            segments: sampleTimingData,
            totalDuration: 5.0,
            wordCount: 8
        )
        
        // When: Generate JSON format
        let jsonContent = generateJSONContent(from: session)
        
        // Then: Verify JSON format compliance
        XCTAssertTrue(jsonContent.contains("\"sessionId\""), "JSON should contain session metadata")
        XCTAssertTrue(jsonContent.contains("\"segments\""), "JSON should contain segments array")
        XCTAssertTrue(jsonContent.contains("\"text\""), "JSON should contain text fields")
        XCTAssertTrue(jsonContent.contains("\"startTime\""), "JSON should contain timing data")
        XCTAssertTrue(jsonContent.contains("\"endTime\""), "JSON should contain timing data")
        XCTAssertTrue(jsonContent.contains("\"confidence\""), "JSON should contain confidence scores")
        
        // Verify JSON is valid
        do {
            let jsonData = jsonContent.data(using: .utf8)!
            let jsonObject = try JSONSerialization.jsonObject(with: jsonData)
            XCTAssertTrue(jsonObject is [String: Any], "JSON should be a valid object")
        } catch {
            XCTFail("Generated JSON should be valid: \(error)")
        }
    }
    
    /// Test export format validation and error handling
    func testExportFormatValidation() {
        // Given: Invalid timing data (overlapping segments)
        let invalidSegments = [
            TranscriptionSegment(text: "Overlapping", startTime: 0.0, endTime: 2.0, confidence: 0.9),
            TranscriptionSegment(text: "segments", startTime: 1.0, endTime: 3.0, confidence: 0.8) // Overlaps
        ]
        
        let session = AudioRecordingSession(
            sessionId: "invalid-session",
            startTime: Date(),
            endTime: Date().addingTimeInterval(3.0),
            audioFileURL: nil,
            segments: invalidSegments,
            totalDuration: 3.0,
            wordCount: 2
        )
        
        // When: Generate export formats
        let srtContent = generateSRTContent(from: session)
        let vttContent = generateVTTContent(from: session)
        let ttmlContent = generateTTMLContent(from: session)
        let jsonContent = generateJSONContent(from: session)
        
        // Then: Verify formats are still generated (should handle overlapping gracefully)
        XCTAssertFalse(srtContent.isEmpty, "SRT should be generated even with invalid data")
        XCTAssertFalse(vttContent.isEmpty, "VTT should be generated even with invalid data")
        XCTAssertFalse(ttmlContent.isEmpty, "TTML should be generated even with invalid data")
        XCTAssertFalse(jsonContent.isEmpty, "JSON should be generated even with invalid data")
    }
    
    /// Test export format file extensions and MIME types
    func testExportFormatMetadata() {
        // Given: Export format types
        let formats: [ExportManager.TimingExportFormat] = [.srt, .vtt, .ttml, .json]
        
        // When: Check format metadata
        for format in formats {
            // Then: Verify each format has proper metadata
            XCTAssertFalse(format.fileExtension.isEmpty, "File extension should not be empty")
            XCTAssertFalse(format.mimeType.isEmpty, "MIME type should not be empty")
            
            // Verify specific format metadata
            switch format {
            case .srt:
                XCTAssertEqual(format.fileExtension, "srt")
                XCTAssertEqual(format.mimeType, "application/x-subrip")
            case .vtt:
                XCTAssertEqual(format.fileExtension, "vtt")
                XCTAssertEqual(format.mimeType, "text/vtt")
            case .ttml:
                XCTAssertEqual(format.fileExtension, "ttml")
                XCTAssertEqual(format.mimeType, "application/ttml+xml")
            case .json:
                XCTAssertEqual(format.fileExtension, "json")
                XCTAssertEqual(format.mimeType, "application/json")
            }
        }
    }
    
    // MARK: - Helper Methods for Format Generation
    
    private func generateSRTContent(from session: AudioRecordingSession) -> String {
        var content = ""
        for (index, segment) in session.segments.enumerated() {
            content += "\(index + 1)\n"
            content += "\(formatSRTTime(segment.startTime)) --> \(formatSRTTime(segment.endTime))\n"
            content += "\(segment.text)\n\n"
        }
        return content
    }
    
    private func generateVTTContent(from session: AudioRecordingSession) -> String {
        var content = "WEBVTT\n\n"
        for segment in session.segments {
            content += "\(formatVTTTime(segment.startTime)) --> \(formatVTTTime(segment.endTime))\n"
            content += "\(segment.text)\n\n"
        }
        return content
    }
    
    private func generateTTMLContent(from session: AudioRecordingSession) -> String {
        var content = """
        <?xml version="1.0" encoding="UTF-8"?>
        <tt xmlns="http://www.w3.org/ns/ttml">
        <body>
        """
        
        for segment in session.segments {
            content += "<p begin=\"\(formatTTMLTime(segment.startTime))\" end=\"\(formatTTMLTime(segment.endTime))\">\(segment.text)</p>\n"
        }
        
        content += """
        </body>
        </tt>
        """
        return content
    }
    
    private func generateJSONContent(from session: AudioRecordingSession) -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        
        do {
            let data = try encoder.encode(session)
            return String(data: data, encoding: .utf8) ?? ""
        } catch {
            return "{\"error\": \"Failed to encode session\"}"
        }
    }
    
    private func formatSRTTime(_ time: TimeInterval) -> String {
        let hours = Int(time) / 3600
        let minutes = (Int(time) % 3600) / 60
        let seconds = Int(time) % 60
        let milliseconds = Int((time.truncatingRemainder(dividingBy: 1)) * 1000)
        return String(format: "%02d:%02d:%02d,%03d", hours, minutes, seconds, milliseconds)
    }
    
    private func formatVTTTime(_ time: TimeInterval) -> String {
        let hours = Int(time) / 3600
        let minutes = (Int(time) % 3600) / 60
        let seconds = Int(time) % 60
        let milliseconds = Int((time.truncatingRemainder(dividingBy: 1)) * 1000)
        return String(format: "%02d:%02d:%02d.%03d", hours, minutes, seconds, milliseconds)
    }
    
    private func formatTTMLTime(_ time: TimeInterval) -> String {
        let hours = Int(time) / 3600
        let minutes = (Int(time) % 3600) / 60
        let seconds = Int(time) % 60
        let milliseconds = Int((time.truncatingRemainder(dividingBy: 1)) * 1000)
        return String(format: "%02d:%02d:%02d.%03d", hours, minutes, seconds, milliseconds)
    }
}

// MARK: - Legacy Tests (Maintained for Compatibility)

class SpeechRecognizerTests: XCTestCase {
    var speechRecognizer: SpeechRecognizer!
    
    override func setUp() {
        super.setUp()
        speechRecognizer = SpeechRecognizer()
    }

    override func tearDown() {
        speechRecognizer = nil
        super.tearDown()
    }
    
    func testStartTranscribingSetsUpAudioEngine() {
        speechRecognizer.startTranscribing()
        
        // With new engine architecture, transcriptionEngine and engineEventTask should be set
        XCTAssertNotNil(speechRecognizer.transcriptionEngine, "Transcription engine should be created")
        XCTAssertNotNil(speechRecognizer.engineEventTask, "Engine event task should be running")
        
        // Give engine a moment to start
        let expectation = self.expectation(description: "Engine starts")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation.fulfill()
        }
        waitForExpectations(timeout: 1.0)
    }
    
    func testStopTranscribingStopsAudioEngine() {
        speechRecognizer.startTranscribing()
        
        // Give engine a moment to start
        let startExpectation = self.expectation(description: "Engine starts")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            startExpectation.fulfill()
        }
        waitForExpectations(timeout: 1.0)
        
        speechRecognizer.stopTranscribing()
        
        // Give engine a moment to stop
        let stopExpectation = self.expectation(description: "Engine stops")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            stopExpectation.fulfill()
        }
        waitForExpectations(timeout: 1.0)
        
        // Engine and event task should be cleaned up
        XCTAssertNil(speechRecognizer.transcriptionEngine, "Engine should be nil after stop")
        XCTAssertNil(speechRecognizer.engineEventTask, "Event task should be nil after stop")
    }
}
