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
        ZStack {
            VStack {
                ScrollView {
                    Text(viewModel.transcribedText)
                        .font(.system(size: viewModel.fontSize))
                        .padding()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(backgroundColor)
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
                        Text(viewModel.isRecording ? "Stop Listening" : "Start Listening")
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
                }
                .padding()
            }
            .padding()

            if viewModel.showSettings {
                Color.black.opacity(0.5)
                    .edgesIgnoringSafeArea(.all)
                    .onTapGesture {
                        self.viewModel.showSettings.toggle()
                    }

                SettingsView(viewModel: viewModel)
                    .background(Color(UIColor.systemBackground))
                    .cornerRadius(10)
                    .shadow(radius: 10)
                    .padding()
                    .transition(.move(edge: .bottom))
                    .animation(.easeInOut)
            }
        }
        .onAppear {
            applyTheme()
        }
        .onChange(of: viewModel.theme) { _ in
            applyTheme()
        }
    }

    private var backgroundColor: Color {
        switch viewModel.theme {
        case .light:
            return Color.white
        case .dark:
            return Color.black
        case .highContrast:
            return Color.yellow
        }
    }

    private func applyTheme() {
        switch viewModel.theme {
        case .light:
            UIApplication.shared.windows.first?.overrideUserInterfaceStyle = .light
        case .dark:
            UIApplication.shared.windows.first?.overrideUserInterfaceStyle = .dark
        case .highContrast:
            // For high contrast, you might want to set a specific override, if necessary.
            break
        }
    }
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
