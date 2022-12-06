//
//  GroupCell.swift
//  SlobPicker
//
//  Created by 孔令傑 on 2022/12/2.
//

import UIKit

class GroupManageCell: UITableViewCell {
    @IBOutlet weak var groupTitleLabel: UILabel!
    
    func configure(groupTitle: String) {
        groupTitleLabel.text = groupTitle
    }
}
