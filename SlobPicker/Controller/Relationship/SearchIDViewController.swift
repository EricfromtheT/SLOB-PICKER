//
//  SearchIDViewController.swift
//  SlobPicker
//
//  Created by 孔令傑 on 2022/11/4.
//

import UIKit

class SearchIDViewController: UIViewController {
    @IBOutlet weak var idTextField: UITextField! {
        didSet {
            idTextField.layer.cornerRadius = 5
            idTextField.layer.borderWidth = 2
            idTextField.layer.borderColor = UIColor.asset(.navigationbar2)?.cgColor
            idTextField.delegate = self
        }
    }
    @IBOutlet weak var profileImageView: UIImageView! {
        didSet {
            profileImageView.layer.borderColor = UIColor.black.cgColor
            profileImageView.layer.borderWidth = 1
        }
    }
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var sendInvitationButton: UIButton! {
        didSet {
            sendInvitationButton.isEnabled = false
        }
    }
    @IBOutlet weak var cancelButton: UIButton! {
        didSet {
            cancelButton.layer.cornerRadius = 10
            cancelButton.layer.borderWidth = 2
            cancelButton.layer.borderColor = UIColor.systemGray2.cgColor
        }
    }
    @IBOutlet weak var sendButton: UIButton! {
        didSet {
            sendButton.layer.cornerRadius = 10
            sendButton.layer.borderWidth = 2
            sendButton.layer.borderColor = UIColor.systemGray2.cgColor
        }
    }
    @IBOutlet weak var textStack: UIStackView!
    
    var userInfo: User?
    var isRealUser = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "添加好友"
        setUpLayout()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        profileImageView.layer.cornerRadius = profileImageView.bounds.width / 2
    }
    
    func setUpLayout() {
        textStack.translatesAutoresizingMaskIntoConstraints = false
        idTextField.translatesAutoresizingMaskIntoConstraints = false
        textStack.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        textStack.topAnchor.constraint(equalTo: view.topAnchor, constant: 200).isActive = true
        idTextField.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.5).isActive = true
        idTextField.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.045).isActive = true
        
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.04).isActive = true
        nameLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        nameLabel.topAnchor.constraint(equalTo: textStack.bottomAnchor, constant: 30).isActive = true

        profileImageView.translatesAutoresizingMaskIntoConstraints = false
        profileImageView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.4).isActive = true
        profileImageView.heightAnchor.constraint(equalTo: profileImageView.widthAnchor).isActive = true
        profileImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        profileImageView.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 20).isActive = true

        sendButton.translatesAutoresizingMaskIntoConstraints = false
        sendButton.topAnchor.constraint(equalTo: profileImageView.bottomAnchor, constant: 30).isActive = true
        sendButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
    }
    
    func searchUser() {
        if let content = idTextField.text, !content.isEmpty {
            self.userInfo = nil
            self.isRealUser = false
            // Search firebase
            let userQuery = FirebaseManager.FirebaseCollectionRef.users.ref.whereField("user_id", isEqualTo: content)
            FirebaseManager.shared.getDocuments(userQuery) {
                (userInfo: [User]) in
                if userInfo.isEmpty {
                    self.showNoUserPrompt()
                } else {
                    self.userInfo = userInfo.first
                    self.isRealUser = true
                }
                DispatchQueue.main.async {
                    if let userInfo = self.userInfo {
                        self.sendInvitationButton.isEnabled = true
                        self.nameLabel.text = userInfo.userName
                        self.profileImageView.loadImage(userInfo.profileURL, placeHolder: UIImage.asset(.user))
                    }
                }
                
            }
        }
    }
    
    func showNoUserPrompt() {
        if self.userInfo == nil {
            self.sendInvitationButton.isEnabled = false
            self.nameLabel.text = "無此用戶"
            self.profileImageView.image = UIImage.asset(.user)
            let alert = UIAlertController(title: "無此用戶", message: "查無此ID用戶", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "好", style: .cancel))
            self.present(alert, animated: true)
        }
    }
    
    @IBAction func sendInvitation() {
        if isRealUser {
            if let userInfo = self.userInfo {
                FirebaseManager.shared.addFriend(userUUID: userInfo.userUUID)
                let alert = UIAlertController(title: "添加成功", message: "成功新增一位好友", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "好", style: .cancel))
                self.present(alert, animated: true)
            }
        }
    }
    
    @IBAction func cancel() {
        idTextField.text = ""
    }
}

// MARK: UITextFieldDelegate
extension SearchIDViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        searchUser()
        return true
    }
}
