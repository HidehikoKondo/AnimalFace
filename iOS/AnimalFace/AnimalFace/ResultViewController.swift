//
//  ResultViewController.swift
//  AnimalFace
//
//  Created by Hidehiko Kondo on 2017/09/14.
//  Copyright © 2017年 UDONKONET. All rights reserved.
//

import UIKit
import GoogleMobileAds
import TwitterKit

class ResultViewController: UIViewController, GADBannerViewDelegate ,GADInterstitialDelegate, UIDocumentInteractionControllerDelegate {
    @IBOutlet weak var resultImage: UIImageView!
    @IBOutlet weak var adView: UIView!
    @IBOutlet weak var buttonInstagram: UIButton!
    @IBOutlet weak var buttonTwitter: UIButton!
    @IBOutlet weak var buttonLine: UIButton!

    var controller: UIDocumentInteractionController!
    var bannerView: GADBannerView!
    var interstitial: GADInterstitial!

    //推論結果結果
    var result: String = ""
    var faceImage: UIImage! = nil

    var resultText = ""
    var shareText = "\n#どうぶつ顔占い\nhttps://itunes.apple.com/jp/app/id1314890802"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.viewGradient()

        //デバッグ用
        if(result == ""){
            result = "inu"
        }
        if(faceImage == nil){
            faceImage = resultImage.image
        }

        //アプリの存在確認
        self.installCheck()
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()

    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        //AdMob
        interstitial = createAndLoadInterstitial()
        self.admobBanner()

        //画像合成
        self.createResultImage()

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    //MARK: 結果画像関連
    func createResultImage(){
        let image1:UIImage = faceImage
        let image2:UIImage = UIImage.init(named: "result-" + result)!
        let image:UIImage = combineImage(imageA: image1, imageB: image2)
        resultImage.image = image;
//        resultImage.layer.cornerRadius = resultImage.frame.size.width * 0.5
//        resultImage.layer.borderColor = UIColor.white.cgColor
//        resultImage.layer.borderWidth = 5
        resultImage.clipsToBounds = true
        
        self.setResultText()
    }

    func setResultText(){
        switch result {
        case "panda":
            resultText = "【パンダ顔】笹食ってる場合じゃねぇ！実は肉食系女子！"
        case "inu":
            resultText = "【いぬ顔】一度好きになった相手にはとことん惚れます！"
        case "koara":
            resultText = "【コアラ顔】夜型なので昼間はそっとしといてね。夜は元気だよ。"
        case "penguin":
            resultText = "【ペンギン顔】いつでもみんなと仲良しパーリーピーポー"
        case "kitsune":
            resultText = "【キツネ顔】気ままにいつもひとり。群れるのがちょっと苦手"
        case "kaba":
            resultText = "【カバ顔】いつも優しそうに見えるけど、キレると超怖いよ！"
        case "kuma":
            resultText = "【くま顔】普段は怖いイメージだけど実はとっても家族思い"
        case "uma":
            resultText = "【うま顔】俺の背後に立つな！おもいっきり蹴っとばすぞ！"
        case "neko":
            resultText = "【ねこ顔】Theツンデレ！！　気まぐれで甘えたり噛み付いたり..."
        case "usagi":
            resultText = "【うさぎ顔】かまってくれないと寂しくて死んじゃうぞ"
        case "risu":
            resultText = "【リス顔】ちょっと怖がりだけど、人なつっこいカワイイ子"
        case "ushi":
            resultText = "【うし顔】いつでもまったりマイペース。のんびり屋さん。"
        default:
            resultText = ""
        }
    }
    
    //合体画像
    func combineImage(imageA:UIImage, imageB:UIImage )-> UIImage{
        var combinedImage: UIImage! =  nil
        let size: CGSize = imageA.size
        let rect: CGRect = CGRect(x:0 , y:0 , width:size.width , height:size.height )
        
        //コンテキスト作成開始
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        imageA.draw(in: rect)
        imageB.draw(in: CGRect(x:0 , y:0 , width:imageA.size.width , height:imageA.size.height))

        //合成
        combinedImage = UIGraphicsGetImageFromCurrentImageContext();

        //合成終了
        UIGraphicsEndImageContext()
        return combinedImage
    }
    
    //MARK: 投稿関連
    func installCheck(){
        if !UIApplication.shared.canOpenURL(NSURL.init(string: "instagram://app")! as URL) {
            //self.buttonInstagram.isEnabled = false
            print("----INSTALL CHECK ---- instagram not exsist")
        }
        if !UIApplication.shared.canOpenURL(NSURL.init(string: "line://")! as URL) {
            //self.buttonLine.isEnabled = false
            print("----INSTALL CHECK ---- LINE not exsist")
        }
        if !UIApplication.shared.canOpenURL(NSURL.init(string: "twitter://")! as URL) {
            //self.buttonTwitter.isEnabled = false
            print("----INSTALL CHECK ---- twitter not exsist")
        }
    }

    //Instagram投稿
    @IBAction func shareInstagram(_ sender: Any) {
        if !UIApplication.shared.canOpenURL(NSURL.init(string: "instagram://app")! as URL) {
            alert(title: "ｱﾚﾚ?>(○´∀｀○)", message: "Instagramをインストールしてね")
            return;
        }

        // Instagram用の投稿画像を作成
        let image = self.resultImage.image
        let imageData = UIImageJPEGRepresentation(image!, 0.9)

        // ファイルのURLを UIDocumentInteractionController に渡す必要があるので、適当な場所に一旦保存する
        let fileURL = NSURL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent("Documents/image.igo")
        try!imageData?.write(to: fileURL!)

        // UIDocumentInteractionController を準備する
        self.controller = UIDocumentInteractionController(url: fileURL!)

        // 写真の共有先設定
        self.controller.uti = "com.instagram.exclusivegram"
        controller.delegate = self

        // メニューを表示する
        if UIApplication.shared.canOpenURL(NSURL.init(string: "instagram://app")! as URL) {
            self.controller.presentOpenInMenu(from: self.view.frame, in: self.view, animated: true)
        } else {
            alert(title: "ｱﾚﾚ?>(○´∀｀○)", message: "Instagramをインストールしてね")
        }
    }

