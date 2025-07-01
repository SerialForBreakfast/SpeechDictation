//
//  SettingsView.swift
//  SpeechDictation
//
//  Created by Joseph McCraw on 7/17/24.
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct SettingsView: View {
    @ObservedObject var viewModel: SpeechRecognizerViewModel

    var body: some View {
        VStack(spacing: 20) {
            // Title
            Text("Settings")
                .font(.title)
                .padding()
                .background(Color.gray.opacity(0.15))
                .cornerRadius(10)

            // Text Settings
            VStack(spacing: 10) {
                Text("Transcription Text Size")
                    .font(.headline)
                Slider(value: $viewModel.fontSize, in: 12...60)
                    .padding(.horizontal)
            }
            .padding()
            .background(Color.gray.opacity(0.15))
            .cornerRadius(10)

            // Theme Settings
            VStack(spacing: 10) {
                Text("Theme")
                    .font(.headline)
                HStack {
                    ForEach(Theme.allCases) { theme in
                        Button(action: {
                            viewModel.theme = theme
                        }) {
                            Text(theme.rawValue.capitalized)
                                .padding()
                                .background(viewModel.theme == theme ? Color.blue : Color.gray)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                    }
                }
            }
            .padding()
            .background(Color.gray.opacity(0.15))
            .cornerRadius(10)

            // Mic Sensitivity
            VStack(spacing: 10) {
                Text("Mic Sensitivity")
                    .font(.headline)
                HStack {
                    Slider(value: $viewModel.volume, in: 0...100, step: 1, onEditingChanged: { _ in
                        viewModel.adjustVolume()
                    })
                    VUMeterView(level: viewModel.currentLevel)
                        .frame(height: 100) // Fixed height for consistent appearance
                        .padding(.leading, 8)
                }
                .padding(.horizontal)
                HStack {
                    Text("Low")
                    Spacer()
                    Text("High")
                }
                .font(.caption)
                .padding(.horizontal)
            }
            .padding()
            .background(Color.gray.opacity(0.15))
            .cornerRadius(10)
        }
        .padding()
        #if canImport(UIKit)
        .background(Color(UIColor.systemBackground))
        #else
        .background(Color(NSColor.windowBackgroundColor))
        #endif
        .cornerRadius(10)
        .shadow(radius: 10)
        .padding()
        .fixedSize(horizontal: true, vertical: false) // Ensures the width fits the content
    }
}

enum Theme: String, CaseIterable, Identifiable {
    case light, dark, highContrast

    var id: String { self.rawValue }
}
