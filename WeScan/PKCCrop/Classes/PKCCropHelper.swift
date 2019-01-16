import UIKit


public enum PKCCropLineType{
    case show, hide, `default`
}


public class PKCCropHelper{
    public static let shared = PKCCropHelper()

    public var isNavigationBarShow = false
    public var lineType: PKCCropLineType = .default
    public var maskAlpha: CGFloat = 0.4
    public var barTintColor: UIColor = UIColor(red: 205/255, green: 205/255, blue: 205/255, alpha: 1)
    public var tintColor: UIColor = UIColor(red: 0, green: 0.4, blue: 1, alpha: 1)
    
    public var isDegressShow = true
    public var degressBeforeImage: UIImage? = nil
    public var degressAfterImage: UIImage? = nil
    
    var isCropRate = false
    var isCircle = false

    let minSize: CGFloat = 120

    private init() { }
}
