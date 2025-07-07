//
//  TextSizeSettingView.swift
//  SpeechDictation
//
//  Created by AI Assistant on 7/1/24.
//
//  Displays a slider that allows users to adjust the transcription font size.
//  Persists via `SpeechRecognizerViewModel` which handles UserDefaults sync.
//

import SwiftUI
import Foundation

struct TextSizeSettingView: View {
    @ObservedObject var viewModel: SpeechRecognizerViewModel

    var body: some View {
        VStack(spacing: 10) {
            Text("Transcription Text Size")
                .font(.headline)
            Slider(value: $viewModel.fontSize, in: 12...60)
                .padding(.horizontal)
        }
        .padding()
        .background(Color.gray.opacity(0.15))
        .cornerRadius(10)
    }
} 