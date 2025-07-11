//
//  ExportManager.swift
//  SpeechDictation
//
//  Created by AI Assistant on 6/30/24.
//

import Foundation
import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

/// Service responsible for exporting transcribed text in various formats
/// Provides clipboard copying, file saving, and share sheet functionality
class ExportManager {
    static let shared = ExportManager()
    
    private init() {}
    
    /// Export format options
    enum ExportFormat {
        case plainText
        case richText
        case markdown
        
        var fileExtension: String {
            switch self {
            case .plainText: return "txt"
            case .richText: return "rtf"
            case .markdown: return "md"
            }
        }
        
        var mimeType: String {
            switch self {
            case .plainText: return "text/plain"
            case .richText: return "text/rtf"
            case .markdown: return "text/markdown"
            }
        }
    }
    
    /// Timing export format options
    enum TimingExportFormat {
        case srt
        case vtt
        case ttml
        case json
        
        var fileExtension: String {
            switch self {
            case .srt: return "srt"
            case .vtt: return "vtt"
            case .ttml: return "ttml"
            case .json: return "json"
            }
        }
        
        var mimeType: String {
            switch self {
            case .srt: return "application/x-subrip"
            case .vtt: return "text/vtt"
            case .ttml: return "application/ttml+xml"
            case .json: return "application/json"
            }
        }
    }
    
    /// Copy text to clipboard
    /// - Parameter text: Text to copy
    func copyToClipboard(_ text: String) {
        #if os(iOS)
        UIPasteboard.general.string = text
        #else
        NSPasteboard.general.setString(text, forType: .string)
        #endif
    }
    
    /// Save text to Files app
    /// - Parameters:
    ///   - text: Text to save
    ///   - format: Export format
    ///   - completion: Success callback
    func saveToFiles(text: String, format: ExportFormat, completion: @escaping (Bool) -> Void) {
        let fileName = "transcription_\(formattedTimestamp()).\(format.fileExtension)"
        let tempURL = createTemporaryFile(text: text, fileName: fileName, format: format)
        
        #if os(iOS)
        DispatchQueue.main.async {
            let picker = UIDocumentPickerViewController(forExporting: [tempURL])
            
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first {
                window.rootViewController?.present(picker, animated: true)
                completion(true)
            } else {
                completion(false)
            }
        }
        #else
        completion(false)
        #endif
    }
    
    /// Save timing data to Files app
    /// - Parameters:
    ///   - timingData: Timing data content
    ///   - format: Timing export format
    ///   - completion: Success callback
    func saveTimingDataToFiles(timingData: String, format: TimingExportFormat, completion: @escaping (Bool) -> Void) {
        let fileName = "timing_data_\(formattedTimestamp()).\(format.fileExtension)"
        let tempURL = createTemporaryTimingFile(content: timingData, fileName: fileName, format: format)
        
        #if os(iOS)
        DispatchQueue.main.async {
            let picker = UIDocumentPickerViewController(forExporting: [tempURL])
            
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first {
                window.rootViewController?.present(picker, animated: true)
                completion(true)
            } else {
                completion(false)
            }
        }
        #else
        completion(false)
        #endif
    }
    
    /// Export audio file with timing data
    /// - Parameters:
    ///   - audioURL: URL to the audio file
    ///   - timingData: Timing data content
    ///   - timingFormat: Timing export format
    ///   - completion: Success callback
    func exportAudioWithTimingData(audioURL: URL, timingData: String, timingFormat: TimingExportFormat, completion: @escaping (Bool) -> Void) {
        let timingFileName = "timing_data_\(formattedTimestamp()).\(timingFormat.fileExtension)"
        let timingURL = createTemporaryTimingFile(content: timingData, fileName: timingFileName, format: timingFormat)
        
        #if os(iOS)
        DispatchQueue.main.async {
            let picker = UIDocumentPickerViewController(forExporting: [audioURL, timingURL])
            
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first {
                window.rootViewController?.present(picker, animated: true)
                completion(true)
            } else {
                completion(false)
            }
        }
        #else
        completion(false)
        #endif
    }
    
    /// Present system share sheet (iOS-only)
    /// - Parameters:
    ///   - text: Text to share
    ///   - format: Export format
    ///   - sourceView: Source view for iPad presentation (optional)
    #if os(iOS)
    func presentShareSheet(text: String, format: ExportFormat, from sourceView: UIView?) {
        let fileName = "transcription_\(formattedTimestamp()).\(format.fileExtension)"
        let tempURL = createTemporaryFile(text: text, fileName: fileName, format: format)
        
        DispatchQueue.main.async {
            let activityVC = UIActivityViewController(activityItems: [tempURL], applicationActivities: nil)
            activityVC.excludedActivityTypes = [
                .addToReadingList,
                .assignToContact,
                .postToFlickr,
                .postToVimeo,
                .postToWeibo,
                .postToTencentWeibo
            ]
            
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first {
                
                if let popover = activityVC.popoverPresentationController {
                    popover.sourceView = sourceView ?? window
                    popover.sourceRect = sourceView?.bounds ?? CGRect(x: window.bounds.midX, y: window.bounds.midY, width: 0, height: 0)
                }
                
                window.rootViewController?.present(activityVC, animated: true)
            }
        }
    }
    
