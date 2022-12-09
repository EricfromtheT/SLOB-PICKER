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
    
    override func awakeFromNib() {
        super.awakeFromNib()
        profileImageView.layer.cornerRadius
        = profileImageView.bounds.width / 2
    }
    
    func configure(data: User) {
        profileImageView.loadImage(data.profileURL, placeHolder: UIImage.asset(.user))
        changeButton.addTarget(self, action: #selector(choosePhoto), for: .touchUpInside)
    }
    
    @objc func choosePhoto() {
        var configuration = PHPickerConfiguration()
        configuration.filter = .images
        let picker = PHPickerViewController(configuration: configuration)
        guard let superVC = self.parentContainerViewController() as? ProfileViewController
        else { fatalError("error of getting parent view controller from ProfileImageCell") }
        picker.delegate = superVC
        superVC.present(picker, animated: true)
    }
}
