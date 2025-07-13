//
//  BoundingBoxOverlayView.swift
//  SpeechDictation
//
//  Created by Joseph McCraw on 7/12/25.
//

import Foundation
import UIKit
import Vision

/// UIKit-based bounding box overlay with dark/light mode support
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
            layer.borderColor = boundingBoxColor.cgColor
            layer.borderWidth = 2

            let label = CATextLayer()
            label.string = "\(box.label) (\(Int(box.confidence * 100))%)"
            label.fontSize = 10
            label.foregroundColor = labelTextColor.cgColor
            label.backgroundColor = labelBackgroundColor.cgColor
            label.frame = CGRect(x: 0, y: 0, width: rect.width, height: 16)

            layer.addSublayer(label)
            self.layer.addSublayer(layer)
            boxLayers.append(layer)
        }
    }
    
    // MARK: - Dark/Light Mode Color Helpers
    
    /// Bounding box border color that adapts to dark/light mode
    private var boundingBoxColor: UIColor {
        if #available(iOS 13.0, *) {
            return UIColor { traitCollection in
                switch traitCollection.userInterfaceStyle {
                case .dark:
                    return UIColor.systemGreen.withAlphaComponent(0.9)
                case .light:
                    return UIColor.systemGreen.withAlphaComponent(0.8)
                default:
                    return UIColor.systemGreen.withAlphaComponent(0.8)
                }
            }
        } else {
            return UIColor.green.withAlphaComponent(0.8)
        }
    }
    
    /// Label text color that adapts to dark/light mode
    private var labelTextColor: UIColor {
        return UIColor.white // White text works well on both dark and light backgrounds
    }
    
    /// Label background color that adapts to dark/light mode
    private var labelBackgroundColor: UIColor {
        if #available(iOS 13.0, *) {
            return UIColor { traitCollection in
                switch traitCollection.userInterfaceStyle {
                case .dark:
                    return UIColor.black.withAlphaComponent(0.8)
                case .light:
                    return UIColor.black.withAlphaComponent(0.6)
                default:
                    return UIColor.black.withAlphaComponent(0.6)
                }
            }
        } else {
            return UIColor.black.withAlphaComponent(0.6)
        }
    }
}
