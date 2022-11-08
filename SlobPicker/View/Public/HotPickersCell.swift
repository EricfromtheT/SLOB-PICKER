//
//  HotPickersCell.swift
//  SlobPicker
//
//  Created by 孔令傑 on 2022/11/7.
//

import UIKit

class HotPickerCell: UICollectionViewCell {
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var userNameLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var heartImageView: UIImageView!
    @IBOutlet weak var heartCountLabel: UILabel!
    @IBOutlet weak var pickCountLabel: UILabel!
    @IBOutlet weak var pickImageView: UIImageView!
    
    func configure(data: Picker, imageURL: String, hasLiked: Bool, hasPicked: Bool) {
        profileImageView.loadImage(imageURL)
        userNameLabel.text = data.authorName
        titleLabel.text = data.title
        let heartImageName = hasLiked ? "heart" : "empty-heart"
        heartImageView.image = UIImage(named: heartImageName)
        let pickImageName = hasPicked ? "picking" : "empty-picking"
        pickImageView.image = UIImage(named: pickImageName)
        heartCountLabel.text = "\(data.likedCount ?? 0 )"
        pickCountLabel.text = "\(data.pickedCount ?? 0 )"
    }
}
