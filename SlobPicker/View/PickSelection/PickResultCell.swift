//
//  PickResultCell.swift
//  SlobPicker
//
//  Created by 孔令傑 on 2022/11/4.
//

import UIKit

class PickResultCell: UITableViewCell {
    func configure(results: [VoteResult], data: Picker) {
        let ordered = results.sorted { first, second in
            first.votes > second.votes
        }
        print(ordered, "ordered data")
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
            }
            // Contents
            if !ordered.isEmpty {
                titleLabel.text = data.contents[ordered[index].choice]
                votesLabel.text = String(ordered[index].votes)
            }
        }
        // Left Stack
//        leftStack.heightAnchor.constraint(equalToConstant: 100).isActive = true
        leftStack.topAnchor.constraint(equalTo: self.contentView.topAnchor, constant: 30).isActive = true
        leftStack.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor, constant: 50).isActive = true
        leftStack.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor, constant: -30).isActive = true
        // Right Stack
        rightStack.topAnchor.constraint(equalTo: self.contentView.topAnchor, constant: 30).isActive = true
        rightStack.trailingAnchor.constraint(equalTo: self.contentView.trailingAnchor, constant: -50).isActive = true
        rightStack.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor, constant: -30).isActive = true
    }
}
