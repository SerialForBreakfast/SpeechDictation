//
//  ThemeSettingView.swift
//  SpeechDictation
//
//  Created by AI Assistant on 7/1/24.
//
//  Displays theme selection buttons with proper dark/light mode support.
//

import SwiftUI
import Foundation

struct ThemeSettingView: View {
    @ObservedObject var viewModel: SpeechRecognizerViewModel
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: 10) {
            Text("Theme")
                .font(.headline)
                .foregroundColor(.primary)
            
            HStack {
                ForEach(Theme.allCases) { theme in
                    Button(action: {
                        viewModel.theme = theme
                        AppLog.info(.ui, "Theme selected: \(theme.displayName)")
                    }) {
                        Text(theme.displayName)
                            .font(.system(size: 16, weight: .medium))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(buttonBackgroundColor(for: theme))
                            .foregroundColor(buttonTextColor(for: theme))
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(buttonBorderColor(for: theme), lineWidth: 1)
                            )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .padding()
        .background(sectionBackgroundColor)
        .cornerRadius(10)
    }
    
    // MARK: - Color Helpers
    
    private var sectionBackgroundColor: Color {
        Color(UIColor.secondarySystemBackground)
    }
    
    private func buttonBackgroundColor(for theme: Theme) -> Color {
        let isSelected = viewModel.theme == theme
        
        if isSelected {
            return Color.accentColor
        } else {
            return Color(UIColor.tertiarySystemBackground)
        }
    }
    
    private func buttonTextColor(for theme: Theme) -> Color {
        let isSelected = viewModel.theme == theme
        
        if isSelected {
            return Color.white
        } else {
            return Color.primary
        }
    }
    
    private func buttonBorderColor(for theme: Theme) -> Color {
        let isSelected = viewModel.theme == theme
        
        if isSelected {
            return Color.accentColor.opacity(0.8)
        } else {
            return Color(UIColor.separator)
        }
    }
} 
