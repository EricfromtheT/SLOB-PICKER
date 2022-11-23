//
//  FriendSelectCell.swift
//  SlobPicker
//
//  Created by 孔令傑 on 2022/11/5.
//

import UIKit

class FriendSelectCell: UITableViewCell {
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var chosenMarkImageView: UIImageView!
    
    func configure(data: FriendListObject) {
        profileImageView.loadImage(data.info.profileURL, placeHolder: UIImage.asset(.user))
        nameLabel.text = data.info.userID
        chosenMarkImageView.image = UIImage(named: "check")
        chosenMarkImageView.isHidden = true
    }
}
