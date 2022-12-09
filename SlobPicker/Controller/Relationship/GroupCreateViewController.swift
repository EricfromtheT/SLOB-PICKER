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
            let storyboard = UIStoryboard(name: "Relationship", bundle: nil)
            guard let friendsVC = storyboard.instantiateViewController(withIdentifier: "\(FriendSelectViewController.self)") as? FriendSelectViewController else {
                print("ERROR: FriendSelectViewController cannot be instantiated")
                return
            }
            friendsVC.groupName = groupName
            // Fetch friends info
            group.enter()
            FirebaseManager.shared.fetchAllFriendsID { result in
                switch result {
                case .success(let friends):
                    let friendsUUID = friends.map { friend in
                        friend.userUUID
                    }
                    friendsVC.friendsUUID = friendsUUID
                    friendsVC.mode = .fromCreating
                case .failure(let error):
                    print(error, "ERROR of getting your friends' info")
                }
                self.group.leave()
            }
            group.notify(queue: DispatchQueue.main) {
                self.show(friendsVC, sender: self)
            }
        }
    }
}
