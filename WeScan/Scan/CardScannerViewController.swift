//
//  CardScannerViewController.swift
//  WeScan
//
//  Created by Chingis Gomboev on 29/11/2018.
//  Copyright © 2018 WeTransfer. All rights reserved.
//

import UIKit

enum CardSide {
    case front, back
}

final class CardScannerViewController: ScannerViewController {

    private let cardSide: CardSide

    lazy private var cardOverlayView: CardOverlayView = {
        return CardOverlayView(frame: view.bounds)
    }()

    init(cardSide: CardSide = .front) {
        self.cardSide = cardSide
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }


    override func viewDidLoad() {
        super.viewDidLoad()
        view.insertSubview(cardOverlayView, belowSubview: shutterButton)
        cardOverlayView.setText(cardSide == .front ? "Front side" : "Back side")
        shutterButton.isHidden = true
    }

    override func handleImage(_ image: UIImage, quad: Quadrilateral?) {
        let quad = quad ?? EditScanViewController.defaultQuad(forImage: image)
        guard let ciImage = CIImage(image: image.applyingPortraitOrientation()) else {
            if let imageScannerController = navigationController as? ImageScannerController {
                let error = ImageScannerControllerError.ciImageCreation
                imageScannerController.imageScannerDelegate?.imageScannerController(imageScannerController, didFailWithError: error)
            }
            return
        }

        let scaledQuad = quad

        var cartesianScaledQuad = scaledQuad.toCartesian(withHeight: image.size.height)
        cartesianScaledQuad.reorganize()

        let filteredImage = ciImage.applyingFilter("CIPerspectiveCorrection", parameters: [
            "inputTopLeft": CIVector(cgPoint: cartesianScaledQuad.bottomLeft),
            "inputTopRight": CIVector(cgPoint: cartesianScaledQuad.bottomRight),
            "inputBottomLeft": CIVector(cgPoint: cartesianScaledQuad.topLeft),
            "inputBottomRight": CIVector(cgPoint: cartesianScaledQuad.topRight)
            ])

        let enhancedImage = filteredImage.applyingAdaptiveThreshold()?.withFixedOrientation()

        var uiImage: UIImage!

        // Let's try to generate the CGImage from the CIImage before creating a UIImage.
        if let cgImage = CIContext(options: nil).createCGImage(filteredImage, from: filteredImage.extent) {
            uiImage = UIImage(cgImage: cgImage)
        } else {
            uiImage = UIImage(ciImage: filteredImage, scale: 1.0, orientation: .up)
        }

        let finalImage = uiImage.withFixedOrientation()

        let results = ImageScannerResults(originalImage: image, scannedImage: finalImage, enhancedImage: enhancedImage, doesUserPreferEnhancedImage: false, detectedRectangle: scaledQuad)
        let reviewViewController = ReviewViewController(results: results, cardSide: cardSide)
        navigationController?.pushViewController(reviewViewController, animated: true)

    }
}
