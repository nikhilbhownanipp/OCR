//
//  ViewController.swift
//  OCR
//
//  Created by Nikhil Bhownani on 03/03/21.
//

import UIKit
import SwiftOCR
import AVFoundation
import Vision

extension UIImage {
    func detectOrientationDegree () -> CGFloat {
        switch imageOrientation {
        case .right, .rightMirrored:    return 90
        case .left, .leftMirrored:      return -90
        case .up, .upMirrored:          return 180
        case .down, .downMirrored:      return 0
        @unknown default: return 0
        }
    }
}

class ViewController: UIViewController {
    // MARK: - Outlets
    var cameraView: UIView = UIView()
    var viewFinder: UIView = UIView()
    var label: UILabel = UILabel()
    
    // MARK: - Private Properties
    fileprivate var stillImageOutput: AVCaptureStillImageOutput!
    fileprivate let captureSession = AVCaptureSession()
    fileprivate let device  = AVCaptureDevice.default(for: AVMediaType.video)
    private let ocrInstance = SwiftOCR()
    
    
    // MARK: - View LifeCycle
    override func viewDidLoad() {
        super.viewDidLoad()
        // start camera init
        setup()
//        DispatchQueue.global(qos: .userInitiated).async {
            if self.device != nil {
                self.configureCameraForUse()
            }
//        }
    }
    
    private func setup() {
        view.addSubview(cameraView)
        view.addSubview(viewFinder)
        view.addSubview(label)
        let button = UIButton()
        button.addTarget(self, action: #selector(takePhotoButtonPressed(_:)), for: .touchUpInside)
        button.backgroundColor = .red
        
        cameraView.frame = self.view.frame
        viewFinder.frame = CGRect(x: 10, y: 40, width: 80, height: 80)
        label.frame = CGRect(x: 10, y: self.view.frame.size.height / 2, width: self.view.frame.size.width, height: 50)
        view.addSubview(button)
        button.frame = CGRect(x: 100, y: 500, width: 50, height: 50)
    }
    
    // MARK: - IBActions
    @IBAction func takePhotoButtonPressed (_ sender: UIButton) {
        DispatchQueue.global(qos: .userInitiated).async {
            guard let capturedType = self.stillImageOutput.connection(with: AVMediaType.video) else {
                return
            }
            self.stillImageOutput.captureStillImageAsynchronously(from: capturedType) { optionalBuffer, error in
                guard let buffer = optionalBuffer else {
                    return
                }
                
                let imageData = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(buffer)
                if let image = UIImage(data: imageData!) {
                    OCRTextProcessor.getSavingsBankId(image: image) { strings in
                        print(strings)
                    }
                    
                    OCRTextProcessor.getIFSC(image: image) { ifsc in
                        print(ifsc)
                    }
                }
                
            }
        }
    }
}

extension ViewController {
    // MARK: AVFoundation
    fileprivate func configureCameraForUse () {
        self.stillImageOutput = AVCaptureStillImageOutput()
        let fullResolution = UIDevice.current.userInterfaceIdiom == .phone && max(UIScreen.main.bounds.size.width, UIScreen.main.bounds.size.height) < 568.0
        
        if fullResolution {
            self.captureSession.sessionPreset = AVCaptureSession.Preset.photo
        } else {
            self.captureSession.sessionPreset = AVCaptureSession.Preset.hd1280x720
        }
        
        self.captureSession.addOutput(self.stillImageOutput)
        
        self.prepareCaptureSession()
//
        
    }
    
    private func prepareCaptureSession () {
        do {
            self.captureSession.addInput(try AVCaptureDeviceInput(device: self.device!))
        } catch {
            print("AVCaptureDeviceInput Error")
        }
        
        // layer customization
        let previewLayer = AVCaptureVideoPreviewLayer(session: self.captureSession)
        previewLayer.frame.size = self.cameraView.frame.size
        previewLayer.frame.origin = CGPoint.zero
        previewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        
        // device lock is important to grab data correctly from image
        do {
            try self.device?.lockForConfiguration()
            self.device?.focusPointOfInterest = CGPoint(x: 0.5, y: 0.5)
            self.device?.focusMode = .continuousAutoFocus
            self.device?.unlockForConfiguration()
        } catch {
            print("captureDevice?.lockForConfiguration() denied")
        }
        
        //Set initial Zoom scale
        do {
            try self.device?.lockForConfiguration()
            
            let zoomScale: CGFloat = 2.5
            
            if zoomScale <= (device?.activeFormat.videoMaxZoomFactor)! {
                device?.videoZoomFactor = zoomScale
            }
            
            device?.unlockForConfiguration()
        } catch {
            print("captureDevice?.lockForConfiguration() denied")
        }
        
        DispatchQueue.main.async(execute: {
            self.cameraView.layer.addSublayer(previewLayer)
            self.captureSession.startRunning()
        })
    }
    
}

class OCRTextProcessor {
    static func getSavingsBankId(image: UIImage, completionBlock: @escaping ([String]) -> Void)  {
        OCRManager.shared.fetchTextArray(image) { strings in
            let numbersString = strings.filter {
                return Int64($0) != nil && $0.count > 5
            }
            completionBlock(numbersString)
        }
    }
    
    static func getIFSC(image: UIImage, completionBlock: @escaping (String) -> Void) {
        OCRManager.shared.fetchTextArray(image) { strings in
            var ifscPosition: Int = strings.count
            for (index, item) in strings.enumerated() {
                if item.contains("IFSC") {
                    let components = item.components(separatedBy: "IFSC:")
                    if components.count > 1 {
                        completionBlock(components[1])
                        return
                    }
                    ifscPosition = index
                }
                
                if ifscPosition + 1 == index {
                    completionBlock(item)
                    return
                }
            }
        }
    }
}


class OCRManager {
    
    static var shared: OCRManager = OCRManager()
    
    func fetchTextArray(_ image: UIImage, completion:@escaping ([String]) -> Void) {
        let request = VNRecognizeTextRequest { request, error in
            var stringsArray: [String] = []
            guard let observations = request.results as? [VNRecognizedTextObservation] else {
                fatalError("Received invalid observations")
            }
            
            for observation in observations {
                guard let bestCandidate = observation.topCandidates(1).first else {
                    print("No candidate")
                    continue
                }
                stringsArray.append(bestCandidate.string)
                print("Found this candidate: \(bestCandidate.string)")
            }
            completion(stringsArray)
        }
        let requests = [request]
        guard let img = image.cgImage else {
            fatalError("Missing image to scan")
        }
        
        let handler = VNImageRequestHandler(cgImage: img, options: [:])
        try? handler.perform(requests)
    }
    
}
