//
//  PickResultCell.swift
//  SlobPicker
//
//  Created by 孔令傑 on 2022/11/4.
//

import UIKit

class PickResultCell: UITableViewCell {
    let voteTrailingOffset = CGFloat(-80)
    let contentLeadingOffset = CGFloat(70)
    let topOffset = CGFloat(50)
    let bottomOffset = CGFloat(-50)
    
    func configure(results: [VoteResult], data: Picker) {
        let ordered = results.sorted { first, second in
            first.votes > second.votes
        }
        let leftStack = UIStackView()
        let rightStack = UIStackView()
        leftStack.axis = .vertical
        rightStack.axis = .vertical
        leftStack.spacing = 20
        rightStack.spacing = 20
        leftStack.translatesAutoresizingMaskIntoConstraints = false
        rightStack.translatesAutoresizingMaskIntoConstraints = false
        self.contentView.addSubview(leftStack)
        self.contentView.addSubview(rightStack)
        for index in 0..<data.contents.count {
            let titleLabel = UILabel()
            let votesLabel = UILabel()
            leftStack.addArrangedSubview(titleLabel)
            rightStack.addArrangedSubview(votesLabel)
            for label in [titleLabel, votesLabel] {
                label.translatesAutoresizingMaskIntoConstraints = false
                titleLabel.font = UIFont.systemFont(ofSize: 25)
                votesLabel.font = UIFont.systemFont(ofSize: 25)
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
        // Right Stack
        rightStack.topAnchor.constraint(equalTo: self.contentView.topAnchor, constant: topOffset).isActive = true
        rightStack.trailingAnchor.constraint(equalTo: self.contentView.trailingAnchor, constant: voteTrailingOffset).isActive = true
        rightStack.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor, constant: bottomOffset).isActive = true
    }
    
    func configureLive(results: [VoteResult], data: LivePicker) {
        let ordered = results.sorted { first, second in
            first.votes > second.votes
        }
        let leftStack = UIStackView()
        let rightStack = UIStackView()
        leftStack.axis = .vertical
        rightStack.axis = .vertical
        leftStack.spacing = 20
        rightStack.spacing = 20
        leftStack.translatesAutoresizingMaskIntoConstraints = false
        rightStack.translatesAutoresizingMaskIntoConstraints = false
        self.contentView.addSubview(leftStack)
        self.contentView.addSubview(rightStack)
        for index in 0..<data.contents.count {
            let titleLabel = UILabel()
            let votesLabel = UILabel()
            titleLabel.font = UIFont.systemFont(ofSize: 25)
            votesLabel.font = UIFont.systemFont(ofSize: 25)
            leftStack.addArrangedSubview(titleLabel)
            rightStack.addArrangedSubview(votesLabel)
            for label in [titleLabel, votesLabel] {
                label.translatesAutoresizingMaskIntoConstraints = false
            }
            // Contents
            if !ordered.isEmpty {
                titleLabel.text = data.contents[ordered[index].choice]
                votesLabel.text = String(ordered[index].votes)
            }
        }
        // Left Stack
        //        leftStack.heightAnchor.constraint(equalToConstant: 100).isActive = true
        leftStack.topAnchor.constraint(equalTo: self.contentView.topAnchor, constant: topOffset).isActive = true
        leftStack.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor, constant: contentLeadingOffset).isActive = true
        leftStack.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor, constant: bottomOffset).isActive = true
        // Right Stack
        rightStack.topAnchor.constraint(equalTo: self.contentView.topAnchor, constant: topOffset).isActive = true
        rightStack.trailingAnchor.constraint(equalTo: self.contentView.trailingAnchor, constant: voteTrailingOffset).isActive = true
        rightStack.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor, constant: bottomOffset).isActive = true
    }
    
    func configureImage(results: [VoteResult], data: Picker) {
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
                votesLabel.font = UIFont.systemFont(ofSize: 25)
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
                votesLabel.font = UIFont.systemFont(ofSize: 25)
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
