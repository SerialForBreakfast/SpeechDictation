//
//  ThemeSettingView.swift
//  SpeechDictation
//
//  Created by AI Assistant on 7/1/24.
//
//  Displays theme selection buttons.
//

import SwiftUI
import Foundation

struct ThemeSettingView: View {
    @ObservedObject var viewModel: SpeechRecognizerViewModel

    var body: some View {
        VStack(spacing: 10) {
            Text("Theme")
                .font(.headline)
            HStack {
                ForEach(Theme.allCases) { theme in
                    Button(action: {
                        viewModel.theme = theme
                    }) {
                        Text(theme.rawValue.capitalized)
                            .padding()
                            .background(viewModel.theme == theme ? Color.blue : Color.gray)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.15))
        .cornerRadius(10)
    }
} 