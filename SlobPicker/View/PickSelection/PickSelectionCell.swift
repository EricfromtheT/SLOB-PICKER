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
    @IBOutlet weak var pickButton: UIButton!
    @IBOutlet weak var resultButton: UIButton!
    
    func configure(data: PrivatePicker, index: Int) {
        titleLabel.text = data.title
        authorLabel.text = data.authorName
        pickButton.tag = index
        resultButton.tag = index
    }
}
