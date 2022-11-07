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
    @IBOutlet var imagePickButtons: [UIButton]!
    weak var superVC: PickerEditorViewController?
    
    func configure(superVC: PickerEditorViewController) {
        self.superVC = superVC
        for (idx, button) in imagePickButtons.enumerated() {
            button.addTarget(self, action: #selector(pickPic), for: .touchUpInside)
            button.tag = idx
        }
        superVC.imageUploadCompletely = { filename, index in
            self.imageNameLabels[index].text = filename
        }
    }
    
    @objc func pickPic(_ sender: UIButton) {
        var configuration = PHPickerConfiguration()
        configuration.filter = .images
        let picker = PHPickerViewController(configuration: configuration)
        guard let superVC = superVC else {
            print("ERROR: vc has not been import")
            return }
        superVC.clickIndex = sender.tag
        picker.delegate = superVC
        superVC.present(picker, animated: true)
    }
}

