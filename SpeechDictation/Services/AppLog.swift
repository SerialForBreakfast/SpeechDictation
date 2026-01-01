//
//  AppLog.swift
//  SpeechDictation
//
//  Centralized logging utilities with OSLog integration, deduping, and optional verbose mode.
//

import Foundation
import os

enum AppLog {
    static let subsystem = Bundle.main.bundleIdentifier ?? "SpeechDictation"

    enum Category: String {
        case audioSession = "audio.session"
        case recording = "audio.recording"
        case transcription = "speech.transcription"
        case timing = "speech.timing"
        case secureRecording = "speech.secure"
        case playback = "audio.playback"
        case export = "export"
        case storage = "storage"
        case models = "models"
        case camera = "camera"
        case ui = "ui"
        case auth = "security.auth"
        case download = "download"
    }

    static func debug(
        _ category: Category,
        _ message: String,
        dedupeInterval: TimeInterval? = nil,
        verboseOnly: Bool = false
    ) {
        log(category, message, level: .debug, dedupeInterval: dedupeInterval, verboseOnly: verboseOnly)
    }

    static func info(
        _ category: Category,
        _ message: String,
        dedupeInterval: TimeInterval? = nil,
        verboseOnly: Bool = false
    ) {
        log(category, message, level: .info, dedupeInterval: dedupeInterval, verboseOnly: verboseOnly)
    }

    static func notice(
        _ category: Category,
        _ message: String,
        dedupeInterval: TimeInterval? = nil,
        verboseOnly: Bool = false
    ) {
        log(category, message, level: .notice, dedupeInterval: dedupeInterval, verboseOnly: verboseOnly)
    }

    static func error(
        _ category: Category,
        _ message: String,
        dedupeInterval: TimeInterval? = nil,
        verboseOnly: Bool = false
    ) {
        log(category, message, level: .error, dedupeInterval: dedupeInterval, verboseOnly: verboseOnly)
    }

    static func fault(
        _ category: Category,
        _ message: String,
        dedupeInterval: TimeInterval? = nil,
        verboseOnly: Bool = false
    ) {
        log(category, message, level: .fault, dedupeInterval: dedupeInterval, verboseOnly: verboseOnly)
    }

    static var isVerboseEnabled: Bool {
        let env = ProcessInfo.processInfo.environment["SPEECHDICTATION_VERBOSE_LOGGING"] == "1"
        let defaults = UserDefaults.standard.bool(forKey: "SpeechDictation.verboseLogging")
        return env || defaults
    }

    fileprivate enum LogLevel: String {
        case debug
        case info
        case notice
        case error
        case fault
    }

    private static func log(
        _ category: Category,
        _ message: String,
        level: LogLevel,
        dedupeInterval: TimeInterval?,
        verboseOnly: Bool
    ) {
        if verboseOnly && !isVerboseEnabled {
            return
        }

        if let interval = dedupeInterval {
            let key = LogDebounceKey(category: category, level: level, message: message)
            if !LogDebouncer.shared.shouldLog(key: key, interval: interval) {
                return
            }
        }

        let logger = Logger(subsystem: subsystem, category: category.rawValue)
        switch level {
        case .debug:
            logger.debug("\(message, privacy: .public)")
        case .info:
            logger.info("\(message, privacy: .public)")
        case .notice:
            logger.notice("\(message, privacy: .public)")
        case .error:
            logger.error("\(message, privacy: .public)")
        case .fault:
            logger.fault("\(message, privacy: .public)")
        }
    }
}

private struct LogDebounceKey: Hashable {
    let category: AppLog.Category
    let level: String
    let message: String

    init(category: AppLog.Category, level: AppLog.LogLevel, message: String) {
        self.category = category
        self.level = level.rawValue
        self.message = message
    }
}

private final class LogDebouncer {
    static let shared = LogDebouncer()
    private let lock = OSAllocatedUnfairLock(initialState: [LogDebounceKey: Date]())

    func shouldLog(key: LogDebounceKey, interval: TimeInterval) -> Bool {
        let now = Date()
        return lock.withLock { state in
            if let last = state[key], now.timeIntervalSince(last) < interval {
                return false
            }
            state[key] = now
            return true
        }
    }
}
