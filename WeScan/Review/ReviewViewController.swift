//
//  ReviewViewController.swift
//  WeScan
//
//  Created by Boris Emorine on 2/25/18.
//  Copyright © 2018 WeTransfer. All rights reserved.
//

import UIKit

/// The `ReviewViewController` offers an interface to review the image after it has been cropped and deskwed according to the passed in quadrilateral.
final class ReviewViewController: UIViewController {
    
    var enhancedImageIsAvailable = false
    var isCurrentlyDisplayingEnhancedImage = false
    private let scanType: ScanType

    lazy private var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.clipsToBounds = true
        imageView.isOpaque = true
        imageView.image = results.scannedImage
        imageView.backgroundColor = .black
        imageView.contentMode = .scaleAspectFill
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    lazy private var cardOverlayView: CardOverlayView = {
        return CardOverlayView(frame: view.bounds, scanType: scanType, shadowAlpha: 0.9)
    }()
    
    lazy private var enhanceButton: UIBarButtonItem = {
        let image = UIImage(named: "enhance", in: Bundle(for: ScannerViewController.self), compatibleWith: nil)
        let button = UIBarButtonItem(image: image, style: .plain, target: self, action: #selector(toggleEnhancedImage))
        button.tintColor = .white
        return button
    }()

    lazy var doneButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(finishScan), for: .touchUpInside)
        button.setTitle("Well done!", for: .normal)
        button.layer.cornerRadius = 28
        button.backgroundColor = .white
        button.setTitleColor(.black, for: .normal)
        return button
    }()

    private var results: ImageScannerResults
    
    // MARK: - Life Cycle
    
    init(results: ImageScannerResults, scanType: ScanType = .general) {
        self.results = results
        self.scanType = scanType
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        enhancedImageIsAvailable = false// results.enhancedImage != nil
        
        setupViews()
        setupToolbar()
        setupConstraints()

        switch scanType {
        case .passport:
            title = "Passport"
        case .card(let side):
            title = side == .front ? "Front Side" : "Back Side"
        default:
            title = NSLocalizedString("wescan.review.title", tableName: nil, bundle: Bundle(for: ReviewViewController.self), value: "Review", comment: "The review title of the ReviewController")
        }

        navigationController?.navigationBar.shadowImage = UIImage()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: true)

        if enhancedImageIsAvailable {
            navigationController?.setToolbarHidden(false, animated: true)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setToolbarHidden(true, animated: true)
    }
    
    // MARK: Setups
    
    private func setupViews() {
        view.addSubview(imageView)
        view.addSubview(cardOverlayView)
        view.addSubview(doneButton)
    }
    
    private func setupToolbar() {
        guard enhancedImageIsAvailable else { return }
        
        navigationController?.toolbar.barStyle = .blackTranslucent
        
        let fixedSpace = UIBarButtonItem(barButtonSystemItem: .fixedSpace, target: nil, action: nil)
        toolbarItems = [fixedSpace, enhanceButton]
    }
    
    private func setupConstraints() {
        let imageViewConstraints = [
            imageView.topAnchor.constraint(equalTo: view.topAnchor),
            imageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            view.bottomAnchor.constraint(equalTo: imageView.bottomAnchor),
            view.leadingAnchor.constraint(equalTo: imageView.leadingAnchor)
        ]
        let doneButtonConstraints = [
            doneButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            doneButton.widthAnchor.constraint(equalToConstant: 180.0),
            doneButton.heightAnchor.constraint(equalToConstant: 56.0),
            view.bottomAnchor.constraint(equalTo: doneButton.bottomAnchor, constant: 8.0)
        ]

        NSLayoutConstraint.activate(imageViewConstraints + doneButtonConstraints)
    }
    
    // MARK: - Actions
    
    @objc private func toggleEnhancedImage() {
        guard enhancedImageIsAvailable else { return }
        if isCurrentlyDisplayingEnhancedImage {
            imageView.image = results.scannedImage
            enhanceButton.tintColor = .white
        } else {
            imageView.image = results.enhancedImage
            enhanceButton.tintColor = UIColor(red: 64.0 / 255, green: 159.0 / 255, blue: 255.0 / 255, alpha: 1.0)
        }
        
        isCurrentlyDisplayingEnhancedImage.toggle()
    }
    
    @objc private func finishScan() {
        guard let imageScannerController = navigationController as? ImageScannerController,
            let image = self.imageView.image else { return }

        let imageSize = image.size
        let bounds = cardOverlayView.bounds
        let imageRatio = imageSize.width / imageSize.height
        let boundsRatio = bounds.width / bounds.height

        let scale = imageRatio < boundsRatio ? (bounds.width / imageSize.width) : (bounds.height / imageSize.height)
        var imageFrame: CGRect
        if imageRatio > boundsRatio {
            imageFrame = CGRect(
                x: (imageSize.width - bounds.width / scale) / 2,
                y: 0,
                width: bounds.width / scale,
                height: bounds.height / scale
            )
        } else {
            imageFrame = CGRect(
                x: 0,
                y: (imageSize.height - bounds.height / scale) / 2,
                width: bounds.width / scale,
                height: bounds.height / scale
            )
        }

        var cropRect = cardOverlayView.cropArea
        cropRect = cropRect.insetBy(dx: -(cropRect.width * 0.05), dy: -(cropRect.height * 0.05))

        let rect = CGRect(
            x: imageFrame.origin.x + (cropRect.minX / scale),
            y: imageFrame.origin.y + (cropRect.minY / scale),
            width: cropRect.width / scale,
            height: cropRect.height / scale
        )

        if let image = image.scaledImage(at: rect) {
            results.scannedImage = image
        }
        results.doesUserPreferEnhancedImage = isCurrentlyDisplayingEnhancedImage

        switch scanType {
        case .card(let side):
            if side == .front {
                imageScannerController.cardFrontSide = results
                let scannerViewController = CardScannerViewController(scanType: .card(.back))
                imageScannerController.pushViewController(scannerViewController, animated: true)
            } else {
                if let frontResult = imageScannerController.cardFrontSide {
                    imageScannerController.cardScannerDelegate?
                        .cardScannerController(
                            imageScannerController,
                            didFinishScanningWithResults:
                            CardScannerResults(
                                frontSide: frontResult,
                                backSide: results
                            )
                    )
                }
            }
        case .passport:
            if let image = results.scannedImage.imageRotatedByDegrees(-90, flip: false) {
                results.scannedImage = image
            }

            imageScannerController.imageScannerDelegate?
                .imageScannerController(
                    imageScannerController,
                    didFinishScanningWithResults: results)
        default:
            imageScannerController.imageScannerDelegate?
                .imageScannerController(
                    imageScannerController,
                    didFinishScanningWithResults: results)

        }

    }

}
