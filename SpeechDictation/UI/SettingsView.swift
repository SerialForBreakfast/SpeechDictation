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
