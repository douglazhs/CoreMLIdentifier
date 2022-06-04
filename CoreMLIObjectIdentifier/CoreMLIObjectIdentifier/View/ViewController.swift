//
//  ViewController.swift
//  CoreMLIObjectIdentifier
//
//  Created by Douglas Henrique de Souza Pereira on 03/06/22.
//

import UIKit
import AVKit
import Vision

class ViewController: UIViewController {
    
    //Model
    var model = Resnet50().model
    
    private lazy var objectLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 20,
                                       weight: .semibold)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Object"
        label.textAlignment = .center
        label.textColor = .black
        return label
    }()
    
    private lazy var acurracyLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16,
                                       weight: .regular)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = .black
        label.text = "Accurracy"
        label.textAlignment = .center
        return label
    }()
    
    private lazy var bottomView: UIView = {
        let bottomView = UIView()
        bottomView.translatesAutoresizingMaskIntoConstraints = false
        bottomView.layer.masksToBounds = true
        bottomView.layer.cornerRadius = 15
        bottomView.backgroundColor = .white
        bottomView.addSubview(objectLabel)
        bottomView.addSubview(acurracyLabel)
        bottomView.layer.zPosition = 10
       return bottomView
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(bottomView)
        setupConstraints()
        prepareCaptureSession()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        view.backgroundColor = .black
    }
    
    func prepareCaptureSession(){
        //Camera
        let captureSession = AVCaptureSession()
        
        guard let captureDevice = AVCaptureDevice.default(for: .video) else { return }
        
        guard let input = try? AVCaptureDeviceInput(device: captureDevice) else { return }
        
        captureSession.addInput(input)
        
        captureSession.startRunning()
        
        //Preview Layer
        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        view.layer.addSublayer(previewLayer)
        previewLayer.frame = view.bounds
        
        //Data
        let dataOutput = AVCaptureVideoDataOutput()
        dataOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
        captureSession.addOutput(dataOutput)
    }
    
    func setupConstraints(){
        bottomView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor).isActive = true
        bottomView.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
        bottomView.widthAnchor.constraint(equalToConstant: UIScreen.main.bounds.width).isActive = true
        bottomView.heightAnchor.constraint(equalToConstant: UIScreen.main.bounds.height*0.25).isActive = true
        objectLabel.widthAnchor.constraint(equalToConstant: UIScreen.main.bounds.width-50).isActive = true
        objectLabel.heightAnchor.constraint(equalToConstant: 25).isActive = true
        objectLabel.centerXAnchor.constraint(equalTo: self.bottomView.centerXAnchor).isActive = true
        objectLabel.centerYAnchor.constraint(equalTo: self.bottomView.centerYAnchor).isActive = true
        acurracyLabel.widthAnchor.constraint(equalToConstant: UIScreen.main.bounds.width-50).isActive = true
        acurracyLabel.heightAnchor.constraint(equalToConstant: 25).isActive = true
        acurracyLabel.centerXAnchor.constraint(equalTo: self.bottomView.centerXAnchor).isActive = true
        acurracyLabel.topAnchor.constraint(equalTo: self.objectLabel.bottomAnchor, constant: 20).isActive = true
    }
}

extension ViewController: AVCaptureVideoDataOutputSampleBufferDelegate{
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer: CVPixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        guard let model = try? VNCoreMLModel(for: model) else { return }
        let request = VNCoreMLRequest(model: model) { (finishedReq, err) in
            guard let results = finishedReq.results as? [VNClassificationObservation] else { return }
            guard let firstObservation = results.first else { return }
            
            let acc = Int(firstObservation.confidence * 100)
            
            DispatchQueue.main.asyncAfter(deadline: .now()+1){
                self.objectLabel.text = firstObservation.identifier.uppercased()
                self.acurracyLabel.text = "Accurracy: \(acc)%"
            }
        }
        
        try? VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:]).perform([request])
    }
}

