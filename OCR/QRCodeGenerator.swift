//
//  QRCodeGenerator.swift
//  OCR
//
//  Created by Devesh Prajapat on 03/03/21.
//

import Foundation
import UIKit

class QRCodeGenerator {
    static func generateQR(with url: String) -> CIImage? {
        let data = url.data(using: String.Encoding.isoLatin1, allowLossyConversion: false)
        
        let filter = CIFilter(name: "CIQRCodeGenerator")
        
        filter?.setValue(data, forKey: "inputMessage")
        filter?.setValue("Q", forKey: "inputCorrectionLevel")
        
        return filter?.outputImage
    }
}
