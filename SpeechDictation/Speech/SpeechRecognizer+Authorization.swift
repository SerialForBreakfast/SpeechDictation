//
//  SpeechRecognizer+Authorization.swift
//  SpeechDictation
//
//  Created by Joseph McCraw on 6/29/24.
//

import Speech

extension SpeechRecognizer {
    func requestAuthorization() {
        SFSpeechRecognizer.requestAuthorization { authStatus in
            DispatchQueue.main.async {
                switch authStatus {
                case .authorized:
                    AppLog.info(.transcription, "Speech recognition authorized")
                case .denied:
                    self.transcribedText = "Speech recognition authorization denied"
                case .restricted:
                    self.transcribedText = "Speech recognition restricted on this device"
                case .notDetermined:
                    self.transcribedText = "Speech recognition not authorized"
                @unknown default:
                    fatalError("Unknown authorization status")
                }
            }
        }
        
        AVAudioSession.sharedInstance().requestRecordPermission { granted in
            DispatchQueue.main.async {
                if granted {
                    AppLog.info(.recording, "Microphone access granted")
                } else {
                    self.transcribedText = "Microphone access denied"
                }
            }
        }
    }
    
}
