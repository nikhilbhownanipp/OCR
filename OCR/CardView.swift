//
//  CardView.swift
//  OCR
//
//  Created by Devesh Prajapat on 03/03/21.
//

import Foundation
import UIKit

class CardView: UIView {
    
    @IBOutlet weak var ppLogoView: UIImageView!
    
    @IBOutlet weak var qrCodeImageView: UIImageView! {
        didSet {
            
        }
    }
    
    @IBOutlet weak var nameLabel: UILabel! {
        didSet {
            
        }
    }
    
    override public func awakeFromNib() {
        super.awakeFromNib()
        
    }

    public func updateQRImage(with image: UIImage) {
        self.qrCodeImageView.image = image
    }
    
    public func setupView() {
        self.backgroundColor = UIColor(netHex: 0x5F259F)
        self.nameLabel.numberOfLines = 0
        self.nameLabel.font = UIFont.systemFont(ofSize: 20, weight: UIFont.Weight.medium)
        self.nameLabel.textColor = .white
        self.qrCodeImageView.contentMode = .scaleAspectFit
        self.nameLabel.text = "Phonepe test"
        self.layer.cornerRadius = 16
    }
    
}

extension UIColor {
    public convenience init(netHex: Int) {
        self.init(red: (netHex >> 16) & 0xff, green: (netHex >> 8) & 0xff, blue: netHex & 0xff)
    }
    public convenience init(red: Int, green: Int, blue: Int) {
        self.init(red: CGFloat(red) / 255.0, green: CGFloat(green) / 255.0, blue: CGFloat(blue) / 255.0, alpha: 1.0)
    }
}

extension UIView {
    public var snapshotImage: UIImage? {
        UIGraphicsBeginImageContextWithOptions(bounds.size, false, 0)
        defer { UIGraphicsEndImageContext() }
        drawHierarchy(in: bounds, afterScreenUpdates: true)
        return UIGraphicsGetImageFromCurrentImageContext()
    }
}
