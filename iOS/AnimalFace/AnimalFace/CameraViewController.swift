//
//  ViewController.swift
//  CoreMLwithVision
//
//  Created by Hidehiko Kondo on 2017/07/28.
//  Copyright © 2017年 Wonderplanet. All rights reserved.
//

import UIKit
import UIKit
import CoreML
import Vision
import ImageIO
import AVFoundation

class CameraViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    @IBOutlet weak var cameraView: UIView!
    //カメラセッション
    var captureSession: AVCaptureSession!
    //デバイス
    var cameraDevices: AVCaptureDevice!
    //画像のアウトプット
    var imageOutput: AVCaptureStillImageOutput!

    @IBOutlet weak var thumbnailView: UIImageView!

    override func viewDidLoad() {
        super.viewDidLoad()
        self.viewGradient()

        //セッションの作成
        captureSession = AVCaptureSession()

        //デバイス一覧の取得
        let devices = AVCaptureDevice.devices()

        //バックカメラをcameraDevicesに格納
        for device in devices {
            if device.position == AVCaptureDevice.Position.back {
                cameraDevices = device as! AVCaptureDevice
            }
        }

        //バックカメラからVideoInputを取得
        let videoInput: AVCaptureInput!
        do {
            videoInput = try AVCaptureDeviceInput.init(device: cameraDevices)
        } catch {
            videoInput = nil
        }

        //セッションに追加
        captureSession.addInput(videoInput)

        //出力先を生成
        imageOutput = AVCaptureStillImageOutput()

        //セッションに追加
        captureSession.addOutput(imageOutput)

        //画像を表示するレイヤーを生成
        let captureVideoLayer: AVCaptureVideoPreviewLayer = AVCaptureVideoPreviewLayer.init(session: captureSession)
        captureVideoLayer.frame = self.cameraView.bounds
        captureVideoLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill

        //Viewに追加
        self.cameraView.layer.addSublayer(captureVideoLayer)

        //セッション開始
        captureSession.startRunning()

        //カメラ表示
//        cameraView.layer.addSublayer(cameraLayer)
//        let output = AVCaptureVideoDataOutput()
//        output.setSampleBufferDelegate(self as? AVCaptureVideoDataOutputSampleBufferDelegate, queue: DispatchQueue(label: "queue"))
//        captureSession.addOutput(output)
//        captureSession.startRunning()

    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
//        cameraLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
//        cameraLayer.frame = CGRect(x: 0, y: 0, width: cameraView.bounds.width, height: cameraView.bounds.width )
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }



    //カメラキャプチャー
//    private lazy var captureSession: AVCaptureSession = {
//        let session = AVCaptureSession()
//        session.sessionPreset = AVCaptureSession.Preset.photo
//        guard let backCamera = AVCaptureDevice.default(for: .video),
//            let input = try? AVCaptureDeviceInput(device: backCamera) else {
//                return session
//        }
//        session.addInput(input)
//        return session
//    }()
//    private lazy var cameraLayer: AVCaptureVideoPreviewLayer = AVCaptureVideoPreviewLayer(session: self.captureSession)


    @IBAction func takePhoto(_ sender: Any) {
        //ビデオ出力に接続
        let captureVideoConnection = imageOutput.connection(with: AVMediaType.video)
        
        //接続から画像を取得
        self.imageOutput.captureStillImageAsynchronously(from: captureVideoConnection!) { (imageDataBuffer, error) -> Void in
            //取得したImageのDataBufferをJPEGを変換
            let capturedImageData: NSData = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(imageDataBuffer!) as! NSData
            //JPEGからUIImageを作成
            let Image: UIImage = UIImage(data: capturedImageData as Data)!
            //アルバムに追加
            //UIImageWriteToSavedPhotosAlbum(Image, self, nil, nil)

            self.thumbnailView.image = Image
        }
    }


    @IBAction func back(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }

    func viewGradient(){
        //グラデーションの開始色
        let topColor = UIColor(red:0.07, green:0.13, blue:0.26, alpha:1)
        //グラデーションの開始色
        let bottomColor = UIColor(red:0.54, green:0.74, blue:0.74, alpha:1)

        //グラデーションの色を配列で管理
        let gradientColors: [CGColor] = [topColor.cgColor, bottomColor.cgColor]

        //グラデーションレイヤーを作成
        let gradientLayer: CAGradientLayer = CAGradientLayer()

        //グラデーションの色をレイヤーに割り当てる
        gradientLayer.colors = gradientColors
        //グラデーションレイヤーをスクリーンサイズにする
        gradientLayer.frame = self.view.bounds

        //グラデーションレイヤーをビューの一番下に配置
        self.view.layer.insertSublayer(gradientLayer, at: 0)
    }


}


