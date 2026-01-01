//
//  TranscriptAuditView.swift
//  SpeechDictation
//
//  In-app audit panel for transcription events and segment merging.
//

import SwiftUI

struct TranscriptAuditView: View {
    @ObservedObject private var timingDataManager = TimingDataManager.shared
    @Environment(\.dismiss) private var dismiss
    @State private var showOnlyReplacements = false
    @State private var showOnlyFinals = false

    var body: some View {
        NavigationView {
            VStack(spacing: 12) {
                header

                if timingDataManager.auditEntries.isEmpty {
                    emptyState
                } else {
                    auditList
                }
            }
            .padding()
            .navigationTitle("Transcript Audit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Clear") {
                        timingDataManager.clearAudit()
                    }
                    .foregroundColor(.red)
                }
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Entries: \(timingDataManager.auditEntries.count)")
                        .font(.subheadline.weight(.semibold))
                    Text("Replacements: \(replacementCount)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                VStack(alignment: .leading, spacing: 4) {
                    Toggle("Only replacements", isOn: $showOnlyReplacements)
                        .toggleStyle(.switch)
                    Toggle("Only finals", isOn: $showOnlyFinals)
                        .toggleStyle(.switch)
                }
                .font(.caption)
            }

            if !timingDataManager.auditLogPath.isEmpty {
                Text("Log: \(timingDataManager.auditLogPath)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 32))
                .foregroundColor(.secondary)
            Text("No audit entries yet.")
                .font(.headline)
            Text("Start a recording or transcription to capture events.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var auditList: some View {
        List(filteredEntries.reversed()) { entry in
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(entry.event.rawValue.uppercased())
                        .font(.caption.weight(.semibold))
                        .foregroundColor(entry.replacedPriorText ? .red : .primary)
                    Spacer()
                    Text(Self.timeFormatter.string(from: entry.timestamp))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }

                HStack(spacing: 8) {
                    Text("text \(entry.textLength) (\(formatDelta(entry.textDelta)))")
                    Text("incoming segs \(entry.incomingSegmentCount)")
                    Text("stored segs \(entry.storedSegmentCount) (\(formatDelta(entry.storedSegmentDelta)))")
                }
                .font(.caption2)
                .foregroundColor(.secondary)

                if let note = entry.note, !note.isEmpty {
                    Text(note)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }

                if let text = entry.text, !text.isEmpty {
                    Text(text)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.primary)
                        .lineLimit(4)
                }
            }
            .padding(.vertical, 6)
        }
        .listStyle(.plain)
    }

    private var filteredEntries: [TranscriptAuditEntry] {
        timingDataManager.auditEntries.filter { entry in
            if showOnlyReplacements, !entry.replacedPriorText {
                return false
            }
            if showOnlyFinals, entry.event != .final {
                return false
            }
            return true
        }
    }

    private var replacementCount: Int {
        timingDataManager.auditEntries.filter { $0.replacedPriorText }.count
    }

    private func formatDelta(_ delta: Int) -> String {
        if delta > 0 {
            return "+\(delta)"
        }
        return "\(delta)"
    }

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        return formatter
    }()
}

#Preview {
    TranscriptAuditView()
}
