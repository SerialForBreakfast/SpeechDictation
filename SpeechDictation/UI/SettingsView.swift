//
//  SettingsView.swift
//  SpeechDictation
//
//  Created by Joseph McCraw on 7/17/24.
//
//  Main settings view that combines all setting components.
//  Now supports proper dark/light mode adaptation.
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct SettingsView: View {
    @ObservedObject var viewModel: SpeechRecognizerViewModel
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: 20) {
            Text("Settings")
                .font(.title)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
                .padding()
                .background(headerBackgroundColor)
                .cornerRadius(10)

            TextSizeSettingView(viewModel: viewModel)
            ThemeSettingView(viewModel: viewModel)
            MicSensitivityView(viewModel: viewModel)
        }
        .padding()
        .background(mainBackgroundColor)
        .cornerRadius(10)
        .shadow(color: shadowColor, radius: 10, x: 0, y: 0)
        .padding()
        .fixedSize(horizontal: true, vertical: false) // Ensures the width fits the content
    }
    
    // MARK: - Color Helpers
    
    private var headerBackgroundColor: Color {
        Color(UIColor.tertiarySystemBackground)
    }
    
    private var mainBackgroundColor: Color {
        #if canImport(UIKit)
        Color(UIColor.systemBackground)
        #else
        Color(NSColor.windowBackgroundColor)
        #endif
    }
    
    private var shadowColor: Color {
        Color.black.opacity(colorScheme == .dark ? 0.3 : 0.1)
    }
}
