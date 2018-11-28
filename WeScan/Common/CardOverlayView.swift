//
//  CardOverlayView.swift
//  WeScan
//
//  Created by Chingis Gomboev on 16/11/2018.
//  Copyright © 2018 Osome Pte. Ltd. All rights reserved.
//

import UIKit
// card size ratio 54×86 (85.60 × 53.98) 1.586.

final class CardOverlayView: UIView {

    private let cardRatio: CGFloat = 1.586

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.isUserInteractionEnabled = false
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    lazy private var holeLayer: CAShapeLayer = {
        let layer = CAShapeLayer()
        layer.fillColor = UIColor.init(white: 0, alpha: 0.5).cgColor
        layer.strokeColor = UIColor.white.cgColor
        layer.lineWidth = 1.0
        return layer
    }()

    override func layoutSubviews() {
        super.layoutSubviews()

        let path = UIBezierPath(roundedRect: bounds.insetBy(dx: -1, dy: -1), cornerRadius: 0)

        let origin = CGPoint(x: 20, y: bounds.height / 4)
        let width = bounds.width - origin.x * 2
        let height = width / cardRatio
        let rect = CGRect(origin: origin, size: CGSize(width: width, height: height))

        let holePath = UIBezierPath(
            roundedRect: rect,
            cornerRadius: 16)
        path.append(holePath)
        path.usesEvenOddFillRule = true


        let fillLayer = holeLayer
        fillLayer.path = path.cgPath
        fillLayer.fillRule = CAShapeLayerFillRule.evenOdd
//        fillLayer.opacity = 0.5
        layer.addSublayer(fillLayer)
    }

}

