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
    @IBOutlet weak var bgView: UIView!
    
    func configure(url: String, result: VoteResult) {
        mainImageView.contentMode = .scaleAspectFill
        mainImageView.clipsToBounds = true
        mainImageView.layer.cornerRadius = 20
        mainImageView.loadImage(url, placeHolder: UIImage.asset(.image))
        votesLabel.text = "\(result.votes)"
        bgView.layer.cornerRadius = 20
    }
}
