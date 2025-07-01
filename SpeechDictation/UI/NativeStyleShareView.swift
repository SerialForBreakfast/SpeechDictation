//
//  NativeStyleShareView.swift
//  SpeechDictation
//
//  Created by AI Assistant on 6/30/24.
//

import SwiftUI

/// Native iOS share sheet style interface
/// Clean layout with working functionality via ExportManager
struct NativeStyleShareView: View {
    let text: String
    @Binding var isPresented: Bool
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @Environment(\.openURL) var openURL
    
    var body: some View {
        VStack(spacing: 0) {
            // Handle bar
            Capsule()
                .fill(Color.secondary.opacity(0.5))
                .frame(width: 36, height: 5)
                .padding(.top, 8)
                .padding(.bottom, 20)
            
            // Title
            Text("Share Transcription")
                .font(.headline)
                .fontWeight(.semibold)
                .padding(.bottom, 32)
            
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
                
                ShareButton(
                    icon: "doc.text",
                    title: "Export Text",
                    color: .gray
                ) {
                    exportText()
                }
                
                ShareButton(
                    icon: "square.and.arrow.up",
                    title: "More Options",
                    color: .purple
                ) {
                    showMoreOptions()
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
            
            // Cancel button
            Button("Cancel") {
                isPresented = false
            }
            .font(.system(size: 16, weight: .medium))
            .foregroundColor(.blue)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
        }
        .background(Color.white)
        .alert("Share Result", isPresented: $showingAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
    }
    
    // MARK: - Actions
    
    private func copyToClipboard() {
        ExportManager.shared.copyToClipboard(text)
        showAlert("Copied to clipboard")
        isPresented = false
    }
    
    private func saveToFiles() {
        Task { @MainActor in
            ExportManager.shared.saveToFiles(text: text, format: .plainText) { success in
                showAlert(success ? "File saved successfully" : "Failed to save file")
                isPresented = false
            }
        }
    }
    
    private func exportText() {
        Task { @MainActor in
            ExportManager.shared.saveToFiles(text: text, format: .plainText) { success in
                showAlert(success ? "Text exported successfully" : "Failed to export text")
                isPresented = false
            }
        }
    }
    
    private func shareViaEmail() {
        let encodedText = text.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        if let url = URL(string: "mailto:?subject=Speech Transcription&body=\(encodedText)") {
            openURL(url)
            isPresented = false
        }
    }
    
    private func shareViaMessages() {
        let encodedText = text.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        if let url = URL(string: "sms:&body=\(encodedText)") {
            openURL(url)
            isPresented = false
        }
    }
    
    private func showMoreOptions() {
        // Fall back to system share sheet for additional options
        ExportManager.shared.presentShareSheet(text: text, format: .plainText, from: nil)
        isPresented = false
    }
    
    private func showAlert(_ message: String) {
        alertMessage = message
        showingAlert = true
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

struct NativeStyleShareView_Previews: PreviewProvider {
    static var previews: some View {
        NativeStyleShareView(text: "Sample transcript text", isPresented: .constant(true))
            .previewLayout(.sizeThatFits)
    }
} 