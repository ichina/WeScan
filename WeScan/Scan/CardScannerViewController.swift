//
//  CardScannerViewController.swift
//  WeScan
//
//  Created by Chingis Gomboev on 29/11/2018.
//  Copyright © 2018 WeTransfer. All rights reserved.
//

import UIKit

public enum CardSide {
    case front, back
}

final class CardScannerViewController: ScannerViewController {

    private var imageCropper: ImageCropper {
        return PassportImageCropper()
    }

    private let scanType: ScanType

    lazy private var cardOverlayView: CardOverlayView = {
        return CardOverlayView(frame: view.bounds, scanType: scanType)
    }()

    lazy private var libraryButton: UIButton = {
        let button = UIButton()
        button.setTitle("Library", for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(openLibraryImageScannerController), for: .touchUpInside)
        return button
    }()


    init(scanType: ScanType = .passport) {
        self.scanType = scanType
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }


    override func viewDidLoad() {
        super.viewDidLoad()

        view.insertSubview(cardOverlayView, belowSubview: shutterButton)
        switch scanType {
        case .card(let side):
            cardOverlayView.setTitleText(side == .front ? "Front side" : "Back side")
            cardOverlayView.setDetailText("Make sure your card is straight\non the camera")

        case .passport:
            cardOverlayView.setTitleText("Passport")
        default: break
        }
        toolbar.isHidden = true

        view.addSubview(libraryButton)
        setupLibraryConstraints()

    }

    private func setupLibraryConstraints() {
        var libraryButtonConstraints = [NSLayoutConstraint]()

        if #available(iOS 11.0, *) {
            libraryButtonConstraints = [
                libraryButton.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: 24.0),
                view.safeAreaLayoutGuide.bottomAnchor.constraint(equalTo: libraryButton.bottomAnchor, constant: (65.0 / 2) - 10.0)
            ]
        } else {
            libraryButtonConstraints = [
                libraryButton.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 24.0),
                view.bottomAnchor.constraint(equalTo: libraryButton.bottomAnchor, constant: (65.0 / 2) - 10.0)
            ]

        }
        NSLayoutConstraint.activate(libraryButtonConstraints)
    }

    override func handleImage(_ image: UIImage, quad: Quadrilateral?) {
        let quad = quad ?? EditScanViewController.defaultQuad(forImage: image)

        DispatchQueue.global().async {
            guard let finalImage = self.imageCropper.cropImage(image, quad: quad) else {
                if let imageScannerController = self.navigationController as? ImageScannerController {
                    let error = ImageScannerControllerError.ciImageCreation
                    DispatchQueue.main.async {
                        imageScannerController.imageScannerDelegate?
                            .imageScannerController(imageScannerController, didFailWithError: error)
                    }
                }
                return
            }

            let results = ImageScannerResults(
                originalImage: image, scannedImage: finalImage, enhancedImage: nil,
                doesUserPreferEnhancedImage: false, detectedRectangle: quad
            )

            let reviewViewController = ReviewViewController(results: results, scanType: self.scanType)
            DispatchQueue.main.async {
                self.navigationController?.pushViewController(reviewViewController, animated: true)
            }
        }
    }

    @objc private func openLibraryImageScannerController() {
        let imagePicker =  UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = .photoLibrary
        imagePicker.navigationBar.barStyle = .black
        imagePicker.navigationBar.barTintColor = .black
//        imagePicker.navigationBar.isTranslucent = false
        imagePicker.navigationBar.tintColor = .white

        present(imagePicker, animated: true, completion: nil)

    }

}

extension CardScannerViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController,
                               didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {

        if let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            let vc = createCropVC(image)
            picker.pushViewController(vc, animated: true)
            return
        }
        picker.dismiss(animated: true, completion: nil)
    }

    private func createCropVC(_ image: UIImage) -> UIViewController {
        PKCCropHelper.shared.isNavigationBarShow = true
        let cropVC = PKCCropViewController(image, scanType: scanType)
        cropVC.delegate = self
        return cropVC
    }
}

extension CardScannerViewController: PKCCropDelegate {
    func pkcCropImage(_ image: UIImage?, originalImage: UIImage?) {
        guard let image = image else { return }
        if let imageScannerController = self.navigationController as? ImageScannerController {

            var results = ImageScannerResults(
                originalImage: image, scannedImage: image, enhancedImage: nil,
                doesUserPreferEnhancedImage: false, detectedRectangle: EditScanViewController.defaultQuad(forImage: image)
            )

            if case .passport = scanType, let newImage = image.imageRotatedByDegrees(-90, flip: false) {
                results.originalImage = newImage
            }

            imageScannerController.imageScannerDelegate?
                .imageScannerController(
                    imageScannerController,
                    didFinishScanningWithResults: results)
        }
    }

    //If crop is canceled
    func pkcCropCancel(_ viewController: PKCCropViewController) {
        viewController.navigationController?.popViewController(animated: true)
    }

    //Successful crop
    func pkcCropComplete(_ viewController: PKCCropViewController) {
        if let vc = viewController.presentingViewController {
            vc.dismiss(animated: true) { [weak self] in
                self?.dismiss(animated: true, completion: nil)
            }
            return
        }
        viewController.dismiss(animated: true, completion: nil)
    }

}
