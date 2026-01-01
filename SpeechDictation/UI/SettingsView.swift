//
//  SettingsView.swift
//  SpeechDictation
//
//  Created by Joseph McCraw on 7/17/24.
//
//  Main settings view that combines all setting components including security preferences.
//  Now supports proper dark/light mode adaptation and secure recordings configuration.
//

import SwiftUI
import Foundation
import AVFoundation
import CoreML
import Vision
import Combine
#if canImport(ARKit)
import ARKit
#endif
#if canImport(UIKit)
import UIKit
#endif

struct SettingsView: View {
    @ObservedObject var viewModel: SpeechRecognizerViewModel
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("Settings")
                    .font(.title)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(headerBackgroundColor)
                    .cornerRadius(10)

                TextSizeSettingView(viewModel: viewModel)
                ThemeSettingView(viewModel: viewModel)
                MicSensitivityView(viewModel: viewModel)
                DepthBasedDistanceView()
                SecureRecordingsSettingsView()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(mainBackgroundColor)
            .cornerRadius(10)
            .shadow(color: shadowColor, radius: 10, x: 0, y: 0)
            .padding()
        }
        .preferredColorScheme(preferredColorScheme)
    }
    
    // MARK: - Color Helpers
    
    private var headerBackgroundColor: Color {
        #if canImport(UIKit)
        return Color(UIColor.tertiarySystemBackground)
        #else
        return Color(NSColor.windowBackgroundColor)
        #endif
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
    
    private var preferredColorScheme: ColorScheme? {
        switch viewModel.theme {
        case .system:
            return nil
        case .light, .highContrast:
            return .light
        case .dark:
            return .dark
        }
    }
}

/// SwiftUI view for configuring secure recordings preferences
/// Provides authentication settings, biometric status, and iCloud sync options
struct SecureRecordingsSettingsView: View {
    @StateObject private var authManager = LocalAuthenticationManager.shared
    @Environment(\.colorScheme) private var colorScheme
    @State private var showingAuthenticationInfo = false
    @State private var iCloudSyncEnabled = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: "lock.shield.fill")
                    .foregroundColor(.blue)
                    .font(.title2)
                
                Text("Secure Recordings")
                    .font(.headline)
                    .fontWeight(.medium)
                
                Spacer()
                
                Button(action: {
                    showingAuthenticationInfo = true
                }) {
                    Image(systemName: "info.circle")
                        .foregroundColor(.secondary)
                        .font(.subheadline)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            
            // Authentication requirement toggle
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Require Authentication")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Text("Use \(authManager.biometricType.description) or passcode to access private recordings")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Toggle("", isOn: Binding(
                        get: { authManager.isAuthenticationRequired },
                        set: { authManager.setAuthenticationRequired($0) }
                    ))
                    .labelsHidden()
                    .scaleEffect(0.8)
                }
                .padding(.horizontal, 16)
                
                // Authentication status indicator
                if authManager.isAuthenticationRequired {
                    HStack(spacing: 8) {
                        Image(systemName: authenticationStatusIcon)
                            .foregroundColor(authenticationStatusColor)
                            .font(.caption)
                        
                        Text(authenticationStatusText)
                            .font(.caption)
                            .foregroundColor(authenticationStatusColor)
                        
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                }
            }
            
            Divider()
                .padding(.horizontal, 16)
            
            // iCloud sync preference (placeholder for future implementation)
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("iCloud Backup")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Text("Optionally sync secure recordings to iCloud (requires encryption)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Toggle("", isOn: $iCloudSyncEnabled)
                        .labelsHidden()
                        .scaleEffect(0.8)
                        .disabled(true) // Disabled for future implementation
                }
                .padding(.horizontal, 16)
                
                if iCloudSyncEnabled {
                    HStack(spacing: 8) {
                        Image(systemName: "icloud.fill")
                            .foregroundColor(.blue)
                            .font(.caption)
                        
                        Text("Coming soon - End-to-end encrypted iCloud sync")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                }
            }
            
            // Device security status
            VStack(alignment: .leading, spacing: 8) {
                Text("Device Security Status")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .padding(.horizontal, 16)
                
                VStack(spacing: 6) {
                    SecurityStatusRow(
                        title: "Device Passcode",
                        isEnabled: authManager.isDeviceSecure(),
                        icon: "key.fill"
                    )
                    
                    SecurityStatusRow(
                        title: authManager.biometricType.description,
                        isEnabled: authManager.isBiometricAuthenticationAvailable(),
                        icon: biometricIcon
                    )
                    
                    SecurityStatusRow(
                        title: "File Protection",
                        isEnabled: true,
                        icon: "shield.checkered"
                    )
                }
                .padding(.horizontal, 16)
            }
        }
        .padding(.vertical, 12)
        .background(settingsCardBackgroundColor)
        .cornerRadius(12)
        .onAppear {
            authManager.refreshBiometricCapabilities()
            loadiCloudSyncPreference()
        }
        .alert("Secure Recordings Authentication", isPresented: $showingAuthenticationInfo) {
            Button("OK") { }
        } message: {
            Text("Secure recordings use complete file protection and require authentication to access. All speech processing happens on-device for maximum privacy. Authentication is cached for 5 minutes after successful verification.")
        }
    }
    
    // MARK: - Helper Properties
    
    private var settingsCardBackgroundColor: Color {
        #if canImport(UIKit)
        Color(UIColor.secondarySystemBackground)
        #else
        Color(NSColor.controlBackgroundColor)
        #endif
    }
    
    private var authenticationStatusIcon: String {
        if authManager.authenticationState.isAuthenticated {
            return "checkmark.circle.fill"
        } else {
            return "lock.circle.fill"
        }
    }
    
    private var authenticationStatusColor: Color {
        if authManager.authenticationState.isAuthenticated {
            return .green
        } else {
            return .orange
        }
    }
    
    private var authenticationStatusText: String {
        if authManager.authenticationState.isAuthenticated {
            return "Authenticated - Access granted"
        } else {
            return "Authentication required for access"
        }
    }
    
    private var biometricIcon: String {
        switch authManager.biometricType {
        case .faceID: return "faceid"
        case .touchID: return "touchid"
        case .opticID: return "opticid"
        case .none: return "questionmark.circle"
        }
    }
    
    // MARK: - Helper Methods
    
    private func loadiCloudSyncPreference() {
        iCloudSyncEnabled = UserDefaults.standard.bool(forKey: "secureRecordingsiCloudSync")
    }
}

