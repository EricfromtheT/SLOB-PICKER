//
//  GroupNameCell.swift
//  SlobPicker
//
//  Created by 孔令傑 on 2022/12/2.
//

import UIKit

class GroupNameCell: UITableViewCell {
    @IBOutlet weak var nameLabel: UILabel!
    
    func configure(name: String) {
        nameLabel.text = name
    }
}