    /// Present share sheet for timing data (iOS-only)
    /// - Parameters:
    ///   - timingData: Timing data content
    ///   - format: Timing export format
    ///   - sourceView: Source view for iPad presentation (optional)
    func presentTimingDataShareSheet(timingData: String, format: TimingExportFormat, from sourceView: UIView?) {
        let fileName = "timing_data_\(formattedTimestamp()).\(format.fileExtension)"
        let tempURL = createTemporaryTimingFile(content: timingData, fileName: fileName, format: format)
        
        DispatchQueue.main.async {
            let activityVC = UIActivityViewController(activityItems: [tempURL], applicationActivities: nil)
            activityVC.excludedActivityTypes = [
                .addToReadingList,
                .assignToContact,
                .postToFlickr,
                .postToVimeo,
                .postToWeibo,
                .postToTencentWeibo
            ]
            
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first {
                
                if let popover = activityVC.popoverPresentationController {
                    popover.sourceView = sourceView ?? window
                    popover.sourceRect = sourceView?.bounds ?? CGRect(x: window.bounds.midX, y: window.bounds.midY, width: 0, height: 0)
                }
                
                window.rootViewController?.present(activityVC, animated: true)
            }
        }
    }
    
    /// Present share sheet for audio with timing data (iOS-only)
    /// - Parameters:
    ///   - audioURL: URL to the audio file
    ///   - timingData: Timing data content
    ///   - timingFormat: Timing export format
    ///   - sourceView: Source view for iPad presentation (optional)
    func presentAudioWithTimingDataShareSheet(audioURL: URL, timingData: String, timingFormat: TimingExportFormat, from sourceView: UIView?) {
        let timingFileName = "timing_data_\(formattedTimestamp()).\(timingFormat.fileExtension)"
        let timingURL = createTemporaryTimingFile(content: timingData, fileName: timingFileName, format: timingFormat)
        
        DispatchQueue.main.async {
            let activityVC = UIActivityViewController(activityItems: [audioURL, timingURL], applicationActivities: nil)
            activityVC.excludedActivityTypes = [
                .addToReadingList,
                .assignToContact,
                .postToFlickr,
                .postToVimeo,
                .postToWeibo,
                .postToTencentWeibo
            ]
            
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first {
                
                if let popover = activityVC.popoverPresentationController {
                    popover.sourceView = sourceView ?? window
                    popover.sourceRect = sourceView?.bounds ?? CGRect(x: window.bounds.midX, y: window.bounds.midY, width: 0, height: 0)
                }
                
                window.rootViewController?.present(activityVC, animated: true)
            }
        }
    }
    #else
    // Stub for non-iOS platforms to maintain cross-platform build.
    func presentShareSheet(text: String, format: ExportFormat, from sourceView: Any?) {
        // Share sheet unavailable on this platform.
    }
    
    func presentTimingDataShareSheet(timingData: String, format: TimingExportFormat, from sourceView: Any?) {
        // Share sheet unavailable on this platform.
    }
    
    func presentAudioWithTimingDataShareSheet(audioURL: URL, timingData: String, timingFormat: TimingExportFormat, from sourceView: Any?) {
        // Share sheet unavailable on this platform.
    }
    #endif
    
    // MARK: - Private Methods
    
    private func createTemporaryFile(text: String, fileName: String, format: ExportFormat) -> URL {
        let tempDirectory = FileManager.default.temporaryDirectory
        let fileURL = tempDirectory.appendingPathComponent(fileName)
        
        let content = formatText(text, for: format)
        
        do {
            try content.write(to: fileURL, atomically: true, encoding: .utf8)
        } catch {
            print("Error creating temporary file: \(error)")
        }
        
        return fileURL
    }
    
    private func createTemporaryTimingFile(content: String, fileName: String, format: TimingExportFormat) -> URL {
        let tempDirectory = FileManager.default.temporaryDirectory
        let fileURL = tempDirectory.appendingPathComponent(fileName)
        
        do {
            try content.write(to: fileURL, atomically: true, encoding: .utf8)
        } catch {
            print("Error creating temporary timing file: \(error)")
        }
        
        return fileURL
    }
    
    private func formatText(_ text: String, for format: ExportFormat) -> String {
        switch format {
        case .plainText:
            return text
        case .richText:
            return "{\\rtf1\\ansi\\deff0 {\\fonttbl {\\f0 Times New Roman;}} \\f0\\fs24 \(text)}"
        case .markdown:
            return "# Speech Transcription\n\n\(text)\n\n---\n\n*Transcribed on \(Date())*"
        }
    }
    
    private func formattedTimestamp() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        return formatter.string(from: Date())
    }
}

// MARK: - Document Picker Delegate (iOS-only)
#if os(iOS)
/// Coordinator class to handle `UIDocumentPickerViewController` delegate callbacks.
private class DocumentPickerCoordinator: NSObject, UIDocumentPickerDelegate {
    private let completion: (Bool) -> Void
    
    init(completion: @escaping (Bool) -> Void) {
        self.completion = completion
        super.init()
    }
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        completion(true)
    }
    
    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        completion(false)
    }
}
#endif 