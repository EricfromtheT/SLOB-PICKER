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
        }
    }
    @IBOutlet weak var profileImageView: UIImageView! {
        didSet {
            profileImageView.layer.cornerRadius
            = profileImageView.bounds.width / 2
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
    @IBOutlet weak var searchButton: UIButton! {
        didSet {
            searchButton.layer.cornerRadius = 10
            searchButton.layer.borderWidth = 2
            searchButton.layer.borderColor = UIColor.systemGray2.cgColor
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
    
    var userInfo: User?
    var isRealUser = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "添加好友"
    }
    
    @IBAction func searchUser() {
        if let content = idTextField.text, !content.isEmpty {
            self.userInfo = nil
            self.isRealUser = false
            // Search firebase
            FirebaseManager.shared.searchUser(userID: content) { result in
                switch result {
                case .success(let userInfo):
                    self.userInfo = userInfo
                    self.isRealUser = true
                case .failure(let error):
                    if error as? UserError == .nodata {
                        self.showNoUserPrompt()
                    } else {
                        print(error, "ERROR of fetching single user info")
                    }
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
        // TODO: 邀請需要改為對方須接受邀約
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