//
//  MicSensitivityView.swift
//  SpeechDictation
//
//  Created by AI Assistant on 7/1/24.
//
//  Combines mic gain slider with real-time VU meter.
//

import SwiftUI
import Foundation

struct MicSensitivityView: View {
    @ObservedObject var viewModel: SpeechRecognizerViewModel

    var body: some View {
        VStack(spacing: 10) {
            Text("Mic Sensitivity")
                .font(.headline)
            HStack {
                Slider(value: $viewModel.volume, in: 0...100, step: 1, onEditingChanged: { _ in
                    viewModel.adjustVolume()
                })
                VUMeterView(level: viewModel.currentLevel)
                    .frame(height: 100)
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
} 