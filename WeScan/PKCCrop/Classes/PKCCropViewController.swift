import UIKit

public protocol PKCCropDelegate: class {
    func pkcCropCancel(_ viewController: PKCCropViewController)
    func pkcCropImage(_ image: UIImage?, originalImage: UIImage?)
    func pkcCropComplete(_ viewController: PKCCropViewController)
}


public class PKCCropViewController: UIViewController {
    public weak var delegate: PKCCropDelegate?
    public var tag: Int = 0
    private let scanType: ScanType
    var initialScale: CGFloat?
    var image = UIImage()
    @IBOutlet fileprivate weak var scrollView: UIScrollView!
    @IBOutlet fileprivate weak var scrollTopConst: NSLayoutConstraint!
    @IBOutlet fileprivate weak var scrollBottomConst: NSLayoutConstraint!
    @IBOutlet fileprivate weak var scrollLeadingConst: NSLayoutConstraint!
    @IBOutlet fileprivate weak var scrollTrailingConst: NSLayoutConstraint!

    fileprivate let imageView = UIImageView()
    fileprivate let overlay: CardOverlayView

    lazy var doneButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(doneAction(_:)), for: .touchUpInside)
        button.setTitle("Perfect!", for: .normal)
        button.layer.cornerRadius = 28
        button.backgroundColor = .white
        button.setTitleColor(.black, for: .normal)
        return button
    }()

    lazy private var cancelButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(named: "backIos", in: Bundle(for: ScannerViewController.self),
                                compatibleWith: nil), for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(cancelImageScannerController), for: .touchUpInside)
        return button
    }()
    @objc
    private func cancelImageScannerController() {
        navigationController?.popViewController(animated: true)
    }

    @IBOutlet fileprivate weak var rotateButton: UIButton!

    private var imageRotateRate: Float = 0

    public init(_ image: UIImage, tag: Int = 0, scanType: ScanType = .passport) {
        self.overlay = CardOverlayView(frame: .zero, scanType: scanType, shadowAlpha: 0.9)
        self.scanType = scanType

        super.init(nibName: "PKCCropViewController", bundle: Bundle(for: PKCCrop.self))
        self.image = image.resetOrientation()
        self.tag = tag
    }



    override public var prefersStatusBarHidden: Bool {
//        if self.navigationController == nil || !PKCCropHelper.shared.isNavigationBarShow {
            return true
//        } else {
//            return false
//        }
    }


    override public func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
//        if self.navigationController == nil || !PKCCropHelper.shared.isNavigationBarShow{
        self.navigationController?.setNavigationBarHidden(true, animated: true)
//        }
    }



    override public func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
//        if self.navigationController == nil || !PKCCropHelper.shared.isNavigationBarShow{
            self.navigationController?.setNavigationBarHidden(false, animated: true)
