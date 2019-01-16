//
//  ImageCropper.swift
//  WeScan
//
//  Created by Chingis Gomboev on 07/01/2019.
//  Copyright © 2019 WeTransfer. All rights reserved.
//

protocol ImageCropper {
    func cropImage(_ image: UIImage, quad: Quadrilateral) -> UIImage?
}

final class DefaultImageCropper: ImageCropper {

    func cropImage(_ image: UIImage, quad: Quadrilateral) -> UIImage? {
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

final class PassportImageCropper: ImageCropper {

    func cropImage(_ image: UIImage, quad: Quadrilateral) -> UIImage? {
        return image
    }
}
