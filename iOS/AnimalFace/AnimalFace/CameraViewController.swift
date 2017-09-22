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
    //MARK: - value outlets
    @IBOutlet weak var cameraView: UIView!
    @IBOutlet weak var thumbnailView: UIImageView!
    @IBOutlet weak var facelineImageView: UIImageView!

    var captureSession: AVCaptureSession!
    var cameraDevices: AVCaptureDevice!
    var imageOutput: AVCaptureStillImageOutput!
    var imageToAnalyis : CIImage?


    //MARK: - Life cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        self.viewGradient()
        self.cameraConnection()
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

    //MARK: - カメラ関連
    func cameraConnection(){
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

        //顔の線を一番上に
        facelineImageView.bringSubview(toFront: cameraView)
    }


    @IBAction func takePhoto(_ sender: Any) {
        //ビデオ出力に接続
        let captureVideoConnection = imageOutput.connection(with: AVMediaType.video)
        
        //接続から画像を取得
        self.imageOutput.captureStillImageAsynchronously(from: captureVideoConnection!) { (imageDataBuffer, error) -> Void in
            //取得したImageのDataBufferをJPEGを変換
            let capturedImageData: NSData = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(imageDataBuffer!)! as NSData
            //JPEGからUIImageを作成
            let Image: UIImage = UIImage(data: capturedImageData as Data)!
            //アルバムに追加
            //UIImageWriteToSavedPhotosAlbum(Image, self, nil, nil)

            self.thumbnailView.image = Image

            //顔認識へ
            self.faceDetect()
        }
    }

    // MARK: - 顔検出
    func faceDetect(){
        print("顔検出開始")
        guard var uiImage = thumbnailView.image
            else { fatalError("no image from image picker") }

        //カメラで撮った画像がなぜか横向きになるので縦にする
        UIGraphicsBeginImageContext((uiImage.size))
        uiImage.draw(in: CGRect(x:0, y:0, width:(uiImage.size.width), height:(uiImage.size.height)))
        uiImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()

        guard let ciImage = CIImage(image: uiImage)
            else { fatalError("can't create CIImage from UIImage") }
        self.imageToAnalyis = ciImage.oriented(forExifOrientation: Int32(uiImage.imageOrientation.rawValue))

        //Visionへのリクエスト
        let handler = VNImageRequestHandler(ciImage: ciImage, orientation: CGImagePropertyOrientation(rawValue: UInt32(Int32(uiImage.imageOrientation.rawValue)))!)

        DispatchQueue.global(qos: .userInteractive).async {
            do {
                try handler.perform([self.faceDetectionRequest])
            } catch {
                print(error)
            }
        }

    }
    //リクエスト
    lazy var faceDetectionRequest : VNDetectFaceRectanglesRequest = {
        let faceRequest = VNDetectFaceRectanglesRequest(completionHandler:self.handleFaceDetection)
        return faceRequest
    }()

    //ハンドラ
    func handleFaceDetection (request: VNRequest, error: Error?) {
        guard let observations = request.results as? [VNFaceObservation]
            else
        {
            print("unexpected result type from VNFaceObservation")
            return
        }

        guard observations.first != nil else {
            print("顔が見つかりませんでした")
            return
        }

        // Show the pre-processed image
        DispatchQueue.main.async {
            self.thumbnailView.subviews.forEach({ (s) in
                s.removeFromSuperview()
            })
            for face in observations
            {
                //顔を検出したら、分類処理へ。（１回だけでいいので複数検出したらreturn）
                print("顔を検出しました")
                break;
            }
        }
    }

    // MARK: - UI関連

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


