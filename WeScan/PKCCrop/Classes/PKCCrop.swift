import UIKit

public class PKCCrop: NSObject {
    public func cropViewController(_ image: UIImage, tag: Int = 0) -> PKCCropViewController{
        let pkcCropVC = PKCCropViewController(image, tag: tag)
        return pkcCropVC
    }
}


