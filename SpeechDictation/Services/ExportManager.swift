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
/// Supports both basic text formats and timing-based formats for professional workflows
class ExportManager {
    static let shared = ExportManager()
    
    private init() {}

    // Retain active document-picker coordinators until the picker completes to
    // avoid premature deallocation which can cause UI hangs and missing
    // delegate callbacks.
#if os(iOS)
    @MainActor
    private var activeCoordinators: [DocumentPickerCoordinator] = []

    @MainActor
    private func addCoordinator(_ coordinator: DocumentPickerCoordinator) {
        activeCoordinators.append(coordinator)
    }

    @MainActor
    private func removeCoordinator(_ coordinator: DocumentPickerCoordinator) {
        activeCoordinators.removeAll { $0 === coordinator }
    }
#endif
    
    /// Export format options for basic text export
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
        
        var displayName: String {
            switch self {
            case .plainText: return "Plain Text"
            case .richText: return "Rich Text"
            case .markdown: return "Markdown"
            }
        }
        
        var description: String {
            switch self {
            case .plainText: return "Simple text file"
            case .richText: return "Formatted text with styling"
            case .markdown: return "Markdown formatted text"
            }
        }
    }
    
    /// Timing export format options for professional workflows
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
        
        var displayName: String {
            switch self {
            case .srt: return "SRT (SubRip)"
            case .vtt: return "VTT (WebVTT)"
            case .ttml: return "TTML (Timed Text)"
            case .json: return "JSON (Timing Data)"
            }
        }
        
        var description: String {
            switch self {
            case .srt: return "Standard subtitle format for video editing"
            case .vtt: return "Web video subtitle format"
            case .ttml: return "Professional timed text markup"
            case .json: return "Structured timing data for developers"
            }
        }
    }
    
    // MARK: - Basic Text Export Methods
    
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

        // Off-load heavy file generation to a background queue to prevent UI hangs.
        DispatchQueue.global(qos: .userInitiated).async {
            let tempURL = self.createTemporaryFile(text: text, fileName: fileName, format: format)

            #if os(iOS)
            Task { @MainActor in
                var coordinatorRef: DocumentPickerCoordinator?
                let wrapper: (Bool) -> Void = { [weak self] success in
                    if let coord = coordinatorRef {
                        self?.removeCoordinator(coord)
                    }
                    completion(success)
                }
                let coordinator = DocumentPickerCoordinator(completion: wrapper)
                coordinatorRef = coordinator

                let picker = UIDocumentPickerViewController(forExporting: [tempURL])
                picker.delegate = coordinator

                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let window = windowScene.windows.first {
                    self.addCoordinator(coordinator)
                    window.rootViewController?.present(picker, animated: true)
                } else {
                    completion(false)
                }
            }
            #else
            completion(false)
            #endif
        }
    }
    
    // MARK: - Timing Data Export Methods
    
    /// Generate timing data content for a specific format
    /// - Parameters:
    ///   - session: Audio recording session with timing data
    ///   - format: Timing export format
    /// - Returns: Formatted timing data string
    func generateTimingDataContent(from session: AudioRecordingSession, format: TimingExportFormat) -> String {
        switch format {
        case .srt:
            return generateSRTContent(from: session)
        case .vtt:
            return generateVTTContent(from: session)
        case .ttml:
            return generateTTMLContent(from: session)
        case .json:
            return generateJSONContent(from: session)
        }
    }
    
    /// Save timing data to Files app
    /// - Parameters:
    ///   - session: Audio recording session with timing data
    ///   - format: Timing export format
    ///   - completion: Success callback
    func saveTimingDataToFiles(session: AudioRecordingSession, format: TimingExportFormat, completion: @escaping (Bool) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            let timingData = self.generateTimingDataContent(from: session, format: format)
            let fileName = "timing_data_\(self.formattedTimestamp()).\(format.fileExtension)"
            let tempURL = self.createTemporaryTimingFile(content: timingData, fileName: fileName, format: format)

            #if os(iOS)
            Task { @MainActor in
                var coordinatorRef: DocumentPickerCoordinator?
                let wrapper: (Bool) -> Void = { [weak self] success in
                    if let coord = coordinatorRef {
                        self?.removeCoordinator(coord)
                    }
                    completion(success)
                }
                let coordinator = DocumentPickerCoordinator(completion: wrapper)
                coordinatorRef = coordinator

                let picker = UIDocumentPickerViewController(forExporting: [tempURL])
                picker.delegate = coordinator

                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let window = windowScene.windows.first {
                    self.addCoordinator(coordinator)
                    window.rootViewController?.present(picker, animated: true)
                } else {
                    completion(false)
                }
            }
            #else
            completion(false)
            #endif
        }
    }
    
    /// Export audio file with timing data
    /// - Parameters:
    ///   - session: Audio recording session with timing data
    ///   - timingFormat: Timing export format
    ///   - completion: Success callback
    func exportAudioWithTimingData(session: AudioRecordingSession, timingFormat: TimingExportFormat, completion: @escaping (Bool) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            let timingData = self.generateTimingDataContent(from: session, format: timingFormat)
            let timingFileName = "timing_data_\(self.formattedTimestamp()).\(timingFormat.fileExtension)"
            let timingURL = self.createTemporaryTimingFile(content: timingData, fileName: timingFileName, format: timingFormat)

            guard let audioURL = session.audioFileURL else {
                completion(false)
                return
            }

            #if os(iOS)
            Task { @MainActor in
                var coordinatorRef: DocumentPickerCoordinator?
                let wrapper: (Bool) -> Void = { [weak self] success in
                    if let coord = coordinatorRef {
                        self?.removeCoordinator(coord)
                    }
                    completion(success)
                }
                let coordinator = DocumentPickerCoordinator(completion: wrapper)
                coordinatorRef = coordinator

                let picker = UIDocumentPickerViewController(forExporting: [audioURL, timingURL])
                picker.delegate = coordinator

                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let window = windowScene.windows.first {
                    self.addCoordinator(coordinator)
                    window.rootViewController?.present(picker, animated: true)
                } else {
                    completion(false)
                }
            }
            #else
            completion(false)
            #endif
        }
    }
    
    // MARK: - Share Sheet Methods
    
    /// Present system share sheet for basic text (iOS-only)
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
    ///   - session: Audio recording session with timing data
    ///   - format: Timing export format
    ///   - sourceView: Source view for iPad presentation (optional)
    func presentTimingDataShareSheet(session: AudioRecordingSession, format: TimingExportFormat, from sourceView: UIView?) {
        let timingData = generateTimingDataContent(from: session, format: format)
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
    ///   - session: Audio recording session with timing data
    ///   - timingFormat: Timing export format
    ///   - sourceView: Source view for iPad presentation (optional)
    func presentAudioWithTimingDataShareSheet(session: AudioRecordingSession, timingFormat: TimingExportFormat, from sourceView: UIView?) {
        let timingData = generateTimingDataContent(from: session, format: timingFormat)
        let timingFileName = "timing_data_\(formattedTimestamp()).\(timingFormat.fileExtension)"
        let timingURL = createTemporaryTimingFile(content: timingData, fileName: timingFileName, format: timingFormat)
        
        guard let audioURL = session.audioFileURL else {
            return
        }
        
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
    
    func presentTimingDataShareSheet(session: AudioRecordingSession, format: TimingExportFormat, from sourceView: Any?) {
        // Share sheet unavailable on this platform.
    }
    
    func presentAudioWithTimingDataShareSheet(session: AudioRecordingSession, timingFormat: TimingExportFormat, from sourceView: Any?) {
        // Share sheet unavailable on this platform.
    }
    #endif
    
    // MARK: - Private Format Generation Methods
    
    /// Generates grouped SRT content that is easier to read and standards-compliant.
    ///
    /// Rules:
    ///   • Combine consecutive `TranscriptionSegment`s until one of the limits is hit:
    ///       1. Maximum caption duration (`maxCaptionDuration`, default 2 s).
    ///       2. Maximum character length (`maxCaptionChars`, default 42).
    ///       3. The current segment text ends with a sentence-terminating punctuation mark (., !, ?).
    ///   • Identical consecutive captions are de-duplicated to avoid partial-result overlap.
    ///
    /// ‑ Parameter session: The recording session containing word-level segments.
    /// ‑ Returns: Well-formed SRT text.
    private func generateSRTContent(from session: AudioRecordingSession) -> String {
        let maxCaptionDuration: TimeInterval = 2.0
        let maxCaptionChars: Int = 42

        var captions: [(start: TimeInterval, end: TimeInterval, text: String)] = []

        var currentStart: TimeInterval?
        var currentEnd: TimeInterval?
        var currentText: String = ""

        func flushCurrent() {
            guard let start = currentStart, let end = currentEnd, !currentText.isEmpty else { return }
            // Avoid duplicate consecutive captions
            if captions.last?.text.trimmingCharacters(in: .whitespacesAndNewlines) != currentText.trimmingCharacters(in: .whitespacesAndNewlines) {
                captions.append((start, end, currentText))
            }
            currentStart = nil
            currentEnd = nil
            currentText = ""
        }

        for segment in session.segments {
            if currentStart == nil {
                currentStart = segment.startTime
            }

            // Proposed combined text if we append this segment
            let proposedText = currentText.isEmpty ? segment.text : currentText + " " + segment.text
            let proposedDuration = segment.endTime - (currentStart ?? segment.startTime)

            let endsWithSentenceBreak = segment.text.last.map { ".$!?".contains($0) } ?? false

            let exceedsDuration = proposedDuration > maxCaptionDuration
            let exceedsChars = proposedText.count > maxCaptionChars

            if exceedsDuration || exceedsChars || endsWithSentenceBreak {
                // Flush the caption built so far, start new one with this segment
                flushCurrent()
                currentStart = segment.startTime
                currentText = segment.text
                currentEnd = segment.endTime
            } else {
                // Append to current caption
                currentText = proposedText
                currentEnd = segment.endTime
            }
        }

        // Flush remaining caption
        flushCurrent()

        // Build SRT string
        var result = ""
        for (index, cap) in captions.enumerated() {
            result += "\(index + 1)\n"
            result += "\(formatSRTTime(cap.start)) --> \(formatSRTTime(cap.end))\n"
            result += "\(cap.text)\n\n"
        }
        return result
    }
    
    private func generateVTTContent(from session: AudioRecordingSession) -> String {
        var content = "WEBVTT\n\n"
        for segment in session.segments {
            content += "\(formatVTTTime(segment.startTime)) --> \(formatVTTTime(segment.endTime))\n"
            content += "\(segment.text)\n\n"
        }
        return content
    }
    
    private func generateTTMLContent(from session: AudioRecordingSession) -> String {
        var content = """
        <?xml version="1.0" encoding="UTF-8"?>
        <tt xmlns="http://www.w3.org/ns/ttml">
        <body>
        """
        
        for segment in session.segments {
            content += "<p begin=\"\(formatTTMLTime(segment.startTime))\" end=\"\(formatTTMLTime(segment.endTime))\">\(segment.text)</p>\n"
        }
        
        content += """
        </body>
        </tt>
        """
        return content
    }
    
    private func generateJSONContent(from session: AudioRecordingSession) -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        
        do {
            let data = try encoder.encode(session)
            return String(data: data, encoding: .utf8) ?? ""
        } catch {
            return "{\"error\": \"Failed to encode session\"}"
        }
    }
    
    // MARK: - Private Helper Methods
    
    private func createTemporaryFile(text: String, fileName: String, format: ExportFormat) -> URL {
        let tempDirectory = FileManager.default.temporaryDirectory
        let fileURL = tempDirectory.appendingPathComponent(fileName)
        
        let content = formatText(text, for: format)
        
        do {
            try content.write(to: fileURL, atomically: true, encoding: .utf8)
        } catch {
            AppLog.error(.export, "Error creating temporary file: \(error)")
        }
        
        return fileURL
    }
    
    private func createTemporaryTimingFile(content: String, fileName: String, format: TimingExportFormat) -> URL {
        let tempDirectory = FileManager.default.temporaryDirectory
        let fileURL = tempDirectory.appendingPathComponent(fileName)
        
        do {
            try content.write(to: fileURL, atomically: true, encoding: .utf8)
        } catch {
            AppLog.error(.export, "Error creating temporary timing file: \(error)")
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
    
    private func formatSRTTime(_ time: TimeInterval) -> String {
        let hours = Int(time) / 3600
        let minutes = (Int(time) % 3600) / 60
        let seconds = Int(time) % 60
        let milliseconds = Int((time.truncatingRemainder(dividingBy: 1)) * 1000)
        return String(format: "%02d:%02d:%02d,%03d", hours, minutes, seconds, milliseconds)
    }
    
    private func formatVTTTime(_ time: TimeInterval) -> String {
        let hours = Int(time) / 3600
        let minutes = (Int(time) % 3600) / 60
        let seconds = Int(time) % 60
        let milliseconds = Int((time.truncatingRemainder(dividingBy: 1)) * 1000)
        return String(format: "%02d:%02d:%02d.%03d", hours, minutes, seconds, milliseconds)
    }
    
    private func formatTTMLTime(_ time: TimeInterval) -> String {
        let hours = Int(time) / 3600
        let minutes = (Int(time) % 3600) / 60
        let seconds = Int(time) % 60
        let milliseconds = Int((time.truncatingRemainder(dividingBy: 1)) * 1000)
        return String(format: "%02d:%02d:%02d.%03d", hours, minutes, seconds, milliseconds)
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
        controller.dismiss(animated: true) {
            self.completion(true)
        }
    }

    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        controller.dismiss(animated: true) {
            self.completion(false)
        }
    }
}
#endif 
