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
    private let imageCropper: ImageCropper

    lazy private var cardOverlayView: CardOverlayView = {
        return CardOverlayView(frame: view.bounds)
    }()

    init(cardSide: CardSide = .front, imageCropper: ImageCropper = DefaultImageCropper()) {
        self.cardSide = cardSide
        self.imageCropper = imageCropper
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

        DispatchQueue.global().async {
            guard let finalImage = self.imageCropper.cropImage(image, quad: quad) else {
                if let imageScannerController = self.navigationController as? ImageScannerController {
                    let error = ImageScannerControllerError.ciImageCreation
                    DispatchQueue.main.async {
                        imageScannerController.imageScannerDelegate?.imageScannerController(imageScannerController, didFailWithError: error)
                    }
                }
                return
            }

            let results = ImageScannerResults(
                originalImage: image, scannedImage: finalImage, enhancedImage: nil,
                doesUserPreferEnhancedImage: false, detectedRectangle: quad
            )

            let reviewViewController = ReviewViewController(results: results, cardSide: self.cardSide)
            DispatchQueue.main.async {
                self.navigationController?.pushViewController(reviewViewController, animated: true)
            }
        }
    }
}

public protocol ImageCropper {
    func cropImage(_ image: UIImage, quad: Quadrilateral) -> UIImage?
}

final public class DefaultImageCropper: ImageCropper {
    public init() {}

    public func cropImage(_ image: UIImage, quad: Quadrilateral) -> UIImage? {
        guard let ciImage = CIImage(image: image.applyingPortraitOrientation()) else {
            return nil
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

        //        let enhancedImage = filteredImage.applyingAdaptiveThreshold()?.withFixedOrientation()

        var uiImage: UIImage!

        // Let's try to generate the CGImage from the CIImage before creating a UIImage.
        if let cgImage = CIContext(options: nil).createCGImage(filteredImage, from: filteredImage.extent) {
            uiImage = UIImage(cgImage: cgImage)
        } else {
            uiImage = UIImage(ciImage: filteredImage, scale: 1.0, orientation: .up)
        }

        let finalImage = uiImage.withFixedOrientation()
        return finalImage
    }
}
