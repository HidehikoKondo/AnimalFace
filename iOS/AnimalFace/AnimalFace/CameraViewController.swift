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
import Firebase

class CameraViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate , GADBannerViewDelegate  {

    
    //MARK: - value outlets
    @IBOutlet weak var cameraView: UIView!
    @IBOutlet weak var facelineImageView: UIImageView!
    @IBOutlet weak var adView: UIView!
    @IBOutlet weak var shutterButton: UIButton!
    @IBOutlet weak var changeButton: UIButton!
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var indicatorView: UIView!

    var bannerView: GADBannerView!
    var captureSession: AVCaptureSession!
    var cameraDevices: AVCaptureDevice!
    var imageOutput: AVCaptureStillImageOutput!
    var imageToAnalyis : CIImage?
    var inputImage: CIImage!
    var cameraType: Bool = true
    var photoImage: UIImage!
    var croppedFace: UIImage!

    //MARK: - Life cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        self.viewGradient()
    }

    override func viewWillAppear(_ animated: Bool) {
        self.cameraConnection(type: cameraType)
        self.enableButton()
    }

    override func viewWillDisappear(_ animated: Bool) {
        self.cameraRelease()
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
    @IBAction func changeCamera(_ sender: Any) {
        //いったんセッション切る
        captureSession.stopRunning()

        //カメラタイプを反転
        cameraType = !cameraType

        //再接続
        self.cameraConnection(type: cameraType)
    }

    // camera stop メモリ解放
    func cameraRelease(){
        //シミュレータだったら何もしない
        if(TARGET_OS_SIMULATOR != 0){
            return
        }

        captureSession.stopRunning()
        for output in captureSession.outputs {
            captureSession.removeOutput((output as? AVCaptureOutput)!)
        }
        for input in captureSession.inputs {
            captureSession.removeInput((input as? AVCaptureInput)!)
        }
        captureSession = nil
        cameraDevices = nil
    }

    func cameraConnection(type: Bool){
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
            if(type == true){
                if device.position == AVCaptureDevice.Position.front {
                    cameraDevices = device as! AVCaptureDevice
                }
            }else{
                if device.position == AVCaptureDevice.Position.back {
                    cameraDevices = device as! AVCaptureDevice
                }
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
        //ボタンを無効
        self.disableButton()

        //ビデオ出力に接続
        let captureVideoConnection = imageOutput.connection(with: AVMediaType.video)
        
        //接続から画像を取得
        self.imageOutput.captureStillImageAsynchronously(from: captureVideoConnection!) { (imageDataBuffer, error) -> Void in
            //取得したImageのDataBufferをJPEGを変換
            let capturedImageData: NSData = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(imageDataBuffer!)! as NSData
            //JPEGからUIImageを作成
            let cameraImage: UIImage = UIImage(data: capturedImageData as Data)!

            //カメラを止める
            self.captureSession.stopRunning()

            //インカメのときだけ写真を反転させる
            if(self.cameraType){
                self.photoImage = cameraImage.flipHorizontal()
            }else{
                self.photoImage = cameraImage
            }

            //顔認識へ
            self.faceDetect()
        }
    }

    //写真を正方形に（横幅のサイズで固定）に切り抜く
    func cropRectangle(image: UIImage) -> UIImage{
        var croppedImage: UIImage


        UIGraphicsBeginImageContextWithOptions(CGSize(width: image.size.width, height: image.size.width), false, 0.0)
        let imageRef = image
        let context = UIGraphicsGetCurrentContext()

        var ypos = (image.size.width - image.size.height) * 0.5

        imageRef.draw(in: CGRect(x: 0, y: ypos, width: image.size.width, height: image.size.height))

        croppedImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return croppedImage
    }

    // MARK: - 顔検出
    func faceDetect(){
        print("顔検出開始")
        guard var uiImage = photoImage
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
            self.alert(title:"ｱﾚﾚ?>(○´∀｀○) ", message: "顔が写ってないよ")
            return
        }

        // Show the pre-processed image
        DispatchQueue.main.async {
//            self.thumbnailView.subviews.forEach({ (s) in
//                s.removeFromSuperview()
//            })
            for face in observations
            {
                //四角で囲む
                let view = self.CreateBoxView(withColor: UIColor.red)
                view.frame = self.transformRect(fromRect: face.boundingBox,
                                                toViewRect: self.photoImage)
                self.croppedFace = self.photoImage.cropping(to: view.frame)

                //顔の部分を四角で囲む
//                self.thumbnailView.addSubview(view)
//                self.thumbnailView.image = croppedImage

                //分類処理へ
                print("顔を検出しました")
                self.faceClassification()
                break;
            }
        }
    }

    //四角で囲む
    func CreateBoxView(withColor : UIColor) -> UIView {
        let view = UIView()
        view.layer.borderColor = withColor.cgColor
        view.layer.borderWidth = 2
        view.backgroundColor = UIColor.clear
        return view
    }

    //FaceDetectionで返ってきた顔の位置でUIImageで切り抜く
    func transformRect(fromRect: CGRect , toViewRect :UIImage) -> CGRect {

        var toRect = CGRect()
        toRect.size.width = fromRect.size.width * (toViewRect.size.width)
        toRect.size.height = fromRect.size.height * (toViewRect.size.height)
        toRect.origin.y =  (toViewRect.size.height) - ((toViewRect.size.height) * fromRect.origin.y )
        toRect.origin.y  = toRect.origin.y -  toRect.size.height
        toRect.origin.x =  fromRect.origin.x * (toViewRect.size.width)

        return toRect
    }

    // MARK: -顔分類
    func faceClassification(){
        //画像をモデルに渡す形式（CIImage）に変換
        guard let uiImage = self.croppedFace
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
            model = try! VNCoreMLModel(for: Face().model)
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

            //カスタムイベントログ
            Analytics.logEvent("classification", parameters: [
                "class": classification as NSObject,
                "Confidence": best.confidence as NSObject,
                ])

            // 結果画面へ結果の受け渡しと遷移
            let storyboard: UIStoryboard = self.storyboard!
            let nextView = storyboard.instantiateViewController(withIdentifier: "resultviewcontroller") as! ResultViewController
            nextView.result = classification
            nextView.faceImage = self.cropRectangle(image: self.photoImage)
            nextView.modalTransitionStyle = .partialCurl
            self.present(nextView, animated: true, completion: nil)

        }
    }

    // MARK: - UI関連
    //アラート
    func alert(title: String, message:String){
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)

        // OKボタンを追加
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler:{(action:UIAlertAction!) -> Void in
            self.enableButton()
            self.captureSession.startRunning()
        }))

        // UIAlertController を表示
        self.present(alert, animated: true, completion: nil)
    }

    func enableButton(){
        self.shutterButton.isEnabled = true
        self.changeButton.isEnabled = true
        self.backButton.isEnabled = true
        self.indicatorView.isHidden = true
    }

    func disableButton(){
        self.shutterButton.isEnabled = false
        self.changeButton.isEnabled = false
        self.backButton.isEnabled = false
        self.indicatorView.isHidden = false
    }

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

        //インジケータの角丸
        self.indicatorView.layer.cornerRadius = 10
        
        
