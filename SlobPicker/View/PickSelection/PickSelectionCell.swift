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
    @IBOutlet weak var groupNameLabel: UILabel!
    @IBOutlet weak var pickButton: UIButton!
    @IBOutlet weak var resultButton: UIButton!
    @IBOutlet weak var bgView: UIView!
    @IBOutlet weak var profileImageView: UIImageView!
    var leftColor: [UIColor?] = [UIColor.asset(.card1left), UIColor.asset(.card2left), UIColor.asset(.card3left), UIColor.asset(.card4left)]
    var rightColor: [UIColor?] = [UIColor.asset(.card1right), UIColor.asset(.card2right), UIColor.asset(.card3right), UIColor.asset(.card4right)]
    let gradientLayer = CAGradientLayer()
    
    func configure(data: Picker, index: Int, url: String?) {
        profileImageView.loadImage(url, placeHolder: UIImage.asset(.user))
        profileImageView.layer.cornerRadius = profileImageView.bounds.width / 2
        titleLabel.text = data.title
        authorLabel.text = data.authorID
        groupNameLabel.text = data.groupName
        pickButton.tag = index
        resultButton.tag = index
        bgView.layer.cornerRadius = 20
        gradientLayer.cornerRadius = 20
        gradientLayer.frame = CGRect(x: 0, y: 0, width: SPConstant.screenWidth*0.85, height: 150)
        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer.endPoint = CGPoint(x: 1, y: 1)
        gradientLayer.colors = [leftColor[index % 4]?.cgColor , rightColor[index % 4]?.cgColor]
        bgView.layer.insertSublayer(gradientLayer, at: 0)
    }
}
