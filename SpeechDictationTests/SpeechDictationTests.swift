//
//  SpeechDictationTests.swift
//  SpeechDictationTests
//
//  Created by Joseph McCraw on 6/25/24.
//

//import Testing
import XCTest
import AVFoundation
@testable import SpeechDictation

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
    
//    func testAudioSessionConfiguration() {
//        speechRecognizer.configureAudioSession()
//        
//        let audioSession = AVAudioSession.sharedInstance()
//        XCTAssertEqual(audioSession.category, .playAndRecord)
//        XCTAssertEqual(audioSession.mode, .default)
//        XCTAssertTrue(audioSession.isOtherAudioPlaying)
//    }
    
    func testStartTranscribingSetsUpAudioEngine() {
        speechRecognizer.startTranscribing()
        
        XCTAssertNotNil(speechRecognizer.audioEngine)
        XCTAssertNotNil(speechRecognizer.speechRecognizer)
        XCTAssertNotNil(speechRecognizer.request)
        XCTAssertTrue(speechRecognizer.audioEngine!.isRunning)
    }
    
    func testStopTranscribingStopsAudioEngine() {
        speechRecognizer.startTranscribing()
        speechRecognizer.stopTranscribing()
        
        XCTAssertNil(speechRecognizer.audioEngine)
        XCTAssertNil(speechRecognizer.request)
        XCTAssertNil(speechRecognizer.recognitionTask)
    }

//    func testWaveformUpdates() {
//        speechRecognizer.startTranscribing()
//
//        let sampleBuffer = AVAudioPCMBuffer(pcmFormat: AVAudioFormat(standardFormatWithSampleRate: 44100.0, channels: 1)!, frameCapacity: 1024)!
//        sampleBuffer.frameLength = 1024
//        for i in 0..<1024 {
//            sampleBuffer.floatChannelData?.pointee[i] = Float(i) / 1024.0
//        }
//
//        speechRecognizer.processAudioBuffer(buffer: sampleBuffer)
//
//        XCTAssertFalse(speechRecognizer.audioSamples.isEmpty)
//    }
    
//    func testTranscriptionWorks() {
//        let expectation = self.expectation(description: "Transcription works")
//
//        speechRecognizer.transcribeAudioFile(from: URL(string: "https://example.com/test.m4a")!)
//
//        DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
//            XCTAssertFalse(self.speechRecognizer.transcribedText.isEmpty)
//            expectation.fulfill()
//        }
//
//        waitForExpectations(timeout: 15, handler: nil)
//    }
}