//        let statusBarHeight = UIApplication.shared.statusBarFrame.size.height
//        let statusBar = UIView(frame:CGRect(x: 0.0, y: 0.0, width: UIScreen.main.bounds.size.width, height: statusBarHeight))
//        statusBar.backgroundColor = UIColor(red: 1, green: 1, blue: 1, alpha: 1.0)
//        view.addSubview(statusBar)
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
    }
    
    /// Tells the delegate an ad request loaded an ad.
    func adViewDidReceiveAd(_ bannerView: GADBannerView) {
        print("adViewDidReceiveAd")

        //TODO: なぜか広告が複数表示される問題の対応
        let bannerViews: Array = self.adView.subviews
        var index:Int = 0;
        for view in bannerViews{
            if(index > 0){
                view.removeFromSuperview()
            }
            index += 1
        }
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

//画像切り抜き
extension UIImage {
    func cropping(to: CGRect) -> UIImage? {
        var opaque = false
        if let cgImage = cgImage {
            switch cgImage.alphaInfo {
            case .noneSkipLast, .noneSkipFirst:
                opaque = true
            default:
                break
            }
        }
        
        UIGraphicsBeginImageContextWithOptions(to.size, opaque, scale)
        draw(at: CGPoint(x: -to.origin.x, y: -to.origin.y))
        let result = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return result
    }
}
//画像反転
extension UIImage {
    func flipHorizontal() -> UIImage {
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        let imageRef = self.cgImage
        let context = UIGraphicsGetCurrentContext()
        context?.translateBy(x: size.width, y: size.height)
        context?.scaleBy(x: -1.0, y: 1.0)
        draw(in: CGRect(x: 0, y: -size.height, width: size.width, height: size.height))
        let flipHorizontalImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return flipHorizontalImage!
    }
}
