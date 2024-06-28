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
                let midHeight = height / 2
                let sampleCount = samples.count
                let xStride = width / CGFloat(sampleCount)
                
                path.move(to: CGPoint(x: 0, y: midHeight))
                
                for (index, sample) in samples.enumerated() {
                    let x = CGFloat(index) * xStride
                    let y = midHeight - CGFloat(sample) * midHeight
                    path.addLine(to: CGPoint(x: x, y: y))
                }
            }
            .stroke(Color.blue, lineWidth: 1)
        }
    }
}
