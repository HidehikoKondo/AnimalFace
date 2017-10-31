//
//  ResultViewController.swift
//  AnimalFace
//
//  Created by Hidehiko Kondo on 2017/09/14.
//  Copyright © 2017年 UDONKONET. All rights reserved.
//

import UIKit
import GoogleMobileAds

class ResultViewController: UIViewController, GADBannerViewDelegate ,GADInterstitialDelegate {
    @IBOutlet weak var resultImage: UIImageView!
    @IBOutlet weak var adView: UIView!
    var bannerView: GADBannerView!
    var interstitial: GADInterstitial!
    //推論結果結果
    var result: String = ""
    var faceImage: UIImage! = nil
    
    //@IBOutlet weak var resultLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()
        self.viewGradient()
        
        //AdMob
        interstitial = createAndLoadInterstitial()

        //結果表示
        //resultLabel.text = result
        
        //画像合成
        
        let image1:UIImage = UIImage.init(named: "result-" + result)!
        let image2:UIImage = faceImage
        let image:UIImage = combineImage(imageA: image1, imageB: image2)
        resultImage.image = image;
        
        resultImage.layer.cornerRadius = resultImage.frame.size.width * 0.5
        resultImage.layer.borderColor = UIColor.white.cgColor
        resultImage.layer.borderWidth = 5

        resultImage.clipsToBounds = true
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.admob()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    func combineImage(imageA:UIImage, imageB:UIImage )-> UIImage{
        //合体画像
        var combinedImage: UIImage! =  nil
        
        //決定
        let size: CGSize = imageA.size
        let rect: CGRect = CGRect(x:0 , y:0 , width:size.width , height:size.height )
        
        //コンテキスト作成開始
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        
        imageA.draw(in: rect)
        imageB.draw(in: CGRect(x:135 , y:77 , width:100 , height:100))
        
        //合成
        combinedImage = UIGraphicsGetImageFromCurrentImageContext();
        
        //合成終了
        UIGraphicsEndImageContext()
        
        return combinedImage
    }
    
    //MARK: UI
    @IBAction func pushActivityButton(sender: AnyObject) {
        let text = "Share!!"
        let shareImage:UIImage = resultImage.image! as UIImage
        // UIActivityViewControllerをインスタンス化
        let activityVc = UIActivityViewController(activityItems: [text, shareImage], applicationActivities: nil)

        //アクティビティに表示したくない機能やアプリを指定
        let excludedActivityTypes = [
            UIActivityType.postToWeibo,
            //UIActivityType.message,
            //UIActivityType.mail,
            UIActivityType.print,
            UIActivityType.copyToPasteboard,
            UIActivityType.assignToContact,
            //UIActivityType.saveToCameraRoll,
            UIActivityType.addToReadingList,
            UIActivityType.postToFlickr,
            UIActivityType.postToVimeo,
            UIActivityType.postToTencentWeibo,
            UIActivityType.airDrop
        ]
        activityVc.excludedActivityTypes = excludedActivityTypes

        activityVc.completionWithItemsHandler = { [unowned self] (activityType, success, items, error) -> Void in
            print("clsoe activityViewController")
        }
        // UIAcitivityViewControllerを表示
        self.present(activityVc, animated: true, completion: {
            print("open activityViewController")
        })
    }

    
    @IBAction func back(_ sender: Any) {
        //self.dismiss(animated: true, completion: nil)
        self.presentingViewController?.presentingViewController?.dismiss(animated: true, completion: nil)
    }

    @IBAction func saveToLibrary(_ sender: Any) {
        print("結果を保存")
        // その中の UIImage を取得
        let targetImage = resultImage.image!

        // UIImage の画像をカメラロールに画像を保存
        UIImageWriteToSavedPhotosAlbum(targetImage, self, #selector(self.showResultOfSaveImage(_:didFinishSavingWithError:contextInfo:)), nil)
    }

    // 保存を試みた結果をダイアログで表示
    @objc func showResultOfSaveImage(_ image: UIImage, didFinishSavingWithError error: NSError!, contextInfo: UnsafeMutableRawPointer) {
        var title = "カメラロールに保存しました"
        var message = "SNSのアイコンにして、診断結果をみんなにシェアしよう！(≧∀≦*)"

        if error != nil {
            title = "エラーだよ><"
            message = "診断結果の保存に失敗しました"
        }

        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)

        // OKボタンを追加
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler:{
            (action:UIAlertAction!) -> Void in
            print("OK")
        }))

        // UIAlertController を表示
        self.present(alert, animated: true, completion: nil)
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
    
    //インタースティシャル（ロードが終わったらこれを呼び出す）
    func showInterstitial(){
        if interstitial.isReady {
            interstitial.present(fromRootViewController: self)
        } else {
            print("Ad wasn't ready")
        }
    }
    
    func createAndLoadInterstitial() -> GADInterstitial {
        var interstitial = GADInterstitial(adUnitID: "ca-app-pub-3324877759270339/9498075835")
        interstitial.delegate = self
        interstitial.load(GADRequest())
        return interstitial
    }
    
    func interstitialDidDismissScreen(_ ad: GADInterstitial) {
        interstitial = createAndLoadInterstitial()
    }
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
    }

    
    /// Tells the delegate an ad request succeeded.
    func interstitialDidReceiveAd(_ ad: GADInterstitial) {
        print("interstitialDidReceiveAd")
    }
    
    /// Tells the delegate an ad request failed.
    func interstitial(_ ad: GADInterstitial, didFailToReceiveAdWithError error: GADRequestError) {
        print("interstitial:didFailToReceiveAdWithError: \(error.localizedDescription)")
    }
    
    /// Tells the delegate that an interstitial will be presented.
    func interstitialWillPresentScreen(_ ad: GADInterstitial) {
        print("interstitialWillPresentScreen")
    }
    
    /// Tells the delegate the interstitial is to be animated off the screen.
    func interstitialWillDismissScreen(_ ad: GADInterstitial) {
        print("interstitialWillDismissScreen")
    }
    
    //    /// Tells the delegate the interstitial had been animated off the screen.
    //    func interstitialDidDismissScreen(_ ad: GADInterstitial) {
    //        print("interstitialDidDismissScreen")
    //    }
    
    /// Tells the delegate that a user click will open another app
    /// (such as the App Store), backgrounding the current app.
    func interstitialWillLeaveApplication(_ ad: GADInterstitial) {
        print("interstitialWillLeaveApplication")
    }
}
