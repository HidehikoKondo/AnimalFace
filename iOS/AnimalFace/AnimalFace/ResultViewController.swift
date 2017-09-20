//
//  ResultViewController.swift
//  AnimalFace
//
//  Created by Hidehiko Kondo on 2017/09/14.
//  Copyright © 2017年 UDONKONET. All rights reserved.
//

import UIKit

class ResultViewController: UIViewController {
    @IBOutlet weak var image: UIImageView!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

    @IBAction func pushActivityButton(sender: AnyObject) {
        let text = "Share!!"
        let shareImage:UIImage = image.image! as UIImage




        // UIActivityViewControllerをインスタンス化
        let activityVc = UIActivityViewController(activityItems: [text, shareImage], applicationActivities: nil)

        // UIAcitivityViewControllerを表示
        self.present(activityVc, animated: true, completion: nil)
    }

    
    @IBAction func back(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }

}
