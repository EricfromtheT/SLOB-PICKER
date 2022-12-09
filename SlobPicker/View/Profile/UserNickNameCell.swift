//
//  UserNickNameCell.swift
//  SlobPicker
//
//  Created by 孔令傑 on 2022/12/8.
//

import UIKit

class UserNickNameCell: UITableViewCell, ProfileCell {
    @IBOutlet weak var nickNameLabel: UILabel!
    
    func configure(data: User) {
        nickNameLabel.text = data.userName
    }
}
