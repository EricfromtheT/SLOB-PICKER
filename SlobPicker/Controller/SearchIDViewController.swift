//
//  SearchIDViewController.swift
//  SlobPicker
//
//  Created by 孔令傑 on 2022/11/4.
//

import UIKit

class SearchIDViewController: UIViewController {
    @IBOutlet weak var idTextField: UITextField!
    @IBOutlet weak var profileImageView: UIImageView! {
        didSet {
            profileImageView.layer.cornerRadius
            = profileImageView.bounds.width / 2
        }
    }
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var sendInvitationButton: UIButton! {
        didSet {
            sendInvitationButton.isEnabled = false
        }
    }
    
    var userInfo: User?
    var isRealUser = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func searchUser() {
        if let content = idTextField.text, !content.isEmpty {
            self.userInfo = nil
            self.isRealUser = false
            // Search firebase
            FirebaseManager.shared.searchUserID(userID: content) { result in
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
                        self.profileImageView.loadImage(userInfo.profileURL)
                    }
                }
            }
        }
    }
    
    func showNoUserPrompt() {
        if self.userInfo == nil {
            self.sendInvitationButton.isEnabled = false
            self.nameLabel.text = "No user"
            self.profileImageView.image = UIImage(named: "image")
            let alert = UIAlertController(title: "No User", message: "no user with this ID", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .cancel))
            self.present(alert, animated: true)
        }
    }
    
    @IBAction func sendInvitation() {
        // TODO: 邀請需要改為對方須接受邀約
        if isRealUser {
            if let userInfo = self.userInfo {
                FirebaseManager.shared.addFriend(userID: userInfo.userID)
                let alert = UIAlertController(title: "Succeeded", message: "you have got a new friend", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .cancel))
                self.present(alert, animated: true)
            }
        }
    }
}
