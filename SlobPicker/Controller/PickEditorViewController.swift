//
//  PickEditorViewController.swift
//  SlobPicker
//
//  Created by 孔令傑 on 2022/11/2.
//

import UIKit
import PhotosUI

class PickEditorViewController: UIViewController {
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var filenameLabel: UILabel!
    
    // MARK: Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    private var willBeUploadedData: [UIImage]?
    
    @IBAction func pickPic() {
        var configuration = PHPickerConfiguration()
        configuration.filter = .images
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = self
        present(picker, animated: true)
    }
    
    @objc func publishPicker() {
        guard let data = willBeUploadedData else { fatalError("UIImages have not been found") }
        for image in data {
            // transform image file type
            if let uploadData = image.jpegData(compressionQuality: 0.001) {
                // Deal with png file uploading
                let uniqueString = UUID().uuidString
                let dataRef = FirebaseManager.shared.storageRef.child("\(uniqueString).jpeg")
                dataRef.putData(uploadData) { data, error in
                    if let error = error {
                        print(error, "ERROR for uploading data to firebase storage")
                    } else {
                        dataRef.downloadURL { url, error in
                            guard let downloadURL = url else {
                                print(error, "ERROR: URL uploading issue")
                                return
                            }
                            // TODO: upload URL TO firebase DB
                            print(downloadURL)
                        }
                    }
                }
            }
        }
        
    }
}

extension PickEditorViewController: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        let result = results.first
        let itemProvider = result?.itemProvider
        if let itemProvider = itemProvider, itemProvider.canLoadObject(ofClass: UIImage.self) {
            itemProvider.loadObject(ofClass: UIImage.self) { [weak self] (image, error) in
                DispatchQueue.main.async {
                    guard let image = image as? UIImage, let self = self else {
                        print("=========")
                        print(error ?? "no error")
                        return }
                    self.willBeUploadedData?.append(image)
                    self.imageView.image = image
                    self.filenameLabel.text = itemProvider.suggestedName
                }
            }
        }
    }
}
