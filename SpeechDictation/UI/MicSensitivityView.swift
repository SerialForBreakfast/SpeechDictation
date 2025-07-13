//
//  MicSensitivityView.swift
//  SpeechDictation
//
//  Created by AI Assistant on 7/1/24.
//
//  Combines mic gain slider with real-time VU meter.
//  Now supports proper dark/light mode adaptation.
//

import SwiftUI
import Foundation

struct MicSensitivityView: View {
    @ObservedObject var viewModel: SpeechRecognizerViewModel
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: 10) {
            Text("Mic Sensitivity")
                .font(.headline)
                .foregroundColor(.primary)
            
            HStack {
                Slider(value: $viewModel.volume, in: 0...100, step: 1, onEditingChanged: { _ in
                    viewModel.adjustVolume()
                })
                .accentColor(.accentColor)
                
                VUMeterView(level: viewModel.currentLevel)
                    .frame(height: 100)
                    .padding(.leading, 8)
            }
            .padding(.horizontal)
            
            HStack {
                Text("Low")
                    .foregroundColor(.secondary)
                Spacer()
                Text("High")
                    .foregroundColor(.secondary)
            }
            .font(.caption)
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