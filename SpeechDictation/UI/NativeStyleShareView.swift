//
//  NativeStyleShareView.swift
//  SpeechDictation
//
//  Created by AI Assistant on 6/30/24.
//
//  Enhanced native iOS share sheet style interface with proper dark/light mode support.
//

import SwiftUI
import Foundation

/// Enhanced native iOS share sheet style interface
/// Supports both basic text formats and professional timing formats
struct NativeStyleShareView: View {
    let text: String
    let timingSession: AudioRecordingSession?
    @Binding var isPresented: Bool
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var selectedTextFormat: ExportManager.ExportFormat = .plainText
    @State private var selectedTimingFormat: ExportManager.TimingExportFormat = .srt
    @State private var showingFormatSelector = false
    @State private var exportType: ExportType = .text
    @Environment(\.openURL) var openURL
    @Environment(\.colorScheme) private var colorScheme
    
    enum ExportType {
        case text
        case timing
        case audioWithTiming
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Handle bar
            Capsule()
                .fill(Color.secondary.opacity(0.5))
                .frame(width: 36, height: 5)
                .padding(.top, 8)
                .padding(.bottom, 20)
            
            // Title
            Text("Export Transcription")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
                .padding(.bottom, 32)
            
            // Export type selector
            if timingSession != nil {
                Picker("Export Type", selection: $exportType) {
                    Text("Text Only").tag(ExportType.text)
                    Text("Timing Data").tag(ExportType.timing)
                    Text("Audio + Timing").tag(ExportType.audioWithTiming)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }
            
            // Share actions grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 20), count: 3), spacing: 28) {
                ShareButton(
                    icon: "doc.on.clipboard",
                    title: "Copy",
                    color: .blue
                ) {
                    copyToClipboard()
                }
                
                ShareButton(
                    icon: "folder",
                    title: "Save to Files",
                    color: .orange
                ) {
                    saveToFiles()
                }
                
                ShareButton(
                    icon: "square.and.arrow.up",
                    title: "Share",
                    color: .green
                ) {
                    shareContent()
                }
                
                ShareButton(
                    icon: "doc.text",
                    title: "Format Options",
                    color: .purple
                ) {
                    showingFormatSelector = true
                }
                
                ShareButton(
                    icon: "envelope",
                    title: "Mail",
                    color: .blue
                ) {
                    shareViaEmail()
                }
                
                ShareButton(
                    icon: "message",
                    title: "Messages",
                    color: .green
                ) {
                    shareViaMessages()
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
            
            // Format info
            if exportType != .text {
                VStack(spacing: 8) {
                    Text("Selected Format:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(formatDisplayName)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Text(formatDescription)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                }
                .padding(.bottom, 20)
            }
            
            // Cancel button
            Button("Cancel") {
                isPresented = false
            }
            .font(.system(size: 16, weight: .medium))
            .foregroundColor(.accentColor)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(cancelButtonBackgroundColor)
            .cornerRadius(12)
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
        }
        .background(mainBackgroundColor)
        .alert("Export Result", isPresented: $showingAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
        .sheet(isPresented: $showingFormatSelector) {
            FormatSelectorView(
                exportType: exportType,
                selectedTextFormat: $selectedTextFormat,
                selectedTimingFormat: $selectedTimingFormat,
                isPresented: $showingFormatSelector
            )
        }
    }
    
    // MARK: - Color Helpers
    
    private var mainBackgroundColor: Color {
        Color(UIColor.systemBackground)
    }
    
    private var cancelButtonBackgroundColor: Color {
        Color(UIColor.secondarySystemBackground)
    }
    
    // MARK: - Computed Properties
    
    private var formatDisplayName: String {
        switch exportType {
        case .text:
            return selectedTextFormat.displayName
        case .timing, .audioWithTiming:
            return selectedTimingFormat.displayName
        }
    }
    
    private var formatDescription: String {
        switch exportType {
        case .text:
            return selectedTextFormat.description
        case .timing, .audioWithTiming:
            return selectedTimingFormat.description
        }
    }
    
    // MARK: - Actions
    
    private func copyToClipboard() {
        switch exportType {
        case .text:
            ExportManager.shared.copyToClipboard(text)
        case .timing, .audioWithTiming:
            guard let session = timingSession else { return }
            let timingData = ExportManager.shared.generateTimingDataContent(from: session, format: selectedTimingFormat)
            ExportManager.shared.copyToClipboard(timingData)
        }
        showAlert("Copied to clipboard")
        isPresented = false
    }
    
    private func saveToFiles() {
        Task { @MainActor in
            switch exportType {
            case .text:
                ExportManager.shared.saveToFiles(text: text, format: selectedTextFormat) { success in
                    showAlert(success ? "File saved successfully" : "Failed to save file")
                    isPresented = false
                }
                return
            case .timing:
                guard let session = timingSession else { return }
                ExportManager.shared.saveTimingDataToFiles(session: session, format: selectedTimingFormat) { success in
                    showAlert(success ? "Timing data saved successfully" : "Failed to save timing data")
                    isPresented = false
                }
                return
            case .audioWithTiming:
                guard let session = timingSession else { return }
                ExportManager.shared.exportAudioWithTimingData(session: session, timingFormat: selectedTimingFormat) { success in
                    showAlert(success ? "Audio and timing data exported successfully" : "Failed to export audio and timing data")
                    isPresented = false
                }
                return
            }
        }
    }
    
    private func shareContent() {
        switch exportType {
        case .text:
            ExportManager.shared.presentShareSheet(text: text, format: selectedTextFormat, from: nil)
        case .timing:
            guard let session = timingSession else { return }
            ExportManager.shared.presentTimingDataShareSheet(session: session, format: selectedTimingFormat, from: nil)
        case .audioWithTiming:
            guard let session = timingSession else { return }
            ExportManager.shared.presentAudioWithTimingDataShareSheet(session: session, timingFormat: selectedTimingFormat, from: nil)
        }
        isPresented = false
    }
    
    private func shareViaEmail() {
        let content: String
        switch exportType {
        case .text:
            content = text
        case .timing, .audioWithTiming:
            guard let session = timingSession else { return }
            content = ExportManager.shared.generateTimingDataContent(from: session, format: selectedTimingFormat)
        }
        
        let encodedContent = content.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        if let url = URL(string: "mailto:?subject=Speech Transcription&body=\(encodedContent)") {
            openURL(url)
        }
        isPresented = false
    }
    
    private func shareViaMessages() {
        let content: String
        switch exportType {
        case .text:
            content = text
        case .timing, .audioWithTiming:
            guard let session = timingSession else { return }
            content = ExportManager.shared.generateTimingDataContent(from: session, format: selectedTimingFormat)
        }
        
        let encodedContent = content.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        if let url = URL(string: "sms:&body=\(encodedContent)") {
            openURL(url)
        }
        isPresented = false
    }
    
    private func showAlert(_ message: String) {
        alertMessage = message
        showingAlert = true
    }
}

// MARK: - Format Selector View

struct FormatSelectorView: View {
    let exportType: NativeStyleShareView.ExportType
    @Binding var selectedTextFormat: ExportManager.ExportFormat
    @Binding var selectedTimingFormat: ExportManager.TimingExportFormat
    @Binding var isPresented: Bool
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    headerView
                    formatSelectionView
                    Spacer(minLength: 20)
                }
                .padding()
            }
            .background(Color(UIColor.systemBackground))
            .navigationTitle("Export Format")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                trailing: Button("Cancel") {
                    isPresented = false
                }
                .foregroundColor(.accentColor)
            )
        }
    }
    
    private var headerView: some View {
        Text("Select Export Format")
            .font(.headline)
            .foregroundColor(.primary)
            .padding(.top, 20)
    }
    
    @ViewBuilder
    private var formatSelectionView: some View {
        if exportType == .text {
            textFormatButtons
        } else {
            timingFormatButtons
        }
    }
    
    private var textFormatButtons: some View {
        LazyVStack(spacing: 12) {
            let formats = [ExportManager.ExportFormat.plainText, .richText, .markdown]
            ForEach(0..<formats.count, id: \.self) { index in
                let format = formats[index]
                Button(action: {
                    selectedTextFormat = format
                    isPresented = false
                }) {
                    FormatRow(
                        title: format.displayName,
                        description: format.description,
                        isSelected: selectedTextFormat == format
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
    
    private var timingFormatButtons: some View {
        LazyVStack(spacing: 12) {
            let formats = [ExportManager.TimingExportFormat.srt, .vtt, .ttml, .json]
            ForEach(0..<formats.count, id: \.self) { index in
                let format = formats[index]
                Button(action: {
                    selectedTimingFormat = format
                    isPresented = false
                }) {
                    FormatRow(
                        title: format.displayName,
                        description: format.description,
                        isSelected: selectedTimingFormat == format
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
}

// MARK: - Format Row Component

struct FormatRow: View {
    let title: String
    let description: String
    let isSelected: Bool
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
            }
            
            Spacer()
            
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.accentColor)
                    .font(.system(size: 20))
            }
        }
        .padding()
        .background(isSelected ? Color.accentColor.opacity(0.1) : Color(UIColor.secondarySystemBackground))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
        )
    }
}

// MARK: - Share Button Component

struct ShareButton: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 10) {
                // Icon background circle
                ZStack {
                    Circle()
                        .fill(color.opacity(0.12))
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: icon)
                        .font(.system(size: 22, weight: .medium))
                        .foregroundColor(color)
                }
                
                // Label
                Text(title)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .frame(height: 30)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Preview

struct NativeStyleShareView_Previews: PreviewProvider {
    static var previews: some View {
        NativeStyleShareView(
            text: "Sample transcript text",
            timingSession: nil,
            isPresented: .constant(true)
        )
        .previewLayout(.sizeThatFits)
    }
} 