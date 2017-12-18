//
//  ViewController.swift
//  AnimalFace
//
//  Created by Hidehiko Kondo on 2017/09/13.
//  Copyright © 2017年 UDONKONET. All rights reserved.
//

import UIKit
import GoogleMobileAds
import Firebase

class ViewController: UIViewController, GADBannerViewDelegate{
    @IBOutlet weak var adView: UIView!
    var bannerView: GADBannerView!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.

        self.viewGradient()

        //イベントログ
        Analytics.logEvent(AnalyticsEventSelectContent, parameters: [
            AnalyticsParameterItemID: "ViewController" as NSObject,
            AnalyticsParameterItemName: "ViewController" as NSObject,
            AnalyticsParameterContentType: "cont" as NSObject
            ])
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.admob()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
        bannerView.delegate = self
        bannerView.adUnitID = "ca-app-pub-3324877759270339/5533467015"
        bannerView.rootViewController = self
        bannerView.load(GADRequest())
        self.adView.addSubview(bannerView)

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

