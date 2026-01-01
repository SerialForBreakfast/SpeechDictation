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
#if canImport(UIKit)
import UIKit
#endif

struct MicSensitivityView: View {
    @ObservedObject var viewModel: SpeechRecognizerViewModel
    @Environment(\.colorScheme) private var colorScheme
    private let recommendedVolume: Float = 60.0

    var body: some View {
        VStack(spacing: 10) {
            HStack {
                Text("Mic Sensitivity")
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer()
                Text("Recommended: \(Int(recommendedVolume))")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.secondary.opacity(0.15))
                    .cornerRadius(8)
                    .accessibilityLabel("Recommended mic sensitivity \(Int(recommendedVolume))")
            }
            
            HStack(alignment: .bottom, spacing: 12) {
                sliderWithRecommendedMarker
                    .onChange(of: viewModel.volume) { _ in
                        viewModel.adjustVolume()
                    }

                VStack(spacing: 6) {
                    Text("Input")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    VUMeterView(level: viewModel.currentLevel)
                        .frame(height: 100)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Input level meter")

                VStack(spacing: 6) {
                    Text("Recording")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    VUMeterView(level: viewModel.effectiveLevel)
                        .frame(height: 100)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Recording level meter")
            }
            .padding(.horizontal)
            
            Button("Use Recommended Setting") {
                viewModel.volume = recommendedVolume
                viewModel.adjustVolume()
            }
            .font(.caption)
            .padding(.top, 4)
            .accessibilityLabel("Use recommended mic sensitivity")

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
        .onAppear {
            viewModel.ensureLevelMonitoringActive()
        }
    }

    private var sliderWithRecommendedMarker: some View {
        ZStack(alignment: .leading) {
            Slider(value: $viewModel.volume, in: 0...100, step: 1)
                .accentColor(.accentColor)
            GeometryReader { geometry in
                let width = geometry.size.width
                let markerPosition = width * CGFloat(recommendedVolume / 100.0)
                Rectangle()
                    .fill(Color.secondary.opacity(0.6))
                    .frame(width: 2, height: 12)
                    .offset(x: markerPosition - 1)
                    .accessibilityHidden(true)
            }
            .allowsHitTesting(false)
        }
        .frame(height: 30)
    }
    
    // MARK: - Color Helpers
    
    private var sectionBackgroundColor: Color {
        Color(UIColor.secondarySystemBackground)
    }
}
