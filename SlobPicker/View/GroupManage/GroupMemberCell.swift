//
//  GroupMemberCell.swift
//  SlobPicker
//
//  Created by 孔令傑 on 2022/12/4.
//

import UIKit

class GroupMemberCell: UITableViewCell {
    @IBOutlet weak var profileImageView: UIImageView! {
        didSet {
            profileImageView.layer.cornerRadius = profileImageView.bounds.width / 2
        }
    }
    @IBOutlet weak var nameLabel: UILabel!
    
    func configure(user: User) {
        profileImageView.loadImage(user.profileURL, placeHolder: UIImage.asset(.user))
        nameLabel.text = user.userName
    }
}
