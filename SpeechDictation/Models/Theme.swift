//
//  Theme.swift
//  SpeechDictation
//
//  Created by AI Assistant on 7/1/24.
//
//  A shared enumeration for colour/UI themes used throughout the application. Placed in
//  `Models` so non-UI layers (e.g. view-models) can reference it without importing a UI view
//  file.
//
//  Extend cases here if additional appearance modes are added.
//

import Foundation

public enum Theme: String, CaseIterable, Identifiable {
    case system
    case light
    case dark
    case highContrast

    public var id: String { rawValue }
    
    public var displayName: String {
        switch self {
        case .system:
            return "System"
        case .light:
            return "Light"
        case .dark:
            return "Dark"
        case .highContrast:
            return "High Contrast"
        }
    }
}
