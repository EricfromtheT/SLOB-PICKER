//
//  ChoiceCell.swift
//  SlobPicker
//
//  Created by 孔令傑 on 2022/11/13.
//

import UIKit

class ChoiceCell: UITableViewCell {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var votesLabel: UILabel!
    
    func configure(title: String, result: VoteResult) {
        titleLabel.text = title
        votesLabel.text = "\(result.votes)"
    }
}
