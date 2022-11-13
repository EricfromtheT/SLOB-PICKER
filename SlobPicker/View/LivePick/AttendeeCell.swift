//
//  AttendeeCell.swift
//  SlobPicker
//
//  Created by 孔令傑 on 2022/11/11.
//

import UIKit

class AttendeeCell: UICollectionViewCell {
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var NameLabel: UILabel!
    
    func configure(data: User) {
        profileImageView.loadImage(data.profileURL)
        NameLabel.text = data.userID
    }
}
