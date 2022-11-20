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
        view.image = UIImage(named: "correct")
        return view
    }()
    
    var isFirstClick = true
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
            button.setTitleColor(.brown, for: .normal)
            button.translatesAutoresizingMaskIntoConstraints = false
            button.tag = unit
            button.addTarget(self, action: #selector(choose), for: .touchUpInside)
            // Constraints
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
    
    // TODO: layout a button on imageview to detect selection
    func layoutWithImageType(optionsURLString: [String]) {
        let stackView = UIStackView()
        self.contentView.addSubview(stackView)
        stackView.axis = .vertical
        stackView.translatesAutoresizingMaskIntoConstraints = false
        for unit in 0..<optionsURLString.count {
            let imageView = UIImageView()
            let button = UIButton()
            imageView.isUserInteractionEnabled = true
            stackView.addArrangedSubview(imageView)
            self.contentView.addSubview(button)
            // Attribute
            imageView.layer.cornerRadius = 20
            imageView.contentMode = .scaleAspectFill
            imageView.clipsToBounds = true
            imageView.translatesAutoresizingMaskIntoConstraints = false
            imageView.loadImage(optionsURLString[unit])
            button.tag = unit
            button.translatesAutoresizingMaskIntoConstraints = false
            button.setTitle("", for: .normal)
            button.addTarget(self, action: #selector(choose), for: .touchUpInside)
            // Constraints
            imageView.widthAnchor.constraint(equalToConstant: SPConstant.screenWidth * 0.3).isActive = true
            imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor).isActive = true
            button.widthAnchor.constraint(equalTo: imageView.widthAnchor).isActive = true
            button.heightAnchor.constraint(equalTo: imageView.heightAnchor).isActive = true
            button.centerXAnchor.constraint(equalTo: imageView.centerXAnchor).isActive = true
            button.centerYAnchor.constraint(equalTo: imageView.centerYAnchor).isActive = true
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
        if !isFirstClick {
            chosenImageView.removeFromSuperview()
        }
        self.contentView.addSubview(chosenImageView)
        chosenImageView.translatesAutoresizingMaskIntoConstraints = false
        chosenImageView.widthAnchor.constraint(equalToConstant: 30).isActive = true
        chosenImageView.heightAnchor.constraint(equalToConstant: 30).isActive = true
        chosenImageView.centerXAnchor.constraint(equalTo: sender.centerXAnchor).isActive = true
        chosenImageView.centerYAnchor.constraint(equalTo: sender.centerYAnchor).isActive = true
        isFirstClick = false
        completion?(sender.tag)
    }
}
