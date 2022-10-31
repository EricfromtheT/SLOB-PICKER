//
//  ChooseCell.swift
//  SlobPicker
//
//  Created by 孔令傑 on 2022/10/31.
//

import UIKit

class ChooseCell: UITableViewCell {
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
    
    func layoutWithImageType(optionsURLString: [String]) {
        let stackView = UIStackView()
        self.contentView.addSubview(stackView)
        stackView.axis = .vertical
        stackView.translatesAutoresizingMaskIntoConstraints = false
        for unit in 0..<optionsURLString.count {
            let imageView = UIImageView()
            stackView.addArrangedSubview(imageView)
            // Attribute
            imageView.contentMode = .scaleAspectFit
            imageView.translatesAutoresizingMaskIntoConstraints = false
            imageView.loadImage(optionsURLString[unit])
            // Constraints
            imageView.widthAnchor.constraint(equalToConstant: SPConstant.screenWidth * 0.7).isActive = true
            imageView.heightAnchor.constraint(equalToConstant: 100).isActive = true
        }
        let spacer = UIView()
        spacer.setContentHuggingPriority(.defaultLow, for: .vertical)
        stackView.addArrangedSubview(spacer)
        stackView.spacing = 50
        stackView.centerXAnchor.constraint(equalTo: self.contentView.centerXAnchor).isActive = true
        stackView.topAnchor.constraint(equalTo: self.contentView.topAnchor, constant: 10).isActive = true
        stackView.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor, constant: 10).isActive = true
    }
}
