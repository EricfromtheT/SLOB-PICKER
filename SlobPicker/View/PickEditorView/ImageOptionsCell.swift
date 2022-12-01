//
//  ImageOptionsCell.swift
//  SlobPicker
//
//  Created by 孔令傑 on 2022/11/2.
//

import UIKit
import PhotosUI

class ImageOptionsCell: UITableViewCell {
    @IBOutlet var imageNameLabels: [UILabel]!
    @IBOutlet var imagePickView: [UIImageView]!
    @IBOutlet var deleteView: [UIImageView]!
    weak var superVC: PickerEditorViewController?
    var deleteCompletion: ((Int) -> Void)?
    
//    func configure(superVC: PickerEditorViewController) {
//        self.superVC = superVC
//        for (idx, button) in imagePickButtons.enumerated() {
//            button.addTarget(self, action: #selector(pickPic), for: .touchUpInside)
//            button.tag = idx
//            imageNameLabels[idx].text = "照片\(idx)"
//        }
//        superVC.imageUploadCompletely = { filename, index in
//            self.imageNameLabels[index].text = filename
//        }
//    }
    
    func configure(superVC: PickerEditorViewController) {
        self.superVC = superVC
        for (idx, imgView) in imagePickView.enumerated() {
            imgView.isUserInteractionEnabled = true
            imgView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(pickPic)))
            imgView.tag = idx
            imgView.layer.cornerRadius = 15
            imgView.contentMode = .scaleAspectFill
            imgView.clipsToBounds = true
            imageNameLabels[idx].text = "請上傳照片"
            imagePickView[idx].image = UIImage.asset(.upload)
            deleteView[idx].isHidden = true
            deleteView[idx].tag = idx
            deleteView[idx].isUserInteractionEnabled = true
            deleteView[idx].addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(deletePic)))
        }
        superVC.imageUploadCompletely = { filename, image, index in
            self.imageNameLabels[index].text = filename
            self.imagePickView[index].image = image
            self.deleteView[index].isHidden = false
        }
    }
    
    @objc func pickPic(_ sender: UITapGestureRecognizer) {
        var configuration = PHPickerConfiguration()
        configuration.filter = .images
        let picker = PHPickerViewController(configuration: configuration)
        guard let superVC = superVC else {
            print("ERROR: vc has not been import")
            return }
        superVC.clickIndex = sender.view?.tag
        picker.delegate = superVC
        superVC.present(picker, animated: true)
    }
    
    @objc func deletePic(_ sender: UITapGestureRecognizer) {
        if let view = sender.view {
            imagePickView[view.tag].image = UIImage.asset(.upload)
            deleteView[view.tag].isHidden = true
            deleteCompletion?(view.tag)
        } else {
            fatalError("image view with no tag")
        }
    }
}

