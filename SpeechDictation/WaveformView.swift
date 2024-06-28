//
//  WaveformView.swift
//  SpeechDictation
//
//  Created by Joseph McCraw on 6/27/24.
//

import SwiftUI

struct WaveformView: View {
    var samples: [Float]
    
    var body: some View {
        GeometryReader { geometry in
            Path { path in
                let width = geometry.size.width
                let height = geometry.size.height
                let midY = height / 2
                let sampleCount = samples.count
                let step = width / CGFloat(sampleCount)
                
                for i in 0..<sampleCount {
                    let x = CGFloat(i) * step
                    let y = midY + CGFloat(samples[i]) * midY
                    if i == 0 {
                        path.move(to: CGPoint(x: x, y: y))
                    } else {
                        path.addLine(to: CGPoint(x: x, y: y))
                    }
                }
            }
            .stroke(Color.blue, lineWidth: 1)
        }
    }
}