//        }
    }


    deinit {
        //print("deinit \(self)")
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func viewDidLoad() {
        super.viewDidLoad()
        self.initVars()
        self.initCrop(self.image)
    }

    private func initVars(){
        self.view.backgroundColor = .black

        self.scrollTopConst.constant = 0

        self.scrollView.delegate = self
        self.scrollView.showsVerticalScrollIndicator = false
        self.scrollView.showsHorizontalScrollIndicator = false
        self.rotateButton.addTarget(self, action: #selector(rotateLeftAction(_:)), for: .touchUpInside)

        self.navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .done, target: self, action: #selector(doneAction(_:))
        )

        view.addSubview(doneButton)
        view.addSubview(cancelButton)

        let doneButtonConstraints = [
            doneButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            doneButton.widthAnchor.constraint(equalToConstant: 180.0),
            doneButton.heightAnchor.constraint(equalToConstant: 56.0),
            view.bottomAnchor.constraint(equalTo: doneButton.bottomAnchor, constant: 8.0)
        ]

        let cancelButtonConstraints = [
            cancelButton.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 0),
            cancelButton.topAnchor.constraint(equalTo: view.topAnchor, constant: 20 + (isEarsPhone ? 20 : 0)),
            cancelButton.widthAnchor.constraint(equalToConstant: 40.0),
            cancelButton.widthAnchor.constraint(equalToConstant: 40.0)
        ]

        NSLayoutConstraint.activate(doneButtonConstraints + cancelButtonConstraints)

        switch scanType {
        case .passport:
            overlay.setTitleText("Passport")
            overlay.setDetailText("Adjust your IC photo so it fits\nthe designed area")
        case .card(let side):
            overlay.setTitleText(side == .front ? "Front Side" : "Back Side")
            overlay.setDetailText("Adjust your Card photo so it fits\n the designed area")
        default:
            overlay.setTitleText("")
        }
    }


    private func initCrop(_ image: UIImage){
        self.scrollView.alpha = 0
        scrollView.contentOffset = .zero
        self.scrollView.minimumZoomScale = 0.2
        self.scrollView.maximumZoomScale = 4
        self.scrollView.zoomScale = 1
        self.scrollView.subviews.forEach({ $0.removeFromSuperview() })

        self.scrollView.addSubview(self.imageView)
        self.imageView.image = image
        let screenBounds = UIScreen.main.bounds
        let width = screenBounds.width - self.scrollLeadingConst.constant - self.scrollTrailingConst.constant
        let height = screenBounds.height - self.scrollTopConst.constant - self.scrollBottomConst.constant
        self.imageView.frame = CGRect(x: (width - image.size.width)/2, y: (height - image.size.height)/2, width: image.size.width, height: image.size.height)
        self.imageView.contentMode = .scaleAspectFill

        DispatchQueue.main.async {

            let minimumXScale = PKCCropHelper.shared.minSize / image.size.width
            let minimumYScale = PKCCropHelper.shared.minSize / image.size.height

            let currentXScale = self.scrollView.frame.width / image.size.width
            let currentYScale = self.scrollView.frame.height / image.size.height

            self.scrollView.minimumZoomScale = min(minimumXScale, minimumYScale)

            let screenRatio = self.scrollView.frame.width / self.scrollView.frame.height
            let imageRatio = image.size.width / image.size.height

            self.scrollView.zoomScale = screenRatio > imageRatio ? currentYScale : currentXScale
            if self.initialScale == nil {
                self.initialScale = self.scrollView.zoomScale
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self.scrollView.contentOffset = .zero
                UIView.animate(withDuration: 0.2) {
                    self.scrollView.alpha = 1
                }
            }
            self.overlay.frame = self.scrollView.frame
        }

        view.insertSubview(overlay, aboveSubview: scrollView)
    }


    @objc
    private func cancelAction(_ sender: UIBarButtonItem) {
        self.delegate?.pkcCropCancel(self)
    }

    @objc
    private func doneAction(_ sender: Any) {
        guard let curImage = self.imageView.image else { return }
        let zoomScale = self.scrollView.zoomScale

        var rect: CGRect = .zero
        var cropArea = overlay.cropArea
        cropArea = cropArea.insetBy(dx: -(cropArea.width * 0.05), dy: -(cropArea.height * 0.05))

        switch scanType {
        case .passport:
            rect = CGRect(
                x: (scrollView.contentOffset.x + cropArea.minX - imageView.frame.minX) / zoomScale,
                y: (scrollView.contentOffset.y + cropArea.minY - imageView.frame.minY) / zoomScale,
                width: cropArea.width / zoomScale,
                height: cropArea.height / zoomScale
            ).integral
        case .card(_):
            rect = CGRect(
                x: (scrollView.contentOffset.x + cropArea.minX - imageView.frame.minX) / zoomScale,
                y: (scrollView.contentOffset.y + cropArea.minY - imageView.frame.minY) / zoomScale,
                width: cropArea.width / zoomScale,
                height: cropArea.height / zoomScale
                ).integral
        default:
            rect = CGRect(
                x: (scrollView.contentOffset.x + scrollView.contentInset.left) / zoomScale,
                y: (scrollView.contentOffset.y + scrollView.contentInset.top) / zoomScale,
                width: scrollView.bounds.width / zoomScale,
                height: scrollView.bounds.height / zoomScale).integral
        }

        let image: UIImage? = curImage.scaledImage(at: rect)
        DispatchQueue.main.async {
            self.delegate?.pkcCropImage(image, originalImage: self.image)
        }

        self.delegate?.pkcCropComplete(self)
    }


    @objc private func rotateLeftAction(_ sender: Any) {
        guard let image = self.imageView.image?.imageRotatedByDegrees(-90, flip: false) else {
            return
        }
        self.initCrop(image)
    }
}


extension PKCCropViewController: UIScrollViewDelegate{
    @objc fileprivate func scrollDidZoomCenter() {
        let assetView = self.imageView
        let scrollViewBoundsSize = self.scrollView.bounds.size
        var assetFrame = assetView.frame
        let assetSize = assetView.frame.size

        assetFrame.origin.x = (assetSize.width < scrollViewBoundsSize.width) ?
            (scrollViewBoundsSize.width - assetSize.width) / 2.0 : 0
        assetFrame.origin.y = (assetSize.height < scrollViewBoundsSize.height) ?
            (scrollViewBoundsSize.height - assetSize.height) / 2.0 : 0.0

        assetView.frame = assetFrame

        let cropArea = overlay.cropArea
        var insets = scrollView.contentInset
        insets.top = assetFrame.origin.y > 0 ? max(0, (cropArea.minY - assetFrame.origin.y)) : cropArea.minY
        let botInset = (overlay.bounds.height - cropArea.maxY)
        let assetBotInset = assetFrame.height - assetFrame.maxY
        insets.bottom = assetFrame.origin.y > 0 ? max(0, botInset - assetBotInset) : botInset

        insets.left = assetFrame.origin.x > 0 ? 0 : max(0, cropArea.minX)
        insets.right = assetFrame.origin.x > 0 ? 0 : max(0, (overlay.bounds.width - cropArea.maxX))

        scrollView.contentInset = insets
    }
    
    public func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return self.imageView
    }

    public func scrollViewDidZoom(_ scrollView: UIScrollView) {
        self.scrollDidZoomCenter()
        if case .passport = scanType, let scale = initialScale,
            scrollView.zoomScale != scale, overlay.detailLabel.alpha == 1 {
            UIView.animate(withDuration: 0.1) {
                self.overlay.detailLabel.alpha = 0
            }

        }
    }
}


extension PKCCropViewController: PKCCropLineDelegate{
    func pkcCropLineMask(_ frame: CGRect) {
    }
}

internal final class MaskView: UIView {

}
