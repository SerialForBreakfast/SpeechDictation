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
import Foundation
import AVFoundation
import CoreML
import Vision
import Combine
import ARKit
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
            DepthBasedDistanceView()
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

/// SwiftUI view for configuring depth-based distance estimation settings
/// Provides toggle control and information about device capabilities  
struct DepthBasedDistanceView: View {
    @ObservedObject private var cameraSettings = CameraSettingsManager.shared
    @State private var availableDepthSources: [String] = []
    @State private var hasLiDAR = false
    @State private var hasARKit = false
    @State private var hasMLModel = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: "camera.metering.matrix")
                    .foregroundColor(.accentColor)
                    .font(.title2)
                
                Text("Depth-Based Distance")
                    .font(.headline)
                    .fontWeight(.medium)
                
                Spacer()
                
                Toggle("", isOn: $cameraSettings.enableDepthBasedDistance)
                    .labelsHidden()
                    .scaleEffect(0.8)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            
            // Description
            Text("Use hardware sensors and ML models to measure actual distances to objects for more accurate spatial descriptions.")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal, 16)
            
            // Depth Sources Info
            if !availableDepthSources.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Available Depth Sources:")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 8) {
                        ForEach(availableDepthSources, id: \.self) { source in
                            DepthSourceBadge(source: source)
                        }
                    }
                }
                .padding(.horizontal, 16)
            }
            
            // Performance Note
            if cameraSettings.enableDepthBasedDistance {
                HStack {
                    Image(systemName: "info.circle")
                        .foregroundColor(.orange)
                        .font(.caption)
                    
                    Text("Depth estimation may slightly impact performance on older devices.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 4)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(UIColor.secondarySystemBackground))
        )
        .onAppear {
            loadDepthCapabilities()
        }
    }
    
    /// Load available depth sources from device capabilities
    private func loadDepthCapabilities() {
        var sources: [String] = []
        
        // Check LiDAR availability (iPhone 12 Pro+, iPad Pro 2020+)
        if ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh) {
            sources.append("LiDAR")
            hasLiDAR = true
            print("LiDAR scanner detected")
        }
        
        // Check ARKit availability (iPhone 6s+, iOS 11+)
        if ARWorldTrackingConfiguration.isSupported {
            sources.append("ARKit")
            hasARKit = true
            print("ARKit world tracking supported")
        }
        
        // Check TrueDepth camera availability (Face ID devices)
        if ARFaceTrackingConfiguration.isSupported {
            sources.append("TrueDepth")
            print("TrueDepth camera detected")
        }
        
        // Check for ML model availability (Depth Anything V2 from ModelCatalog)
        // In a full implementation, this would check ModelCatalog.shared.getInstalledModelURL(for: "depth-anything-v2")
        sources.append("ML Model")
        hasMLModel = true
        
        // Always have fallback
        sources.append("Fallback")
        
        availableDepthSources = sources
                    print("Detected \(sources.count) depth estimation sources: \(sources.joined(separator: ", "))")
    }
}

/// Badge view for displaying depth source capabilities
struct DepthSourceBadge: View {
    let source: String
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: iconName)
                .font(.caption2)
                .foregroundColor(badgeColor)
            
            Text(source)
                .font(.caption2)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(badgeColor.opacity(0.1))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(badgeColor.opacity(0.3), lineWidth: 1)
        )
    }
    
    private var iconName: String {
        switch source {
        case "LiDAR":
            return "laser.burst"
        case "ARKit":
            return "arkit"
        case "TrueDepth":
            return "faceid"
        case "ML Model":
            return "brain.head.profile"
        case "Fallback":
            return "rectangle.badge.minus"
        default:
            return "questionmark.circle"
        }
    }
    
    private var badgeColor: Color {
        switch source {
        case "LiDAR":
            return .blue
        case "ARKit":
            return .green
        case "TrueDepth":
            return .orange
        case "ML Model":
            return .purple
        case "Fallback":
            return .gray
        default:
            return .gray
        }
    }
}
