//
//  VUMeterView2.swift
//  SpeechDictation
//
//  Created by Joseph McCraw on 12/13/25.
//
//  A plug-and-play VU meter for both live transcription and playback.
//
//  Design goals:
//  - Accepts either linear (0...1) or decibel input.
//  - Smooth visual updates without requiring timers.
//  - Testable: math/normalization is isolated in pure helpers.
//  - Accessible: label/value reflect current level.
//

import SwiftUI

// MARK: - VUMeterView

public struct VUMeterView2: View {

    // MARK: Public Types

    /// The input scale for the meter.
    public enum InputScale: Equatable, Sendable {
        /// Input is already normalized: 0.0 (silence) ... 1.0 (full scale).
        case linear01
        /// Input is in decibels (dBFS-style), typically negative values.
        /// The `floorDb` is clamped to avoid extreme values (e.g. -80 dB).
        case decibels(floorDb: Double)
    }

    /// Layout direction for the meter.
    public enum Orientation: Equatable, Sendable {
        case horizontal
        case vertical
    }

    /// Rendering style.
    public enum Style: Equatable, Sendable {
        /// A segmented “LED bar” style meter.
        case bars
        /// A continuous fill (capsule) meter.
        case fill
    }

    // MARK: Public Configuration

    private let rawLevel: Double
    private let rawPeakLevel: Double?
    private let inputScale: InputScale
    private let orientation: Orientation
    private let style: Style
    private let barCount: Int
    private let cornerRadius: CGFloat
    private let showsPeakHold: Bool
    private let accessibilityLabelText: String
    private let accessibilityHintText: String?

    // MARK: Internal State (smoothed display)

    @State private var displayedLevel: Double = 0.0
    @State private var displayedPeakHold: Double = 0.0

    // MARK: Init

    /// Creates a VU meter.
    ///
    /// - Parameters:
    ///   - level: The current level. Interpret using `inputScale`.
    ///   - peakLevel: Optional peak level (same scale as `level`). If nil, the view will derive a peak hold from `level`.
    ///   - inputScale: `.linear01` or `.decibels(floorDb:)`.
    ///   - orientation: Horizontal or vertical meter.
    ///   - style: Bars or continuous fill.
    ///   - barCount: Number of segments when using `.bars`.
    ///   - showsPeakHold: Whether to draw a peak indicator.
    ///   - accessibilityLabelText: Accessibility label for VoiceOver.
    ///   - accessibilityHintText: Optional hint for VoiceOver.
    public init(
        level: Double,
        peakLevel: Double? = nil,
        inputScale: InputScale = .linear01,
        orientation: Orientation = .horizontal,
        style: Style = .bars,
        barCount: Int = 18,
        showsPeakHold: Bool = true,
        cornerRadius: CGFloat = 6.0,
        accessibilityLabelText: String = "Audio level",
        accessibilityHintText: String? = "Shows the current volume level."
    ) {
        self.rawLevel = level
        self.rawPeakLevel = peakLevel
        self.inputScale = inputScale
        self.orientation = orientation
        self.style = style
        self.barCount = max(4, barCount)
        self.showsPeakHold = showsPeakHold
        self.cornerRadius = cornerRadius
        self.accessibilityLabelText = accessibilityLabelText
        self.accessibilityHintText = accessibilityHintText
    }

    // MARK: View

