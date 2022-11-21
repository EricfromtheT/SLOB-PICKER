//
//  HotPickersCell.swift
//  SlobPicker
//
//  Created by 孔令傑 on 2022/11/7.
//

import UIKit

class HotPickerCell: UICollectionViewCell {
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var userNameLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var heartImageView: UIImageView!
    @IBOutlet weak var heartCountLabel: UILabel!
    @IBOutlet weak var pickCountLabel: UILabel!
    @IBOutlet weak var pickImageView: UIImageView!
    @IBOutlet weak var bgView: UIView!
    @IBOutlet weak var bgView2: UIView!
    
    var pickerID: String = ""
    var hasLikedC: Bool = false
    var hasPickedC: Bool = false
    var goPickCompletion: (() -> ())?
    var likedCompletion: (() -> ())?
    var dislikedCompletion: (() -> ())?
    var leftColor: [UIColor?] = [UIColor.asset(.card1left), UIColor.asset(.card2left), UIColor.asset(.card3left), UIColor.asset(.card4left)]
    var rightColor: [UIColor?] = [UIColor.asset(.card1right), UIColor.asset(.card2right), UIColor.asset(.card3right), UIColor.asset(.card4right)]
    let gradientLayer = CAGradientLayer()
    
    func configure(data: Picker, imageURL: String, hasLiked: Bool, hasPicked: Bool, index: Int) {
        // assign
        if let id = data.id {
            pickerID = id
        } else {
            print("id is missing")
        }
        hasLikedC = hasLiked
        hasPickedC = hasPicked
        // content
        profileImageView.loadImage(imageURL)
        userNameLabel.text = data.authorName
        titleLabel.text = data.title
        let heartImageName = hasLiked ? "heart" : "empty-heart"
        heartImageView.image = UIImage(named: heartImageName)
        let pickImageName = hasPicked ? "picking" : "empty-picking"
        pickImageView.image = UIImage(named: pickImageName)
        heartCountLabel.text = "\(data.likedCount ?? 0 )"
        pickCountLabel.text = "\(data.pickedCount ?? 0 )"
        // setting
        let heartGesture = UITapGestureRecognizer(target: self, action: #selector(clickLike))
        heartImageView.addGestureRecognizer(heartGesture)
        heartImageView.isUserInteractionEnabled = true
        let pickGesture = UITapGestureRecognizer(target: self, action: #selector(goPick))
        pickImageView.addGestureRecognizer(pickGesture)
        pickImageView.isUserInteractionEnabled = !hasPicked
        // appearance
        profileImageView.layer.cornerRadius = profileImageView.bounds.width / 2
        bgView.layer.cornerRadius = 25
        bgView2.layer.cornerRadius = 22
        gradientLayer.cornerRadius = 25
        gradientLayer.frame = CGRect(x: 0, y: 0, width: SPConstant.screenWidth*0.55, height: 160)
        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer.endPoint = CGPoint(x: 1, y: 1)
        gradientLayer.colors = [leftColor[index % 4]?.cgColor , rightColor[index % 4]?.cgColor]
        bgView.layer.insertSublayer(gradientLayer, at: 0)
    }
    
    func picked() {
        if let texts = pickCountLabel.text, var num = Int(texts) {
            num += 1
            pickCountLabel.text = "\(num)"
        }
        pickImageView.image = UIImage(named: "picking")
    }
    
    @objc func clickLike() {
        if let texts = heartCountLabel.text, var num = Int(texts) {
            if hasLikedC {
                num -= 1
                heartCountLabel.text = "\(num)"
                heartImageView.image = UIImage(named: "empty-heart")
                FirebaseManager.shared.dislikePicker(pickerID: pickerID)
                hasLikedC = false
                dislikedCompletion?()
            } else {
                num += 1
                heartCountLabel.text = "\(num)"
                heartImageView.image = UIImage(named: "heart")
                FirebaseManager.shared.likePicker(pickerID: pickerID)
                hasLikedC = true
                likedCompletion?()
            }
        }
    }
    
    @objc func goPick() {
        if !hasPickedC {
            goPickCompletion?()
        }
    }
}
