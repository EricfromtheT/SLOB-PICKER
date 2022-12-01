//
//  ChooseCell.swift
//  SlobPicker
//
//  Created by 孔令傑 on 2022/10/31.
//

import UIKit

class ChooseCell: UITableViewCell {
    var chosenImageView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFit
        view.image = UIImage(named: "picking")
        return view
    }()
    var lastClickButton: UIButton?
    var completion: ((Int) -> ())?
    
    // MARK: Method
    func layoutWithTextType(optionsString: [String]) {
        let stackView = UIStackView()
        self.contentView.addSubview(stackView)
        stackView.axis = .vertical
        stackView.translatesAutoresizingMaskIntoConstraints = false
        for unit in 0..<optionsString.count {
            let button = UIButton()
            stackView.addArrangedSubview(button)
            // Attribute
            button.setTitle(optionsString[unit], for: .normal)
            button.backgroundColor = UIColor.asset(.choose)
            button.layer.cornerRadius = 25
            button.titleLabel?.font = UIFont.systemFont(ofSize: 18)
            button.setTitleColor(.black, for: .normal)
            button.translatesAutoresizingMaskIntoConstraints = false
            button.tag = unit
            button.addTarget(self, action: #selector(choose), for: .touchUpInside)
            // Constraints
            button.widthAnchor.constraint(equalToConstant: SPConstant.screenWidth * 0.7).isActive = true
            button.heightAnchor.constraint(equalToConstant: 70).isActive = true
        }
        let spacer = UIView()
        spacer.setContentHuggingPriority(.defaultLow, for: .vertical)
        stackView.addArrangedSubview(spacer)
        stackView.spacing = 50
        stackView.centerXAnchor.constraint(equalTo: self.contentView.centerXAnchor).isActive = true
        stackView.topAnchor.constraint(equalTo: self.contentView.topAnchor, constant: 10).isActive = true
        stackView.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor, constant: 10).isActive = true
    }
    
    // TODO: layout a button on imageview to detect selection
    func layoutWithImageType(optionsURLString: [String]) {
        let stackView = UIStackView()
        self.contentView.addSubview(stackView)
        stackView.axis = .vertical
        stackView.translatesAutoresizingMaskIntoConstraints = false
        for unit in 0..<optionsURLString.count {
            let imageView = UIImageView()
            let button = UIButton()
            stackView.addArrangedSubview(button)
//            self.contentView.addSubview(imageView)
            button.addSubview(imageView)
            // Attribute
            imageView.layer.cornerRadius = 20
            imageView.contentMode = .scaleAspectFill
            imageView.clipsToBounds = true
            imageView.translatesAutoresizingMaskIntoConstraints = false
            imageView.loadImage(optionsURLString[unit], placeHolder: UIImage.asset(.image))
            button.tag = unit
            button.translatesAutoresizingMaskIntoConstraints = false
            button.setTitle("", for: .normal)
            button.backgroundColor = UIColor.asset(.choose)
            button.layer.cornerRadius = 25
            button.addTarget(self, action: #selector(choose), for: .touchUpInside)
            // Constraints
            imageView.widthAnchor.constraint(equalToConstant: 80).isActive = true
            imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor).isActive = true
            imageView.centerXAnchor.constraint(equalTo: button.centerXAnchor).isActive = true
            imageView.centerYAnchor.constraint(equalTo: button.centerYAnchor).isActive = true
            button.widthAnchor.constraint(equalToConstant: SPConstant.screenWidth * 0.7).isActive = true
            button.heightAnchor.constraint(equalToConstant: 100).isActive = true
        }
        let spacer = UIView()
        spacer.setContentHuggingPriority(.defaultLow, for: .vertical)
        stackView.addArrangedSubview(spacer)
        stackView.spacing = 50
        stackView.centerXAnchor.constraint(equalTo: self.contentView.centerXAnchor).isActive = true
        stackView.topAnchor.constraint(equalTo: self.contentView.topAnchor, constant: 10).isActive = true
        stackView.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor, constant: 10).isActive = true
    }
    
    @objc func choose(_ sender: UIButton) {
        if let lastButton = lastClickButton {
            lastButton.layer.borderWidth = 0
        }
        sender.layer.borderColor = UIColor.asset(.navigationbar2)?.cgColor
        sender.layer.borderWidth = 2
        lastClickButton = sender
        bouncing(object: sender, distance: 20)
        completion?(sender.tag)
    }
    
    func bouncing(object: UIButton, distance: CGFloat) {
        var boucing = distance
        if boucing < 0 {
            return
        }
        UIView.animate(withDuration: 0.15) {
            // right
            object.transform = CGAffineTransform(translationX: distance, y: 0)
        } completion: { _ in
            // left
            boucing -= 8
            UIView.animate(withDuration: 0.15) {
                object.transform = CGAffineTransform(translationX: 0, y: 0)
            } completion: { _ in
                self.bouncing(object: object, distance: boucing)
            }
            
        }
    }
}