    public var body: some View {
        let normalizedLevel: Double = VUMeterMath.normalizedLevel(from: rawLevel, inputScale: inputScale)
        let normalizedPeak: Double = {
            if let rawPeak: Double = rawPeakLevel {
                return VUMeterMath.normalizedLevel(from: rawPeak, inputScale: inputScale)
            }
            return normalizedLevel
        }()

        return content(
            normalizedLevel: normalizedLevel,
            normalizedPeak: normalizedPeak
        )
        .onAppear {
            // Initialize display state immediately to avoid a first-frame jump.
            displayedLevel = normalizedLevel
            displayedPeakHold = normalizedPeak
        }
        .onChange(of: normalizedLevel) { newValue in
            updateDisplayedLevels(normalizedLevel: newValue, normalizedPeak: normalizedPeak)
        }
        .onChange(of: normalizedPeak) { newValue in
            updateDisplayedLevels(normalizedLevel: normalizedLevel, normalizedPeak: newValue)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(accessibilityLabelText))
        .accessibilityValue(Text(VUMeterMath.accessibilityValueText(forNormalizedLevel: displayedLevel)))
//        .accessibilityHint(accessibilityHintText.map(Text.init))
    }

    // MARK: Rendering

    @ViewBuilder
    private func content(normalizedLevel: Double, normalizedPeak: Double) -> some View {
        switch style {
        case .bars:
            barsContent()
        case .fill:
            fillContent()
        }
    }

