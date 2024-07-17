//
//  ContentView.swift
//  SpeechDictation
//
//  Created by Joseph McCraw on 6/25/24.
//

import SwiftUI

struct ContentView: View {
    @ObservedObject var viewModel = SpeechRecognizerViewModel()

    var body: some View {
        VStack {
            ScrollView {
                Text(viewModel.transcribedText)
                    .font(.system(size: viewModel.fontSize))
                    .padding()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.white)
            .cornerRadius(10)
            .shadow(radius: 5)

            HStack {
                Button(action: {
                    if self.viewModel.isRecording {
                        self.viewModel.stopTranscribing()
                    } else {
                        self.viewModel.startTranscribing()
                    }
                }) {
                    Text(viewModel.isRecording ? "Stop Recording" : "Start Recording")
                        .font(.title2)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }

                Spacer()

                Button(action: {
                    self.viewModel.showSettings.toggle()
                }) {
                    Image(systemName: "gear")
                        .font(.title2)
                        .padding()
                        .background(Color.gray.opacity(0.2))
                        .clipShape(Circle())
                }
                .sheet(isPresented: $viewModel.showSettings) {
                    SettingsView(viewModel: viewModel)
                }
            }
            .padding()
        }
        .padding()
    }
}

struct SettingsView: View {
    @ObservedObject var viewModel: SpeechRecognizerViewModel

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Text Settings")) {
                    Slider(value: $viewModel.fontSize, in: 12...36, step: 1) {
                        Text("Font Size")
                    }
                    .padding()
                }

                Section(header: Text("Theme Settings")) {
                    Picker("Theme", selection: $viewModel.theme) {
                        Text("Light").tag(Theme.light)
                        Text("Dark").tag(Theme.dark)
                        Text("High Contrast").tag(Theme.highContrast)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding()
                }
            }
            .navigationTitle("Settings")
        }
    }
}

enum Theme: String, CaseIterable, Identifiable {
    case light, dark, highContrast

    var id: String { self.rawValue }
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
