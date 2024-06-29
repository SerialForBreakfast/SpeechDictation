//
//  ContentView.swift
//  SpeechDictation
//
//  Created by Joseph McCraw on 6/25/24.
//

import SwiftUI

struct ContentView: View {
    @ObservedObject var speechRecognizer = SpeechRecognizer()
    @State private var fileURL: URL? = URL(string: "https://chrt.fm/track/138C95/prfx.byspotify.com/e/play.podtrac.com/npr-381444908/traffic.megaphone.fm/NPR1393448199.mp3")
    //    @State private var fileURL: URL? = URL(string: "http://traffic.libsyn.com/shitecom/KATG-2024-06-23.mp3")
    
    var body: some View {
        VStack {
            ScrollView {
                Text(speechRecognizer.transcribedText)
                    .font(.largeTitle)
                    .padding()
            }
            
            WaveformView(samples: speechRecognizer.audioSamples)
                .frame(height: 100)
                .border(.blue, width: 2.0)
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
