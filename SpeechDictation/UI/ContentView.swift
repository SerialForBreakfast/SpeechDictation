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
    @State private var isRecording: Bool = false
    @State private var showShareOptions: Bool = false
    @State private var shareItems: [Any] = []
    @State private var showShareSheet: Bool = false
    @State private var shareType: ShareType? = nil

    enum ShareType {
        case transcript
        case recording
        case both
    }

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
                    if self.isRecording {
                        self.speechRecognizer.stopTranscribing()
                    } else {
                        self.speechRecognizer.startTranscribing()
                    }
                    self.isRecording.toggle()
                }) {
                    Text(isRecording ? "Stop Recording" : "Start Recording")
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

                Button(action: {
                    self.showShareOptions = true
                }) {
                    Text("Share")
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
        .alert(isPresented: $showShareOptions) {
            Alert(
                title: Text("Share"),
                message: Text("Choose what you want to share"),
                primaryButton: .default(Text("Share Transcript")) {
                    shareType = .transcript
                    showShareSheet = true
                },
                secondaryButton: .default(Text("Share URL mp3 file")) {
                    shareType = .recording
                    showShareSheet = true
                }
            )
        }
        .sheet(isPresented: $showShareSheet) {
            if let shareType = shareType {
                ShareSheet(items: shareItemsForType(shareType))
            }
        }
    }

    private func shareItemsForType(_ shareType: ShareType) -> [Any] {
        switch shareType {
        case .transcript:
            return [speechRecognizer.transcribedText]
        case .recording:
            if let fileURL = fileURL {
                return [fileURL]
            }
            return []
        case .both:
            if let fileURL = fileURL {
                return [speechRecognizer.transcribedText, fileURL]
            }
            return [speechRecognizer.transcribedText]
        }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    var items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    ContentView()
}
