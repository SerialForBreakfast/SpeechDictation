//
//  ContentView.swift
//  SpeechDictation
//
//  Created by Joseph McCraw on 6/25/24.
//

import SwiftUI

struct ContentView: View {
    @ObservedObject var speechRecognizer = SpeechRecognizer()
    
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
