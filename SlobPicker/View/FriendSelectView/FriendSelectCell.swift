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
        profileImageView.loadImage(data.info.profileURL)
        nameLabel.text = data.info.userName
        chosenMarkImageView.image = UIImage(named: "check")
        chosenMarkImageView.isHidden = true
    }
}
