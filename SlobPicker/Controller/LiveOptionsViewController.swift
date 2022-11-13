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
            if let livePicker = livePicker {
                layoutWithTextType(optionsString: livePicker.contents)
            }
        }
    }
    @IBOutlet weak var bgView: UIView!
    var livePicker: LivePicker?
    var isFirstClick = true
    var chosenImageView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFit
        view.image = UIImage(named: "correct")
        return view
    }()
    var chosenIndex: Int?
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    func layoutWithTextType(optionsString: [String]) {
        let stackView = UIStackView()
        self.optionsView.addSubview(stackView)
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
            button.widthAnchor.constraint(equalToConstant: SPConstant.screenWidth * 0.3).isActive = true
            button.heightAnchor.constraint(equalToConstant: 60).isActive = true
        }
        let spacer = UIView()
        spacer.setContentHuggingPriority(.defaultLow, for: .vertical)
        stackView.addArrangedSubview(spacer)
        stackView.spacing = 30
        stackView.centerXAnchor.constraint(equalTo: optionsView.centerXAnchor).isActive = true
        stackView.topAnchor.constraint(equalTo: optionsView.topAnchor, constant: 10).isActive = true
        stackView.bottomAnchor.constraint(equalTo: optionsView.bottomAnchor, constant: 10).isActive = true
    }
    
    @objc func choose(_ sender: UIButton) {
        if !isFirstClick {
            chosenImageView.removeFromSuperview()
        }
        self.view.addSubview(chosenImageView)
        chosenImageView.translatesAutoresizingMaskIntoConstraints = false
        chosenImageView.widthAnchor.constraint(equalToConstant: 30).isActive = true
        chosenImageView.heightAnchor.constraint(equalToConstant: 30).isActive = true
        chosenImageView.centerXAnchor.constraint(equalTo: sender.centerXAnchor).isActive = true
        chosenImageView.centerYAnchor.constraint(equalTo: sender.centerYAnchor).isActive = true
        isFirstClick = false
        chosenIndex = sender.tag
    }
    
    @IBAction func vote() {
        if let livePicker = livePicker, let chosenIndex = chosenIndex {
            FirebaseManager.shared.voteForLivePicker(pickerID: livePicker.pickerID, choice: chosenIndex)
        }
        dismiss(animated: true)
    }
}
