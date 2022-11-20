//
//  PickCommentsCell.swift
//  SlobPicker
//
//  Created by 孔令傑 on 2022/11/4.
//

import UIKit

class PickCommentsCell: UITableViewCell {
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var commentLabel: UILabel!
    @IBOutlet weak var profileImage: UIImageView!
    
    func configure(data: Comment) {
        nameLabel.text = data.userID
        commentLabel.text = data.comment
        profileImage.layer.cornerRadius = profileImage.bounds.width / 2
        profileImage.clipsToBounds = true
    }
}
