//
//  ProfileImageCell.swift
//  SlobPicker
//
//  Created by 孔令傑 on 2022/12/8.
//

import UIKit
import PhotosUI

class ProfileImageCell: UITableViewCell, ProfileCell {
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var changeButton: UIButton!
    var bundleData: ProfileImage?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        profileImageView.layer.cornerRadius
        = profileImageView.bounds.width / 2
    }
    
    func configure(data: CellModel) {
        guard let data = data as? ProfileImage else { return print("error: getting wrong data from PofileViewController to ProfileImageCell") }
        bundleData = data
        profileImageView.loadImage(data.imageURL, placeHolder: UIImage.asset(.user))
        changeButton.addTarget(self, action: #selector(choosePhoto), for: .touchUpInside)
    }
    
    @objc func choosePhoto() {
        var configuration = PHPickerConfiguration()
        configuration.filter = .images
        let picker = PHPickerViewController(configuration: configuration)
        guard let data = bundleData else { return print("") }
        picker.delegate = data.superVC
        data.superVC.present(picker, animated: true)
    }
}
