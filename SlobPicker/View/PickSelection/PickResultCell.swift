//
//  PickResultCell.swift
//  SlobPicker
//
//  Created by 孔令傑 on 2022/11/4.
//

import UIKit
 
class PickResultCell: UITableViewCell {
    @IBOutlet weak var bgView: UIView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var votesLabel: UILabel!
    @IBOutlet weak var optionImageView: UIImageView!
    @IBOutlet weak var containerView: UIView!
    let colors: [UIColor?] = [UIColor.asset(.result1), UIColor.asset(.result2), UIColor.asset(.result3), UIColor.asset(.result4)]
    
    func configureText(content: String, votes: Int, total: Int, index: Int) {
        optionImageView.isHidden = true
        containerView.isHidden = true
        titleLabel.text = content
        votesLabel.text = String(votes)
        bgView.layer.cornerRadius = 15
        let colorView = UIView()
        colorView.backgroundColor = colors[index]
        colorView.layer.cornerRadius = 15
        if total == 0 {
            return
        }
        bgView.addSubview(colorView)
        bgView.sendSubviewToBack(colorView)
        colorView.translatesAutoresizingMaskIntoConstraints = false
        colorView.leadingAnchor.constraint(equalTo: bgView.leadingAnchor).isActive = true
        colorView.topAnchor.constraint(equalTo: bgView.topAnchor).isActive = true
        colorView.bottomAnchor.constraint(equalTo: bgView.bottomAnchor).isActive = true
        if votes == total {
            colorView.trailingAnchor.constraint(equalTo: bgView.trailingAnchor).isActive = true
        } else {
            colorView.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMinXMinYCorner]
            colorView.widthAnchor
                .constraint(equalTo: bgView.widthAnchor, multiplier: CGFloat(Float(votes)/Float(total))).isActive = true
        }
    }
    
    func configureImage(content: String, votes: Int, total: Int, index: Int) {
        titleLabel.isHidden = true
        optionImageView.layer.cornerRadius = 15
        optionImageView.loadImage(content, placeHolder: UIImage.asset(.image))
        containerView.backgroundColor = .systemGray4
        optionImageView.applyshadowWithCorner(containerView: containerView, cornerRadious: 15)
        votesLabel.text = String(votes)
        bgView.layer.cornerRadius = 15
        let colorView = UIView()
        colorView.backgroundColor = colors[index]
        colorView.layer.cornerRadius = 15
        if total == 0 {
            return
        }
        bgView.addSubview(colorView)
        bgView.sendSubviewToBack(colorView)
        colorView.translatesAutoresizingMaskIntoConstraints = false
        colorView.leadingAnchor.constraint(equalTo: bgView.leadingAnchor).isActive = true
        colorView.topAnchor.constraint(equalTo: bgView.topAnchor).isActive = true
        colorView.bottomAnchor.constraint(equalTo: bgView.bottomAnchor).isActive = true
        if votes == total {
            colorView.trailingAnchor.constraint(equalTo: bgView.trailingAnchor).isActive = true
        } else {
            colorView.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMinXMinYCorner]
            colorView.widthAnchor
                .constraint(equalTo: bgView.widthAnchor, multiplier: CGFloat(Float(votes)/Float(total))).isActive = true
        }
    }
}