    private func barsContent() -> some View {
        let litBars: Int = VUMeterMath.litBarCount(
            normalizedLevel: displayedLevel,
            barCount: barCount
        )

        return ZStack(alignment: alignmentForOrientation) {
            barStack(litBars: litBars)

            if showsPeakHold {
                peakIndicator()
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }

    private func fillContent() -> some View {
        ZStack(alignment: alignmentForOrientation) {
            Capsule()
                .fill(Color.secondary.opacity(0.25))

            GeometryReader { proxy in
                let width: CGFloat = proxy.size.width
                let height: CGFloat = proxy.size.height

                switch orientation {
                case .horizontal:
                    Capsule()
                        .fill(Color.accentColor)
                        .frame(width: width * CGFloat(displayedLevel), height: height)

                case .vertical:
                    Capsule()
                        .fill(Color.accentColor)
                        .frame(width: width, height: height * CGFloat(displayedLevel))
                        .position(x: width / 2.0, y: height - (height * CGFloat(displayedLevel) / 2.0))
                }
            }

            if showsPeakHold {
                peakIndicator()
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }

    private func barStack(litBars: Int) -> some View {
        let spacing: CGFloat = 2.0

        return Group {
            switch orientation {
            case .horizontal:
                HStack(spacing: spacing) {
                    ForEach(0..<barCount, id: \.self) { index in
                        bar(isLit: index < litBars)
                    }
                }

            case .vertical:
                VStack(spacing: spacing) {
                    ForEach((0..<barCount).reversed(), id: \.self) { index in
                        bar(isLit: index < litBars)
                    }
                }
            }
        }
        .padding(4)
        .background(Color.secondary.opacity(0.12))
    }

    private func bar(isLit: Bool) -> some View {
        RoundedRectangle(cornerRadius: 2, style: .continuous)
            .fill(isLit ? Color.accentColor : Color.secondary.opacity(0.25))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func peakIndicator() -> some View {
        let indicatorThickness: CGFloat = 2.0

        return GeometryReader { proxy in
            let size: CGSize = proxy.size

            switch orientation {
            case .horizontal:
                Rectangle()
                    .fill(Color.primary.opacity(0.9))
                    .frame(width: indicatorThickness, height: size.height)
                    .position(
                        x: size.width * CGFloat(displayedPeakHold),
                        y: size.height / 2.0
                    )

            case .vertical:
                Rectangle()
                    .fill(Color.primary.opacity(0.9))
                    .frame(width: size.width, height: indicatorThickness)
                    .position(
                        x: size.width / 2.0,
                        y: size.height - (size.height * CGFloat(displayedPeakHold))
                    )
            }
        }
        .allowsHitTesting(false)
    }

    private var alignmentForOrientation: Alignment {
        switch orientation {
        case .horizontal:
            return .leading
        case .vertical:
            return .bottom
        }
    }

    // MARK: Updates

    /// Smoothly updates the displayed level and peak-hold.
    ///
    /// Note: We keep this animation short to avoid lag while still preventing jitter.
    private func updateDisplayedLevels(normalizedLevel: Double, normalizedPeak: Double) {
        let clampedLevel: Double = VUMeterMath.clamp01(normalizedLevel)
        let clampedPeak: Double = VUMeterMath.clamp01(normalizedPeak)

        withAnimation(.linear(duration: 0.08)) {
            displayedLevel = clampedLevel
        }

        // Peak-hold behavior: hold the max value and decay slowly.
        // This is intentionally simple and “update-driven” for determinism in tests.
        let decayedPeak: Double = max(displayedPeakHold - 0.03, 0.0)
        let nextPeak: Double = max(clampedPeak, decayedPeak)

        withAnimation(.linear(duration: 0.10)) {
            displayedPeakHold = nextPeak
        }
    }
}

// MARK: - VUMeterMath

/// Pure helpers for VU meter normalization and rendering math.
///
/// Keep these in sync with UI expectations; add unit tests around:
/// - dB -> normalized conversion
/// - clamping
/// - bar quantization
public enum VUMeterMath {

    /// Clamps to 0...1.
    public static func clamp01(_ value: Double) -> Double {
        if value.isNaN || value.isInfinite {
            return 0.0
        }
        return min(1.0, max(0.0, value))
    }

    /// Converts raw input into a normalized 0...1 level.
    public static func normalizedLevel(from raw: Double, inputScale: VUMeterView2.InputScale) -> Double {
        switch inputScale {
        case .linear01:
            return clamp01(raw)

        case .decibels(let floorDb):
            return clamp01(normalizedLinearFromDecibels(db: raw, floorDb: floorDb))
        }
    }

    /// Converts decibels (typically negative) into a 0...1 normalized linear scale.
    ///
    /// This uses a simple mapping:
    /// - Any value <= floorDb => 0
    /// - 0 dB => 1
    /// - Interpolate in amplitude space using 10^(dB/20)
    public static func normalizedLinearFromDecibels(db: Double, floorDb: Double) -> Double {
        let clampedDb: Double = max(floorDb, min(0.0, db))

        if clampedDb <= floorDb {
            return 0.0
        }

        let amplitude: Double = pow(10.0, clampedDb / 20.0)
        let floorAmplitude: Double = pow(10.0, floorDb / 20.0)

        let normalized: Double = (amplitude - floorAmplitude) / (1.0 - floorAmplitude)
        return clamp01(normalized)
    }

    /// Quantizes a normalized level into a number of lit bars.
    public static func litBarCount(normalizedLevel: Double, barCount: Int) -> Int {
        let clamped: Double = clamp01(normalizedLevel)
        let count: Int = max(1, barCount)
        let rawBars: Double = clamped * Double(count)
        let lit: Int = Int(rawBars.rounded(.down))
        return min(count, max(0, lit))
    }

    /// Human-readable value text for VoiceOver.
    public static func accessibilityValueText(forNormalizedLevel normalizedLevel: Double) -> String {
        let clamped: Double = clamp01(normalizedLevel)
        let percent: Int = Int((clamped * 100.0).rounded())
        return "\(percent) percent"
    }
}

//// MARK: - Preview
//
//struct VUMeterView_Previews: PreviewProvider {
//    static var previews: some View {
//        VStack(spacing: 16) {
//            VUMeterView(level: 0.15, inputScale: .linear01, orientation: .horizontal, style: .bars)
//                .frame(height: 22)
//
//            VUMeterView(level: -18.0, inputScale: .decibels(floorDb: -60.0), orientation: .horizontal, style: .fill)
//                .frame(height: 18)
//
//            VUMeterView(level: 0.72, inputScale: .linear01, orientation: .vertical, style: .bars)
//                .frame(width: 26, height: 120)
//
//            VUMeterView(level: -6.0, inputScale: .decibels(floorDb: -60.0), orientation: .vertical, style: .fill)
//                .frame(width: 18, height: 120)
//        }
//        .padding()
//    }
//}
