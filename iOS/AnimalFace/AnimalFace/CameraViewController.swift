//
//  ViewController.swift
//  CoreMLwithVision
//
//  Created by Hidehiko Kondo on 2017/07/28.
//  Copyright © 2017年 Wonderplanet. All rights reserved.
//

import UIKit
import CoreML
import Vision
import ImageIO
import AVFoundation
import GoogleMobileAds

class CameraViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate , GADBannerViewDelegate  {
    //MARK: - value outlets
    @IBOutlet weak var cameraView: UIView!
    @IBOutlet weak var thumbnailView: UIImageView!
    @IBOutlet weak var facelineImageView: UIImageView!
    @IBOutlet weak var adView: UIView!
    var bannerView: GADBannerView!

    var captureSession: AVCaptureSession!
    var cameraDevices: AVCaptureDevice!
    var imageOutput: AVCaptureStillImageOutput!
    var imageToAnalyis : CIImage?
    var inputImage: CIImage!


    //MARK: - Life cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        self.viewGradient()
        self.cameraConnection()
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        self.admob()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    //MARK: - カメラ関連
    func cameraConnection(){
        //シミュレータだったら何もしない
        if(TARGET_OS_SIMULATOR != 0){
            return
        }

        //セッションの作成
        captureSession = AVCaptureSession()

        //デバイス一覧の取得
        let devices = AVCaptureDevice.devices()

        //バックカメラをcameraDevicesに格納
        for device in devices {
            if device.position == AVCaptureDevice.Position.front {
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
        //シミュレータだったら何もしない
        if(TARGET_OS_SIMULATOR != 0){
            return
        }
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
                //TODO: 顔を検出したら、分類処理へ。（１回だけでいいので複数検出したらreturn）
                print("顔を検出しました")
                //分類処理へ
                self.faceClassification()

                break;
            }
        }
    }


    // MARK: -顔分類
    func faceClassification(){
        //画像をモデルに渡す形式（CIImage）に変換
        guard let uiImage = thumbnailView.image
            else { fatalError("no image from image picker") }
        guard let ciImage = CIImage(image: uiImage)
            else { fatalError("can't create CIImage from UIImage") }
        let orientation = CGImagePropertyOrientation(rawValue: UInt32(uiImage.imageOrientation.rawValue))
        self.inputImage = ciImage.oriented(forExifOrientation: Int32(orientation!.rawValue))

        //読み込んだ画像をそのまま推論処理へ
        let handler = VNImageRequestHandler(ciImage: self.inputImage)
        do {
            try handler.perform([self.classificationRequest_dogorcat])
        } catch {
            print(error)
        }
    }


    lazy var classificationRequest_dogorcat: VNCoreMLRequest = {
        // Load the ML model through its generated class and create a Vision request for it.
        do {
            var model: VNCoreMLModel? = nil
            model = try! VNCoreMLModel(for: AnimalFaceModel().model)
            return VNCoreMLRequest(model: model!, completionHandler: self.handleClassification)
        } catch {
            fatalError("can't load Vision ML model: \(error)")
        }
    }()


    func handleClassification(request: VNRequest, error: Error?) {
        guard let observations = request.results as? [VNClassificationObservation]
            else { fatalError("unexpected result type from VNCoreMLRequest") }
        guard let best = observations.first
            else { fatalError("can't get best result") }

        DispatchQueue.main.async {
            var classification: String = (best.identifier);
            print("Classification: \"\(classification)\" Confidence: \(best.confidence)")

            if(classification == "coala"){
                print("コアラ")
            }else if(classification == "inu"){
                print("いぬ")
            }else if(classification == "kaba"){
                print("カバ")
            }else if(classification == "kitsune"){
                print("キツネ")
            }else if(classification == "kuma"){
                print("くま")
            }else if(classification == "neko"){
                print("ねこ")
            }else if(classification == "panda"){
                print("パンダ")
            }else if(classification == "penguin"){
                print("ペンギン")
            }else if(classification == "risu"){
                print("リス")
            }else if(classification == "uma"){
                print("うま")
            }else if(classification == "usagi"){
                print("うさぎ")
            }else if(classification == "ushi"){
                print("うし")
            }else{
                print("判別きませんでした")
            }

            // 結果画面へ結果の受け渡しと遷移
            let storyboard: UIStoryboard = self.storyboard!
            let nextView = storyboard.instantiateViewController(withIdentifier: "resultviewcontroller") as! ResultViewController
            nextView.result = classification
            self.present(nextView, animated: true, completion: nil)

        }
    }

    // MARK: - UI関連
    @IBAction func back(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }

    func viewGradient(){
        //グラデーションの開始色
        let topColor = UIColor(red:0.76, green:0.94, blue:0.98, alpha:1)
        //グラデーションの開始色
        let bottomColor = UIColor(red:0.78, green:0.97, blue:0.81, alpha:1)
        
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

    //MARK: AdMob
    func admob(){
        //ADビューの配置(320x50)
        bannerView = GADBannerView(adSize: kGADAdSizeBanner)
        self.adView.addSubview(bannerView)
        bannerView.adUnitID = "ca-app-pub-3324877759270339/5533467015"
        bannerView.rootViewController = self
        bannerView.load(GADRequest())
        bannerView.delegate = self
        
        //ビュー位置調整
        print("safeview-----------------", self.view.safeAreaInsets)
        self.adView.frame = CGRect(x: self.adView.frame.origin.x,
                                   y: self.view.frame.height - self.adView.frame.height -  self.view.safeAreaInsets.bottom,
                                   width: self.adView.frame.width,
                                   height: self.adView.frame.height)
    }
    
    /// Tells the delegate an ad request loaded an ad.
    func adViewDidReceiveAd(_ bannerView: GADBannerView) {
        print("adViewDidReceiveAd")
    }
    
    /// Tells the delegate an ad request failed.
    func adView(_ bannerView: GADBannerView,
                didFailToReceiveAdWithError error: GADRequestError) {
        print("adView:didFailToReceiveAdWithError: \(error.localizedDescription)")
    }
    
    /// Tells the delegate that a full screen view will be presented in response
    /// to the user clicking on an ad.
    func adViewWillPresentScreen(_ bannerView: GADBannerView) {
        print("adViewWillPresentScreen")
    }
    
    /// Tells the delegate that the full screen view will be dismissed.
    func adViewWillDismissScreen(_ bannerView: GADBannerView) {
        print("adViewWillDismissScreen")
    }
    
    /// Tells the delegate that the full screen view has been dismissed.
    func adViewDidDismissScreen(_ bannerView: GADBannerView) {
        print("adViewDidDismissScreen")
    }
    
    /// Tells the delegate that a user click will open another app (such as
    /// the App Store), backgrounding the current app.
    func adViewWillLeaveApplication(_ bannerView: GADBannerView) {
        print("adViewWillLeaveApplication")
    }
}


