import UIKit

extension UIView {
    func addFullConstraints(_ superView: UIView, top: CGFloat = 0, bottom: CGFloat = 0, left: CGFloat = 0, right: CGFloat = 0){
        self.translatesAutoresizingMaskIntoConstraints = false
        superView.addSubview(self)
        let view_constraint_H = NSLayoutConstraint.constraints(withVisualFormat: "H:|-\(left)-[view]-\(right)-|", options: NSLayoutConstraint.FormatOptions(rawValue: 0), metrics: nil, views: ["view": self])
        let view_constraint_V = NSLayoutConstraint.constraints(withVisualFormat: "V:|-\(top)-[view]-\(bottom)-|", options: NSLayoutConstraint.FormatOptions.alignAllLeading, metrics: nil, views: ["view": self])
        superView.addConstraints(view_constraint_H)
        superView.addConstraints(view_constraint_V)
    }

    func horizontalLayout(left: CGFloat = 0, right: CGFloat = 0) -> [NSLayoutConstraint]{
        return NSLayoutConstraint.constraints(withVisualFormat: "H:|-\(left)-[view]-\(right)-|", options: NSLayoutConstraint.FormatOptions(rawValue: 0), metrics: nil, views: ["view": self])
    }
    func verticalLayout(top: CGFloat = 0, bottom: CGFloat = 0) -> [NSLayoutConstraint]{
        return NSLayoutConstraint.constraints(withVisualFormat: "V:|-\(top)-[view]-\(bottom)-|", options: NSLayoutConstraint.FormatOptions.alignAllLeading, metrics: nil, views: ["view": self])
    }
    
    
    func widthConst(_ size: CGFloat){
        self.addConstraint(NSLayoutConstraint(item: self, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .width, multiplier: 1, constant: size))
    }
    func heightConst(_ size: CGFloat){
        self.addConstraint(NSLayoutConstraint(item: self, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1, constant: size))
    }
}
