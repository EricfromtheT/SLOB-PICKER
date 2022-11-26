//
//  PickResultCell.swift
//  SlobPicker
//
//  Created by 孔令傑 on 2022/11/4.
//

import UIKit
 
class PickResultCell: UITableViewCell {
    @IBOutlet weak var bgView: UIView!
    @IBOutlet weak var bgBlueView: UIView!
    
    let voteTrailingOffset = CGFloat(-90)
    let contentLeadingOffset = CGFloat(70)
    let topOffset = CGFloat(30)
    let bottomOffset = CGFloat(-50)
    let fontSize = CGFloat(17)
    
    func configure(results: [VoteResult], data: Picker) {
        bgView.layer.cornerRadius = 20
        bgBlueView.clipsToBounds = true
        bgBlueView.layer.cornerRadius = 20
        bgBlueView.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
        let ordered = results.sorted { first, second in
            first.votes > second.votes
        }
        let leftStack = UIStackView()
        leftStack.axis = .vertical
        leftStack.spacing = 20
        leftStack.translatesAutoresizingMaskIntoConstraints = false
        self.contentView.addSubview(leftStack)
        for index in 0..<data.contents.count {
            let titleLabel = UILabel()
            let votesLabel = UILabel()
            leftStack.addArrangedSubview(titleLabel)
            self.contentView.addSubview(votesLabel)
            for label in [titleLabel, votesLabel] {
                label.translatesAutoresizingMaskIntoConstraints = false
                label.font = UIFont.systemFont(ofSize: fontSize)
                label.numberOfLines = 0
                votesLabel.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor).isActive = true
                votesLabel.trailingAnchor.constraint(equalTo: self.contentView.trailingAnchor, constant: voteTrailingOffset).isActive = true
            }
            // Contents
            if !ordered.isEmpty {
                titleLabel.text = data.contents[ordered[index].choice]
                votesLabel.text = String(ordered[index].votes)
            }
        }
        // Left Stack
        leftStack.topAnchor.constraint(equalTo: self.contentView.topAnchor, constant: topOffset).isActive = true
        leftStack.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor, constant: contentLeadingOffset).isActive = true
        leftStack.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor, constant: bottomOffset).isActive = true
        leftStack.widthAnchor.constraint(equalToConstant: SPConstant.screenWidth * 0.5).isActive = true
    }
    
    func configureLive(results: [VoteResult], data: LivePicker) {
        bgView.layer.cornerRadius = 20
        bgBlueView.clipsToBounds = true
        bgBlueView.layer.cornerRadius = 20
        bgBlueView.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
        let ordered = results.sorted { first, second in
            first.votes > second.votes
        }
        let leftStack = UIStackView()
        leftStack.axis = .vertical
        leftStack.spacing = 20
        leftStack.translatesAutoresizingMaskIntoConstraints = false
        self.contentView.addSubview(leftStack)
        for index in 0..<data.contents.count {
            let titleLabel = UILabel()
            let votesLabel = UILabel()
            leftStack.addArrangedSubview(titleLabel)
            self.contentView.addSubview(votesLabel)
            for label in [titleLabel, votesLabel] {
                label.translatesAutoresizingMaskIntoConstraints = false
                label.font = UIFont.systemFont(ofSize: fontSize)
                label.numberOfLines = 0
                votesLabel.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor).isActive = true
                votesLabel.trailingAnchor.constraint(equalTo: self.contentView.trailingAnchor, constant: voteTrailingOffset).isActive = true
            }
            // Contents
            if !ordered.isEmpty {
                titleLabel.text = data.contents[ordered[index].choice]
                votesLabel.text = String(ordered[index].votes)
            }
        }
        // Left Stack
        leftStack.topAnchor.constraint(equalTo: self.contentView.topAnchor, constant: topOffset).isActive = true
        leftStack.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor, constant: contentLeadingOffset).isActive = true
        leftStack.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor, constant: bottomOffset).isActive = true
        leftStack.widthAnchor.constraint(equalToConstant: SPConstant.screenWidth * 0.5).isActive = true
    }
    
    func configureImage(results: [VoteResult], data: Picker) {
        bgView.layer.cornerRadius = 20
        bgBlueView.clipsToBounds = true
        bgBlueView.layer.cornerRadius = 20
        bgBlueView.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
        let ordered = results.sorted { first, second in
            first.votes > second.votes
        }
        let leftStack = UIStackView()
        leftStack.axis = .vertical
        leftStack.spacing = 20
        leftStack.translatesAutoresizingMaskIntoConstraints = false
        self.contentView.addSubview(leftStack)
        for index in 0..<data.contents.count {
            let imageView = UIImageView()
            let votesLabel = UILabel()
            leftStack.addArrangedSubview(imageView)
            self.contentView.addSubview(votesLabel)
            for view in [imageView, votesLabel] {
                view.translatesAutoresizingMaskIntoConstraints = false
                imageView.widthAnchor.constraint(equalToConstant: 80).isActive = true
                imageView.heightAnchor.constraint(equalToConstant: 80).isActive = true
                imageView.layer.cornerRadius = 20
                imageView.contentMode = .scaleAspectFill
                imageView.clipsToBounds = true
                votesLabel.font = UIFont.systemFont(ofSize: fontSize)
                votesLabel.centerYAnchor.constraint(equalTo: imageView.centerYAnchor).isActive = true
                votesLabel.trailingAnchor
                    .constraint(equalTo: self.contentView.trailingAnchor, constant: voteTrailingOffset).isActive = true
            }
            // Contents
            if !ordered.isEmpty {
                imageView.loadImage(data.contents[ordered[index].choice])
                votesLabel.text = String(ordered[index].votes)
            }
        }
        // Left Stack
        leftStack.topAnchor.constraint(equalTo: self.contentView.topAnchor, constant: topOffset).isActive = true
        leftStack.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor, constant: contentLeadingOffset).isActive = true
        leftStack.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor, constant: bottomOffset).isActive = true
    }
    
    func configureLiveImage(results: [VoteResult], data: LivePicker) {
        bgView.layer.cornerRadius = 20
        bgBlueView.clipsToBounds = true
        bgBlueView.layer.cornerRadius = 20
        bgBlueView.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
        let ordered = results.sorted { first, second in
            first.votes > second.votes
        }
        let leftStack = UIStackView()
        leftStack.axis = .vertical
        leftStack.spacing = 20
        leftStack.translatesAutoresizingMaskIntoConstraints = false
        self.contentView.addSubview(leftStack)
        for index in 0..<data.contents.count {
            let imageView = UIImageView()
            let votesLabel = UILabel()
            leftStack.addArrangedSubview(imageView)
            self.contentView.addSubview(votesLabel)
            for view in [imageView, votesLabel] {
                view.translatesAutoresizingMaskIntoConstraints = false
                imageView.widthAnchor.constraint(equalToConstant: 60).isActive = true
                imageView.heightAnchor.constraint(equalToConstant: 60).isActive = true
                imageView.layer.cornerRadius = 20
                imageView.contentMode = .scaleAspectFill
                imageView.clipsToBounds = true
                votesLabel.font = UIFont.systemFont(ofSize: fontSize)
                votesLabel.centerYAnchor.constraint(equalTo: imageView.centerYAnchor).isActive = true
                votesLabel.trailingAnchor
                    .constraint(equalTo: self.contentView.trailingAnchor, constant: voteTrailingOffset).isActive = true
            }
            // Contents
            if !ordered.isEmpty {
                imageView.loadImage(data.contents[ordered[index].choice])
                votesLabel.text = String(ordered[index].votes)
            }
        }
        // Left Stack
        leftStack.topAnchor.constraint(equalTo: self.contentView.topAnchor, constant: topOffset).isActive = true
        leftStack.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor, constant: contentLeadingOffset).isActive = true
        leftStack.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor, constant: bottomOffset).isActive = true
    }
}
