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
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
