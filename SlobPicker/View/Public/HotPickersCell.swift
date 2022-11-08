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
    
    func configure(data: PublicPicker, imageURL: String, hasLiked: Bool) {
        profileImageView.loadImage(imageURL)
        userNameLabel.text = data.authorName
        titleLabel.text = data.title
        let heartName = hasLiked ? "heart" : "empty-heart"
        heartImageView.image = UIImage(named: heartName)
        heartCountLabel.text = "\(data.likedCount)"
        pickCountLabel.text = "\(data.pickedCount)"
        pickImageView.image = UIImage(named: "picking")
    }
}
