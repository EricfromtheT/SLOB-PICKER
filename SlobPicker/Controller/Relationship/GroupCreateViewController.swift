//
//  GroupCreateViewController.swift
//  SlobPicker
//
//  Created by 孔令傑 on 2022/11/4.
//

import UIKit

class GroupCreateViewController: UIViewController {
    @IBOutlet weak var groupNameTextField: UITextField! {
        didSet {
            groupNameTextField.layer.cornerRadius = 5
            groupNameTextField.layer.borderWidth = 2
            groupNameTextField.layer.borderColor = UIColor.asset(.navigationbar2)?.cgColor
        }
    }
    @IBOutlet weak var chooseButton: UIButton! {
        didSet {
            chooseButton.layer.cornerRadius = 10
            chooseButton.layer.borderWidth = 2
            chooseButton.layer.borderColor = UIColor.systemGray2.cgColor
        }
    }
    
    let group = DispatchGroup()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "創建群組"
    }
    
    @IBAction func selectFriends() {
        if let groupName = groupNameTextField.text, !groupName.isEmpty {
            let storyboard = UIStoryboard.relationship
            guard let friendsVC = storyboard.instantiateViewController(withIdentifier: "\(FriendSelectViewController.self)") as? FriendSelectViewController else {
                print("ERROR: FriendSelectViewController cannot be instantiated")
                return
            }
            // Fetch friends info
            guard let userUUID = FirebaseManager.auth.currentUser?.uid else {
                fatalError("no uuid")
            }
            let userFriendsQuery = FirebaseManager.FirebaseCollectionRef.usersFriends(userID: userUUID).ref.whereField("is_hidden", isEqualTo: false)
            FirebaseManager.shared.getDocuments(userFriendsQuery) {
                (friends: [Friend]) in
                let friendsUUID = friends.map { friend in
                    friend.userUUID
                }
                friendsVC.friendsUUID = friendsUUID
                friendsVC.groupName = groupName
                friendsVC.mode = .fromCreating
                DispatchQueue.main.async {
                    self.show(friendsVC, sender: self)
                }
            }
        }
    }
}
