//
//  SettingsView.swift
//  SpeechDictation
//
//  Created by Joseph McCraw on 7/17/24.
//

import SwiftUI

struct SettingsView: View {
    @ObservedObject var viewModel: SpeechRecognizerViewModel

    var body: some View {
        VStack {
            // Title
            Text("Settings")
                .font(.title)
                .padding(.top, 10) // Adjust the top padding to reduce space

            // Text Settings
            VStack {
                Text("Text Settings")
                Slider(value: $viewModel.fontSize, in: 12...36) // Example slider, replace with your binding
                    .padding()
            }
            .padding()

            // Theme Settings
            VStack {
                Text("Theme Settings")
                HStack {
                    Button("Light") { viewModel.theme = .light }
                    Button("Dark") { viewModel.theme = .dark }
                    Button("High Contrast") { viewModel.theme = .highContrast }
                }
                .padding()
            }
            .padding()
        }
        .background(Color(UIColor.systemBackground)) // Ensure the background matches the theme
        .cornerRadius(10)
        .shadow(radius: 10)
        .padding()
    }
}

enum Theme: String, CaseIterable, Identifiable {
    case light, dark, highContrast

    var id: String { self.rawValue }
}
