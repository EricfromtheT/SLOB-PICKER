//
//  HotPickersCell.swift
//  SlobPicker
//
//  Created by 孔令傑 on 2022/11/7.
//

import UIKit

class HotPickerCell: UICollectionViewCell {
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var userIDLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var heartImageView: UIImageView!
    @IBOutlet weak var heartCountLabel: UILabel!
    @IBOutlet weak var pickCountLabel: UILabel!
    @IBOutlet weak var pickImageView: UIImageView!
    @IBOutlet weak var bgView: UIView!
    @IBOutlet weak var bgView2: UIView!
    @IBOutlet weak var optionalButton: UIButton!
    
    var pickerID: String = ""
    var hasLikedC: Bool = false
    var hasPickedC: Bool = false
    var goPickCompletion: (() -> ())?
    var likedCompletion: (() -> ())?
    var dislikedCompletion: (() -> ())?
    var leftColor: [UIColor?] = [UIColor.asset(.card1left), UIColor.asset(.card2left), UIColor.asset(.card3left), UIColor.asset(.card4left)]
    var rightColor: [UIColor?] = [UIColor.asset(.card1right), UIColor.asset(.card2right), UIColor.asset(.card3right), UIColor.asset(.card4right)]
    let gradientLayer = CAGradientLayer()
    var picker: Picker?
    
    func configure(data: Picker, imageURL: String, hasLiked: Bool, hasPicked: Bool, index: Int) {
        // assign
        if let id = data.id {
            pickerID = id
        } else {
            print("id is missing")
        }
        picker = data
        hasLikedC = hasLiked
        hasPickedC = hasPicked
        // content
        profileImageView.loadImage(imageURL, placeHolder: UIImage.asset(.user))
        userIDLabel.text = data.authorID
        titleLabel.text = data.title
        let heartImageName = hasLiked ? "heart" : "empty-heart"
        heartImageView.image = UIImage(named: heartImageName)
        let pickImageName = hasPicked ? "picking" : "empty-picking"
        pickImageView.image = UIImage(named: pickImageName)
        heartCountLabel.text = "\(data.likedCount ?? 0 )"
        pickCountLabel.text = "\(data.pickedCount ?? 0 )"
        // setting
        setUpOptionalButton()
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
        gradientLayer.frame = CGRect(x: 0, y: 0, width: SPConstant.screenWidth*0.55, height: 165)
        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer.endPoint = CGPoint(x: 1, y: 1)
        gradientLayer.colors = [leftColor[index % 4]?.cgColor , rightColor[index % 4]?.cgColor]
        bgView.layer.insertSublayer(gradientLayer, at: 0)
    }
    
    func setUpOptionalButton() {
        optionalButton.setTitle("", for: .normal)
        optionalButton.showsMenuAsPrimaryAction = true
        optionalButton.menu = UIMenu(children: [
            UIAction(title: "檢舉此則投票", handler: { action in
                FirebaseManager.shared.reportPicker(pickerID: self.pickerID) { result in
                    switch result {
                    case .success( _):
                        let alert = UIAlertController(title: "檢舉完成", message: "我們將儘速審核該則投票", preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: "好的", style: .cancel))
                        self.parentContainerViewController()?.present(alert, animated: true)
                    case .failure(let error):
                        print(error, "error of post report")
                    }
                }
            }),
            UIAction(title: "封鎖此作者", handler: { action in
                if let picker = self.picker {
                    FirebaseManager.shared.block(authorID: picker.authorUUID) { result in
                        switch result {
                        case .success( _):
                            let alert = UIAlertController(title: "封鎖完成", message: "您將無法再看到此為作者的投票", preferredStyle: .alert)
                            alert.addAction(UIAlertAction(title: "好的", style: .cancel))
                            self.parentContainerViewController()?.present(alert, animated: true)
                        case .failure(let error):
                            print(error, "error of block someone")
                        }
                    }
                }
            })
        ])
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
