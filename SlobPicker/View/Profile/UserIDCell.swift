//
//  UserIDCell.swift
//  SlobPicker
//
//  Created by 孔令傑 on 2022/12/8.
//

import UIKit

class UserIDCell: UITableViewCell, ProfileCell {
    @IBOutlet weak var idLabel: UILabel!
    
    func configure(data: User) {
        idLabel.text = data.userID
    }
}
