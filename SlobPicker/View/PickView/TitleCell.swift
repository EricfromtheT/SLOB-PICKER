//
//  TitleCell.swift
//  SlobPicker
//
//  Created by 孔令傑 on 2022/10/31.
//

import UIKit

class TitleCell: UITableViewCell {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var bgView: UIView!
    
    func configure(data: Picker) {
        bgView.layer.cornerRadius = 20
        titleLabel.text = data.title
        descriptionLabel.text = data.description
    }
}
