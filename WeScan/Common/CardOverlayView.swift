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

        let bezierPath = UIBezierPath(
            roundedRect: self.bounds.inset(
                by: UIEdgeInsets(top: 200, left: 40, bottom: 200, right: 40)
            ),
            cornerRadius: 8)

        //        circleLayer.frame = rect
        //        circleLayer.path = bezierPath.cgPath
        //
        //        image?.draw(in: rect)
    }
    override func draw(_ rect: CGRect) {
        super.draw(rect)

    }

}

