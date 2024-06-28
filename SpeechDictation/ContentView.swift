//
//  ContentView.swift
//  SpeechDictation
//
//  Created by Joseph McCraw on 6/25/24.
//

import SwiftUI

struct ContentView: View {
    @ObservedObject var speechRecognizer = SpeechRecognizer()
    //    @State private var fileURL: URL? = URL(string: "https://github.com/rafaelreis-hotmart/Audio-Sample-files/raw/master/sample.mp3")
    @State private var fileURL: URL? = URL(string: "http://traffic.libsyn.com/shitecom/KATG-2024-06-23.mp3")
    
    
    var body: some View {
        VStack {
            Text(speechRecognizer.transcribedText)
                .padding()
                .font(.largeTitle)
            
            WaveformView(samples: speechRecognizer.audioSamples)
                .frame(height: 100)
                .padding()
            
            HStack {
                Button(action: {
                    self.speechRecognizer.startTranscribing()
                }) {
                    Text("Start Recording")
                }
                .padding()
                
                Button(action: {
                    self.speechRecognizer.stopTranscribing()
                }) {
                    Text("Stop Recording")
                }
                .padding()
                Button(action: {
                    if let fileURL = fileURL {
                        self.speechRecognizer.transcribeAudioFile(from: fileURL)
                    }
                }) {
                    Text("Play File URL")
                }
                .padding()
            }
            Slider(value: $speechRecognizer.volume, in: 1...100, step: 1) {
                Text("Volume")
            }
            .padding()
            .onChange(of: speechRecognizer.volume) { newValue in
                print("Volume set to \(newValue)")
            }
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
