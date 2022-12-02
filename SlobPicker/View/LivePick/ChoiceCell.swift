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
    @IBOutlet weak var bgView: UIView!
    
    func configure(title: String, result: VoteResult) {
        titleLabel.text = title
        votesLabel.text = "\(result.votes)"
        bgView.layer.cornerRadius = 20
        
        bgView.layer.shadowColor = UIColor.gray.cgColor
        bgView.layer.shadowOpacity = 0.3
        bgView.layer.shadowOffset = CGSize(width: 0, height: 5)
        bgView.layer.shadowRadius = 2
        bgView.layer.shadowPath = UIBezierPath(roundedRect: CGRect(x: 0,
                                                                   y: 0,
                                                                   width: SPConstant.screenWidth - 40,
                                                                   height: bgView.bounds.height),
                                                      cornerRadius: 20).cgPath
    }
}
