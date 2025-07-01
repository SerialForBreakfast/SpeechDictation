//
//  VUMeterView.swift
//  SpeechDictation
//
//  Created by AI Assistant on 7/1/24.
//
//  A lightweight SwiftUI component that visualises the live microphone input level received
//  from `SpeechRecognizerViewModel.currentLevel`. The level is expected to be **normalised**
//  between 0.0 and 1.0.
//
//  The view renders a simple vertical bar whose fill height tracks the current level. It
//  provides a quick-look "VU" (volume-unit) style meter that can be embedded next to the mic
//  sensitivity slider.
//
//  Concurrency: All updates happen on the main actor because `@Published currentLevel` is
//  observed from SwiftUI. No additional synchronisation is required.
//

import SwiftUI

/// Visualises the microphone input level in real-time.
///
/// The meter consists of a grey background bar and a coloured foreground bar whose height is
/// proportional to `level`.  The colour transitions from green → yellow → red as the level
/// increases to provide an at-a-glance indication of clipping.
struct VUMeterView: View {
    /// Normalised peak/RMS level in the range `0 … 1`.
    let level: Float

    private var clampedLevel: CGFloat { CGFloat(max(0, min(level, 1))) }

    var body: some View {
        GeometryReader { geometry in
            let totalHeight = geometry.size.height
            let activeHeight = totalHeight * clampedLevel

            ZStack(alignment: .bottom) {
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.gray.opacity(0.25))
                RoundedRectangle(cornerRadius: 3)
                    .fill(barColour)
                    .frame(height: activeHeight)
            }
        }
        .frame(width: 14) // Fixed width; height defined by parent.
        .animation(.linear(duration: 0.05), value: level)
        .accessibilityLabel("Input level")
        .accessibilityValue(String(format: "%.0f percent", clampedLevel * 100))
    }

    /// Simple traffic-light colour scale.
    private var barColour: Color {
        switch level {
        case 0.75...:   return .red
        case 0.5...:    return .yellow
        default:        return .green
        }
    }
}

#Preview {
    VStack {
        VUMeterView(level: 0.2)
            .frame(height: 120)
        VUMeterView(level: 0.6)
            .frame(height: 120)
        VUMeterView(level: 0.9)
            .frame(height: 120)
    }
    .padding()
    .previewLayout(.sizeThatFits)
} 