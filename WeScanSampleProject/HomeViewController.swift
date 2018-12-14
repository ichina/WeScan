//
//  ViewController.swift
//  WeScanSampleProject
//
//  Created by Boris Emorine on 2/8/18.
//  Copyright © 2018 WeTransfer. All rights reserved.
//

import UIKit
import WeScan
import AcuantMobileSDK

final class HomeViewController: UIViewController {
    
    lazy private var logoImageView: UIImageView = {
        let image = UIImage(named: "WeScanLogo")
        let imageView = UIImageView(image: image)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    lazy private var logoLabel: UILabel = {
        let label = UILabel()
        label.text = "WeScan"
        label.font = UIFont.systemFont(ofSize: 25.0, weight: .bold)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    lazy private var scanButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setTitle("Scan Now!", for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(presentScanController(_:)), for: .touchUpInside)
        button.backgroundColor = UIColor(red: 64.0 / 255.0, green: 159 / 255.0, blue: 255 / 255.0, alpha: 1.0)
        button.layer.cornerRadius = 20.0
        return button
    }()

    // MARK: - Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupViews()
        setupConstraints()
    }
    
    // MARK: - Setups
    
    private func setupViews() {
        view.addSubview(logoImageView)
        view.addSubview(logoLabel)
        view.addSubview(scanButton)
    }
    
    private func setupConstraints() {
        
        let logoImageViewConstraints = [
            logoImageView.widthAnchor.constraint(equalToConstant: 150.0),
            logoImageView.heightAnchor.constraint(equalToConstant: 150.0),
            logoImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            NSLayoutConstraint(item: logoImageView, attribute: .centerY, relatedBy: .equal, toItem: view, attribute: .centerY, multiplier: 0.75, constant: 0.0)
        ]
        
        let logoLabelConstraints = [
            logoLabel.topAnchor.constraint(equalTo: logoImageView.bottomAnchor, constant: 20.0),
            logoLabel.centerXAnchor.constraint(equalTo: logoImageView.centerXAnchor)
        ]
        
        let scanButtonConstraints = [
            view.bottomAnchor.constraint(equalTo: scanButton.bottomAnchor, constant: 50.0),
            scanButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            scanButton.heightAnchor.constraint(equalToConstant: 40.0),
            scanButton.widthAnchor.constraint(equalToConstant: 150.0)
        ]
        
        NSLayoutConstraint.activate(scanButtonConstraints + logoLabelConstraints + logoImageViewConstraints)
    }
    
    // MARK: - Actions
    
    @objc func presentScanController(_ sender: UIButton) {
        let scannerVC = ImageScannerController(imageCropper: AcuantImageCropper())
        scannerVC.imageScannerDelegate = self
        scannerVC.cardScannerDelegate = self

        present(scannerVC, animated: true, completion: nil)
    }
    
}

extension HomeViewController: ImageScannerControllerDelegate {
    func imageScannerController(_ scanner: ImageScannerController, didFailWithError error: Error) {
        print(error)
    }
    
    func imageScannerController(_ scanner: ImageScannerController, didFinishScanningWithResults results: ImageScannerResults) {
        scanner.dismiss(animated: true, completion: nil)
    }
    
    func imageScannerControllerDidCancel(_ scanner: ImageScannerController) {
        scanner.dismiss(animated: true, completion: nil)
    }
    
}

extension HomeViewController: CardScannerControllerDelegate {
    func cardScannerController(_ scanner: ImageScannerController,
                               didFinishScanningWithResults results: CardScannerResults) {
        print(results)
    }

}

final class AcuantImageCropper: ImageCropper, InitializationDelegate {
    let credential = Credential()

    static var isInitialized = false

    init() {
        if !AcuantImageCropper.isInitialized {
            let endPoints = Endpoints()
            endPoints.frmEndpoint = "https://frm.acuant.net/api/v1"
            endPoints.idEndpoint = "https://services.assureid.net"
            endPoints.healthInsuranceEndpoint = "https://medicscan.acuant.net/api/v1"


            credential.endpoints = endPoints
            credential.username = "anton@osome.com"
            credential.password = "vasmyc627rjtmz8t"
            credential.subscription = "d761aec3-3f39-4c0f-9375-8256c4df7d85"

            Controller.initialize(credential: credential, delegate:self)
        }
    }

    func cropImage(_ image: UIImage, quad: Quadrilateral) -> UIImage? {
        let image = cropAquantImage(image: image)
        guard let result = image?.image else {
            print(image?.error)
            return nil
        }
        return result
    }

    func cropAquantImage(image: UIImage) -> Image? {
        let croppingData = CroppingData()
        croppingData.image = image

        let cardAttributes = CardAttributes()
        cardAttributes.cardType = CardType.AUTO

        let croppingOptions = CroppingOptions()
        croppingOptions.cardAtributes = cardAttributes
        croppingOptions.imageMetricsRequired = true
        croppingOptions.isHealthCard = false
//        let start = CFAbsoluteTimeGetCurrent()
        let croppedImage = Controller.crop(options: croppingOptions, data: croppingData)
//        let elapsed = CFAbsoluteTimeGetCurrent() - start
//        print("Crop Time:\(elapsed)")
        return croppedImage
    }

    func initializationFinished(error: AcuantMobileSDK.AcuantError?) {
        if let error = error {
            print(error)
            return
        }
        AcuantImageCropper.isInitialized = true
        print("INITIALIZED")
    }


}
