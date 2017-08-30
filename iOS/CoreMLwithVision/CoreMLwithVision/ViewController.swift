//
//  ViewController.swift
//  CoreMLwithVision
//
//  Created by Hidehiko Kondo on 2017/07/28.
//

import UIKit
import UIKit
import CoreML
import Vision
import ImageIO


class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    //Outlets
    @IBOutlet weak var cameraView: UIImageView!
    @IBOutlet weak var resultLabel: UILabel!
    @IBOutlet weak var segmentedControl: UISegmentedControl!

    //values
    var inputImage: CIImage!

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    //　撮影が完了時した時に呼ばれる
    func imagePickerController(_ imagePicker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        print("撮影完了")
        self.resultLabel.text = "Analyzing Image…"
        if let pickedImage = info[UIImagePickerControllerOriginalImage] as? UIImage {
            self.cameraView.contentMode = .scaleAspectFit
            self.cameraView.image = pickedImage
        }

        // 閉じる処理
        imagePicker.dismiss(animated: true, completion: {

            //画像をモデルに渡す形式（CIImage）に変換
            guard let uiImage = info[UIImagePickerControllerOriginalImage] as? UIImage
                else { fatalError("no image from image picker") }
            guard let ciImage = CIImage(image: uiImage)
                else { fatalError("can't create CIImage from UIImage") }
            let orientation = CGImagePropertyOrientation(uiImage.imageOrientation)
            self.inputImage = ciImage.oriented(forExifOrientation: Int32(orientation.rawValue))

            //読み込んだ画像をそのまま推論処理へ
            let handler = VNImageRequestHandler(ciImage: self.inputImage)
            do {
                if(self.segmentedControl.selectedSegmentIndex == 2){
                    try handler.perform([self.classificationRequest_dogorcat])
                }

            } catch {
                print(error)
            }
        })
    }

    lazy var classificationRequest_dogorcat: VNCoreMLRequest = {
        // Load the ML model through its generated class and create a Vision request for it.
        do {
            var model: VNCoreMLModel? = nil
            model = try! VNCoreMLModel(for: xxxxxModel().model)
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
            self.resultLabel.text = "Classification: \"\(classification)\" Confidence: \(best.confidence)"
        }
    }


    @IBAction func openCamera(_ sender: Any) {
        print("カメラを開く")
        let sourceType:UIImagePickerControllerSourceType = UIImagePickerControllerSourceType.camera
        // カメラが利用可能かチェック
        if UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.camera){
            // インスタンスの作成
            let cameraPicker = UIImagePickerController()
            cameraPicker.sourceType = sourceType
            cameraPicker.delegate = self
            self.present(cameraPicker, animated: true, completion: nil)
        } else {
            print("error")
        }
    }

    @IBAction func openPicker(_ sender: UIButton) {
        print("ピッカー開く")
        let sourceType:UIImagePickerControllerSourceType = UIImagePickerControllerSourceType.photoLibrary

        let imagePicker = UIImagePickerController()
        imagePicker.sourceType = sourceType
        imagePicker.delegate = self
        self.present(imagePicker, animated: true, completion: nil)
    }


    // 撮影がキャンセルされた時に呼ばれる
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        print("撮影キャンセル")
        picker.dismiss(animated: true, completion: nil)
    }

}

