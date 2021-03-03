//
//  ViewController.swift
//  OCR
//
//  Created by Nikhil Bhownani on 03/03/21.
//

import UIKit
import SnapKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        updateImageInQR()
    }
    
    let cardView = Bundle(for: CardView.self).loadNibNamed(String(describing: CardView.self), owner: nil, options: nil)?.first as! CardView
    
    func updateImageInQR() {
        self.view.addSubview(cardView)
        cardView.setupView()
        cardView.snp.makeConstraints {
            $0.centerX.centerY.equalToSuperview()
            $0.height.equalTo(400)
            $0.width.equalTo(250)
        }
    }
    
}