    //UIDocumenteInterectionControllerを閉じたらインタースティシャル広告表示
    func documentInteractionControllerDidDismissOpenInMenu(_ controller: UIDocumentInteractionController) {
        alert(title: "(´▽｀)ｱﾘｶﾞﾄ!", message: "シェアしてくれてありがとう！")
    }

    //Twitter投稿
    @IBAction func shareTitter(_ sender: Any) {
        print("share twitter")

//        Twitter.sharedInstance().logIn(completion: { (session, error) in
//            if let sess = session {
//                print("signed in as \(sess.userName)");
//            } else {
//                print("error: \(error?.localizedDescription)");
//            }
//        })

        let composer = TWTRComposer()
        composer.setText(self.resultText + self.shareText)
        //composer.setImage(UIImage(named: "camera"))
        composer.setImage(self.resultImage.image)
        composer.show(from: self, completion: { result in
            print("show")
            self.alert(title: "(´▽｀)ｱﾘｶﾞﾄ!", message: "シェアしてくれてありがとう！")
        })
    }

    //LINE投稿
    @IBAction func shareLINE(_ sender: Any) {
        //広告
        alert(title: "(´▽｀)ｱﾘｶﾞﾄ!", message: "シェアしてくれてありがとう！")

        //投稿設定
        let pasteBoard = UIPasteboard.general
        pasteBoard.image = self.resultImage.image
        let lineSchemeImage: String = "line://msg/image/%@"
        let scheme = String(format: lineSchemeImage, pasteBoard.name as CVarArg)
        let messageURL: URL! = URL(string: scheme)

        //LINE起動
        if UIApplication.shared.canOpenURL(messageURL) {
            UIApplication.shared.open(messageURL, options: [:], completionHandler: nil)
        } else {
            alert(title: "ｱﾚﾚ?>(○´∀｀○) ", message: "LINEをインストールしてね")
        }
    }


    //MARK: UI
    //その他のシェアボタン
    @IBAction func pushActivityButton(sender: AnyObject) {
        let shareImage:UIImage = resultImage.image! as UIImage

        //ActivityViewController設定
        let activityVc = UIActivityViewController(activityItems: [self.resultText + self.shareText, shareImage], applicationActivities: nil)
        let excludedActivityTypes = [
            UIActivityType.postToWeibo,
            //UIActivityType.message,
            //UIActivityType.mail,
            UIActivityType.print,
            UIActivityType.copyToPasteboard,
            UIActivityType.assignToContact,
            UIActivityType.saveToCameraRoll,
            UIActivityType.addToReadingList,
            UIActivityType.postToFlickr,
            UIActivityType.postToVimeo,
            UIActivityType.postToTencentWeibo,
            UIActivityType.airDrop
        ]
        activityVc.excludedActivityTypes = excludedActivityTypes
        activityVc.completionWithItemsHandler = { [unowned self] (activityType, success, items, error) -> Void in
            // UIActivityViewControllerを閉じたらインタースティシャル広告表示
            self.alert(title: "(´▽｀)ｱﾘｶﾞﾄ!", message: "シェアしてくれてありがとう！")
        }
        // UIAcitivityViewControllerを表示
        self.present(activityVc, animated: true, completion: {
            print("open activityViewController")
        })
    }

    //アラート
    func alert(title: String, message:String){
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)

        // OKボタンを追加
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler:{(action:UIAlertAction!) -> Void in
            self.showInterstitial()
        }))

        // UIAlertController を表示
        self.present(alert, animated: true, completion: nil)
    }

    //戻る
    @IBAction func back(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }

    //保存ボタン
    @IBAction func saveToLibrary(_ sender: Any) {
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
            title = "ｱﾚﾚ?>(○´∀｀○) "
            message = "診断結果の保存に失敗しました"
        }

        alert(title: title, message: message)
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
        
//        
//        let statusBarHeight = UIApplication.shared.statusBarFrame.size.height
//        let statusBar = UIView(frame:CGRect(x: 0.0, y: 0.0, width: UIScreen.main.bounds.size.width, height: statusBarHeight))
//        statusBar.backgroundColor = UIColor(red: 1, green: 1, blue: 1, alpha: 1.0)
//        view.addSubview(statusBar)
    }

    
    //MARK: AdMob banner
    func admobBanner(){
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
    func adView(_ bannerView: GADBannerView, didFailToReceiveAdWithError error: GADRequestError) {
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


    //MARK: AdMob interstitial
    //インタースティシャル（ロードが終わったらこれを呼び出す）
    func showInterstitial(){
        if interstitial.isReady {
            interstitial.present(fromRootViewController: self)
        } else {
            print("Ad wasn't ready")
        }
    }

    //インタースティシャルロード
    func createAndLoadInterstitial() -> GADInterstitial {
        var interstitial = GADInterstitial(adUnitID: "ca-app-pub-3324877759270339/9498075835")
        interstitial.delegate = self
        interstitial.load(GADRequest())
        return interstitial
    }
    
    func interstitialDidDismissScreen(_ ad: GADInterstitial) {
        interstitial = createAndLoadInterstitial()
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
    
    /// Tells the delegate that a user click will open another app
    /// (such as the App Store), backgrounding the current app.
    func interstitialWillLeaveApplication(_ ad: GADInterstitial) {
        print("interstitialWillLeaveApplication")
    }
}
