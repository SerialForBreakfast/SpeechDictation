//
//  TextSizeSettingView.swift
//  SpeechDictation
//
//  Created by AI Assistant on 7/1/24.
//
//  Displays a slider that allows users to adjust the transcription font size.
//  Persists via `SpeechRecognizerViewModel` which handles UserDefaults sync.
//  Now supports proper dark/light mode adaptation.
//

import SwiftUI
import Foundation

struct TextSizeSettingView: View {
    @ObservedObject var viewModel: SpeechRecognizerViewModel
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: 10) {
            Text("Transcription Text Size")
                .font(.headline)
                .foregroundColor(.primary)
            
            Slider(value: $viewModel.fontSize, in: 12...60)
                .accentColor(.accentColor)
                .padding(.horizontal)
        }
        .padding()
        .background(sectionBackgroundColor)
        .cornerRadius(10)
    }
    
    // MARK: - Color Helpers
    
    private var sectionBackgroundColor: Color {
        Color(UIColor.secondarySystemBackground)
    }
} 