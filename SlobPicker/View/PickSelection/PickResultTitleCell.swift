//
//  PickResultTitleCell.swift
//  SlobPicker
//
//  Created by 孔令傑 on 2022/11/26.
//

import UIKit

class PickResultTitleCell: UITableViewCell {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var dpLabel: UILabel!
    @IBOutlet weak var bgView: UIView!
    
    func configure(title: String, description: String) {
        titleLabel.text = title
        dpLabel.text = description
        bgView.clipsToBounds = false
        bgView.layer.cornerRadius = 15
    }
}
