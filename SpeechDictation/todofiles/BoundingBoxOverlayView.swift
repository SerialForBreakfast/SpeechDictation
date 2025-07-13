//
//  BoundingBoxOverlayView.swift
//  SpeechDictation
//
//  Created by Joseph McCraw on 7/12/25.
//

import Foundation
import UIKit
import Vision

final class BoundingBoxOverlay: UIView {
    private var boxLayers: [CAShapeLayer] = []

    func show(boxes: [DetectedObject], in frame: CGRect) {
        // Remove old layers
        boxLayers.forEach { $0.removeFromSuperlayer() }
        boxLayers.removeAll()

        for box in boxes {
            let rect = VNImageRectForNormalizedRect(box.boundingBox, Int(frame.width), Int(frame.height))
            let layer = CAShapeLayer()
            layer.frame = rect
            layer.borderColor = UIColor.red.cgColor
            layer.borderWidth = 2

            let label = CATextLayer()
            label.string = "\(box.label) (\(Int(box.confidence * 100))%)"
            label.fontSize = 10
            label.foregroundColor = UIColor.white.cgColor
            label.backgroundColor = UIColor.black.withAlphaComponent(0.6).cgColor
            label.frame = CGRect(x: 0, y: 0, width: rect.width, height: 16)

            layer.addSublayer(label)
            self.layer.addSublayer(layer)
            boxLayers.append(layer)
        }
    }
}
