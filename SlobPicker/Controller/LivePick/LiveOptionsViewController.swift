//
//  LiveOptionsViewController.swift
//  SlobPicker
//
//  Created by 孔令傑 on 2022/11/13.
//

import UIKit

class LiveOptionsViewController: UIViewController {
    @IBOutlet weak var optionsView: UIView! {
        didSet {
            optionsView.layer.cornerRadius = 15
            optionsView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
            if let livePicker = livePicker {
                if livePicker.type == 0 {
                    layoutWithTextType(optionsString: livePicker.contents)
                } else {
                    layoutWithImageType(optionsURL: livePicker.contents)
                }
            }
        }
    }
    @IBOutlet weak var voteButton: UIButton! {
        didSet {
            voteButton.layer.cornerRadius=15
        }
    }
    var livePicker: LivePicker?
    var lastClickButton: UIButton?
    var chosenIndex: Int?
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    func layoutWithTextType(optionsString: [String]) {
        let stackView = UIStackView()
        self.optionsView.addSubview(stackView)
        stackView.axis = .vertical
        stackView.backgroundColor = .clear
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
            button.heightAnchor.constraint(equalToConstant:
                                            (optionsView.frame.height - 250) / 5).isActive = true
        }
        let spacer = UIView()
        spacer.setContentHuggingPriority(.defaultLow, for: .vertical)
        stackView.addArrangedSubview(spacer)
        stackView.spacing = 25
        stackView.centerXAnchor.constraint(equalTo: self.optionsView.centerXAnchor).isActive = true
        stackView.topAnchor.constraint(equalTo: self.optionsView.topAnchor, constant: 60).isActive = true
        stackView.bottomAnchor.constraint(equalTo: self.optionsView.bottomAnchor, constant: 10).isActive = true
    }
    
    func layoutWithImageType(optionsURL: [String]) {
        let stackView = UIStackView()
        self.optionsView.addSubview(stackView)
        stackView.axis = .vertical
        stackView.translatesAutoresizingMaskIntoConstraints = false
        for unit in 0..<optionsURL.count {
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
            imageView.loadImage(optionsURL[unit], placeHolder: UIImage.asset(.image))
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
            button.heightAnchor.constraint(equalToConstant: (optionsView.frame.height - 250) / 4).isActive = true
        }
        let spacer = UIView()
        spacer.setContentHuggingPriority(.defaultLow, for: .vertical)
        stackView.addArrangedSubview(spacer)
        stackView.spacing = 50
        stackView.centerXAnchor.constraint(equalTo: self.optionsView.centerXAnchor).isActive = true
        stackView.topAnchor.constraint(equalTo: self.optionsView.topAnchor, constant: 50).isActive = true
        stackView.bottomAnchor.constraint(equalTo: self.optionsView.bottomAnchor, constant: 10).isActive = true
    }
    
    @objc func choose(_ sender: UIButton) {
        if let lastButton = lastClickButton {
            lastButton.layer.borderWidth = 0
        }
        sender.layer.borderColor = UIColor.asset(.navigationbar2)?.cgColor
        sender.layer.borderWidth = 2
        lastClickButton = sender
        bouncing(object: sender, distance: 20)
        chosenIndex = sender.tag
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
    
    @IBAction func vote() {
        if let livePicker = livePicker, let chosenIndex = chosenIndex, let pickerID = livePicker.pickerID {
            FirebaseManager.shared.voteForLivePicker(pickerID: pickerID, choice: chosenIndex)
        }
        dismiss(animated: true)
    }
}
