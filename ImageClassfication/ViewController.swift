//
//  ViewController.swift
//  ImageClassfication
//
//  Created by NeppsStaff on 2021/04/21.
//

import UIKit
import CoreML
import Vision

class ViewController: UIViewController,
                      UIImagePickerControllerDelegate,
                      UINavigationControllerDelegate {
    
    var model = try! VNCoreMLModel(for: MobileNetV2().model)

    @IBOutlet var imageView: UIImageView!
    @IBOutlet var resultText: UITextView!
    
    func showActionSheet() {
        let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        actionSheet.addAction(UIAlertAction(title: "フォトライブラリ", style: .default) {
            action in
            self.showPicker(sourceType: .photoLibrary)
        })
        actionSheet.addAction(UIAlertAction(title: "キャンセル", style: .cancel))
        self.present(actionSheet, animated: true, completion: nil)
    }
    
    //起動時に呼ばれる
    override func viewDidAppear(_ animated: Bool) {
        if self.imageView.image == nil {
            showActionSheet()
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        showActionSheet()
    }
    
    //open imagePicker
    func showPicker(sourceType: UIImagePickerController.SourceType) {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = self
        self.present(picker, animated: true, completion: nil)
    }
    
    //imagePickerの画像取得時の処理
    func imagePickerController(_ picker: UIImagePickerController,
                               didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        var image = info[UIImagePickerController.InfoKey.originalImage] as! UIImage
        
        let size = image.size
        UIGraphicsBeginImageContext(size)
        image.draw(in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
        image = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        
        self.imageView.image = image
        
        picker.presentingViewController!.dismiss(animated: true, completion: nil)
        
        predict(image)
    }
    
    //imagePickerキャンセル時の処理
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.presentingViewController!.dismiss(animated: true, completion: nil)
    }

    //show alert
    func showAlert(_ text: String!) {
        let alert = UIAlertController(title: text, message: nil, preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    //画像分類の実行
    func predict(_ image: UIImage) {
        DispatchQueue.global(qos: .default).async {
            let request = VNCoreMLRequest(model: self.model) {
                request, error in
                if error != nil {
                    self.showAlert(error!.localizedDescription)
                    return
                }
                
                let obserbations = request.results as! [VNClassificationObservation]
                var text: String = "\n"
                
                for i in 0..<min(3, obserbations.count) {
                    let rate = Int(obserbations[i].confidence*100)
                    let identifier = obserbations[i].identifier
                    text += "\(identifier) : \(rate)%\n"
                }
                
                DispatchQueue.main.async {
                    self.resultText.text = text
                    print(text)
                }
            }
            
            request.imageCropAndScaleOption = .centerCrop
            
            let ciImage = CIImage(image: image)!
            
            let orientation = CGImagePropertyOrientation(rawValue: UInt32(image.imageOrientation.rawValue))!
            
            let handler = VNImageRequestHandler(ciImage: ciImage, orientation: orientation)
            guard (try? handler.perform([request])) != nil else {
                return
            }
        }
    }

}

