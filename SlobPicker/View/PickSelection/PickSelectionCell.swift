//
//  PickSelectionCell.swift
//  SlobPicker
//
//  Created by 孔令傑 on 2022/11/3.
//

import UIKit

class PickSelectionCell: UITableViewCell {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var authorLabel: UILabel!
    
    func configure(data: Pick) {
        titleLabel.text = data.title
        authorLabel.text = data.authorName
    }
}
