//
//  CardOverlayView.swift
//  WeScan
//
//  Created by Chingis Gomboev on 16/11/2018.
//  Copyright © 2018 Osome Pte. Ltd. All rights reserved.
//

import UIKit

final class CardOverlayView: UIView {

    private let shadowAlpha: CGFloat

    private var cardRatio: CGFloat {
        if case .card(_) = scanType {
            return 1.586
        } else {
            return 0.66
        }
    }

    let template: UIImageView = {
        let view = UIImageView()
        view.image = UIImage(named: "passportOverlay", in: Bundle(for: CardOverlayView.self), compatibleWith: nil)
        return view;
    }()

    private let scanType: ScanType

    let titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.white
        label.font = UIFont.systemFont(ofSize: 28, weight: .heavy)
        label.text = ""
        label.textAlignment = .center
        return label
    }()

    let detailLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.white
        label.font = UIFont.systemFont(ofSize: 16)
        label.text = ""
        label.numberOfLines = 0
        label.textAlignment = .center
        return label
    }()


    init(frame: CGRect, scanType: ScanType = .general, shadowAlpha: CGFloat = 0.5) {
        self.scanType = scanType
        self.shadowAlpha = shadowAlpha
        super.init(frame: frame)
        self.isUserInteractionEnabled = false
        self.addSubview(titleLabel)
        self.addSubview(detailLabel)

        if case .passport = scanType {
            self.addSubview(template)
        }

    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    lazy private var holeLayer: CAShapeLayer = {
        let layer = CAShapeLayer()
        layer.fillColor = UIColor(white: 0, alpha: shadowAlpha).cgColor
        if case .passport = scanType {
            layer.strokeColor = UIColor(white: 1, alpha: 0.0).cgColor
        } else {
            layer.strokeColor = UIColor(white: 1, alpha: 0.8).cgColor
        }
        layer.lineWidth = 1.0
        return layer
    }()

    override func layoutSubviews() {
        super.layoutSubviews()

        let path = UIBezierPath(roundedRect: bounds.insetBy(dx: -1, dy: -1), cornerRadius: 0)

        let rect = createRect(for: scanType)

        var holePath: UIBezierPath

        var radius: CGFloat = 16
        switch scanType {
        case .passport:
            radius = 10
            var cornerMask = UIRectCorner()
            cornerMask.insert(.topLeft)
            cornerMask.insert(.bottomLeft)
            holePath = UIBezierPath(roundedRect: rect,
                                    byRoundingCorners: cornerMask,
                                    cornerRadii: CGSize(width: radius, height: radius))
            detailLabel.frame = CGRect(x: rect.origin.x + 24, y: rect.maxY - 70, width: rect.width - 48, height: 60);

        default:
            holePath = UIBezierPath(
                roundedRect: rect,
                cornerRadius: radius)
            detailLabel.frame = CGRect(x: rect.origin.x, y: rect.maxY + 40, width: rect.width, height: 80);
        }

        path.append(holePath)
        path.usesEvenOddFillRule = true

        self.cropArea = rect

        let fillLayer = holeLayer
        fillLayer.path = path.cgPath
        fillLayer.fillRule = CAShapeLayerFillRule.evenOdd
        layer.addSublayer(fillLayer)

        titleLabel.frame = CGRect(x: 40, y: 20 + (isEarsPhone ? 20 : 0), width: self.frame.width - 80, height: 40);
        bringSubviewToFront(titleLabel)

        bringSubviewToFront(detailLabel)

        guard template.superview != nil else { return }

        template.frame = rect
    }

    var cropArea: CGRect = .zero

    func setTitleText(_ text: String) {
        titleLabel.text = text
    }
    func setDetailText(_ text: String) {
        detailLabel.text = text
        if !text.isEmpty, case .passport = scanType {
            detailLabel.backgroundColor = UIColor(white: 0, alpha: 0.5)
            detailLabel.layer.cornerRadius = 10
            detailLabel.clipsToBounds = true
        }
    }

    private func createRect(for type: ScanType) -> CGRect {
        switch type {
        case .card(_):
            let origin = CGPoint(x: 10, y: bounds.height / 4)
            let width = bounds.width - origin.x * 2
            let height = width / cardRatio
            let rect = CGRect(origin: origin, size: CGSize(width: width, height: height))
            return rect
        case .passport:
            let leftMargin: CGFloat = 28
            let width = bounds.width - leftMargin * 2
            let height = width / cardRatio
            let origin = CGPoint(x: leftMargin, y: (bounds.height - height) / 2)
            let rect = CGRect(origin: origin, size: CGSize(width: width, height: height))
            return rect
        default:
            return .zero
        }
    }

}

var isEarsPhone: Bool {
    let arr: [CGFloat] = [2436, 2688, 1792]
    return UIDevice().userInterfaceIdiom == .phone && arr.contains(UIScreen.main.nativeBounds.height)
}


