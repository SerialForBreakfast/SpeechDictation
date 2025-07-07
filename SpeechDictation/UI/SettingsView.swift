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
            Text("Settings")
                .font(.title)
                .padding()
                .background(Color.gray.opacity(0.15))
                .cornerRadius(10)

            TextSizeSettingView(viewModel: viewModel)
            ThemeSettingView(viewModel: viewModel)
            MicSensitivityView(viewModel: viewModel)
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
