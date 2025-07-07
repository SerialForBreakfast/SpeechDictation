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
    case light, dark, highContrast

    public var id: String { rawValue }
} 