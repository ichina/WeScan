//
//  ViewController.swift
//  WeScanSampleProject
//
//  Created by Boris Emorine on 2/8/18.
//  Copyright © 2018 WeTransfer. All rights reserved.
//

import UIKit
import WeScan

final class HomeViewController: UIViewController {
    
    lazy private var logoImageView: UIImageView = {
        let image = UIImage(named: "WeScanLogo")
        let imageView = UIImageView(image: image)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    lazy private var resultImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        imageView.layer.borderWidth = 1
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
        view.addSubview(resultImageView)
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

        let resultImageViewConstraints = [
            resultImageView.widthAnchor.constraint(equalToConstant: 300.0),
            resultImageView.heightAnchor.constraint(equalToConstant: 300.0),
            resultImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            NSLayoutConstraint(item: resultImageView, attribute: .centerY, relatedBy: .equal, toItem: view, attribute: .centerY, multiplier: 0.75, constant: 0.0)
        ]

        NSLayoutConstraint.activate(scanButtonConstraints + logoLabelConstraints + logoImageViewConstraints + resultImageViewConstraints)
    }
    
    // MARK: - Actions
    
    @objc func presentScanController(_ sender: UIButton) {
        guard resultImageView.image == nil else {
            resultImageView.image = nil
            resultImageView.backgroundColor = nil
            return
        }
        let scannerVC = ImageScannerController(scanType: .card(.front))
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
        resultImageView.image = results.scannedImage
        resultImageView.backgroundColor = .white
        scanner.dismiss(animated: true, completion: nil)
    }
    
    func imageScannerControllerDidCancel(_ scanner: ImageScannerController) {
        scanner.dismiss(animated: true, completion: nil)
    }
    
}

extension HomeViewController: CardScannerControllerDelegate {
    func cardScannerController(_ scanner: ImageScannerController,
                               didFinishScanningWithResults results: CardScannerResults) {

        resultImageView.image = results.frontSide.scannedImage
        resultImageView.backgroundColor = .white
        scanner.dismiss(animated: true, completion: nil)
    }

}