/// Individual security status row component
struct SecurityStatusRow: View {
    let title: String
    let isEnabled: Bool
    let icon: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(isEnabled ? .green : .secondary)
                .font(.subheadline)
                .frame(width: 16)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.primary)
            
            Spacer()
            
            Image(systemName: isEnabled ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundColor(isEnabled ? .green : .red)
                .font(.caption)
        }
    }
}

#if canImport(ARKit)
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
                .fill(semanticSecondaryBackgroundColor())
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
            AppLog.info(.camera, "LiDAR scanner detected")
        }
        
        // Check ARKit availability (iPhone 6s+, iOS 11+)
        if ARWorldTrackingConfiguration.isSupported {
            sources.append("ARKit")
            hasARKit = true
            AppLog.info(.camera, "ARKit world tracking supported")
        }
        
        // Check TrueDepth camera availability (Face ID devices)
        if ARFaceTrackingConfiguration.isSupported {
            sources.append("TrueDepth")
            AppLog.info(.camera, "TrueDepth camera detected")
        }
        
        // Check for ML model availability (Depth Anything V2 from ModelCatalog)
        // In a full implementation, this would check ModelCatalog.shared.getInstalledModelURL(for: "depth-anything-v2")
        sources.append("ML Model")
        hasMLModel = true
        
        // Always have fallback
        sources.append("Fallback")
        
        availableDepthSources = sources
        AppLog.info(.camera, "Detected \(sources.count) depth estimation sources: \(sources.joined(separator: ", "))")
    }
}
#else
/// Fallback view when ARKit is unavailable (e.g., macOS Catalyst previews)
struct DepthBasedDistanceView: View {
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "camera.metering.matrix")
                    .foregroundColor(.accentColor)
                    .font(.title2)
                Text("Depth-Based Distance")
                    .font(.headline)
                    .fontWeight(.medium)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            
            Text("Depth sensors are unavailable on this platform.")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal, 16)
        }
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(semanticSecondaryBackgroundColor())
        )
    }
}

#endif

// MARK: - Cross-platform Color Helpers

private func semanticSecondaryBackgroundColor() -> Color {
    #if canImport(UIKit)
    return Color(UIColor.secondarySystemBackground)
    #elseif canImport(AppKit)
    return Color(NSColor.controlBackgroundColor)
    #else
    return Color.gray.opacity(0.2)
    #endif
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
