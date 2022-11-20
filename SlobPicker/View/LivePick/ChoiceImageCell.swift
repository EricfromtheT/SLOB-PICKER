//
//  ChoiceImageCell.swift
//  SlobPicker
//
//  Created by 孔令傑 on 2022/11/20.
//

import UIKit

class ChoiceImageCell: UITableViewCell {
    @IBOutlet weak var mainImageView: UIImageView!
    @IBOutlet weak var votesLabel: UILabel!
    
    func configure(url: String, result: VoteResult) {
        mainImageView.contentMode = .scaleAspectFill
        mainImageView.clipsToBounds = true
        mainImageView.loadImage(url)
        votesLabel.text = "\(result.votes)"
    }
}
