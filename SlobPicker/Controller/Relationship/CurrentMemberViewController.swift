//
//  CurrentMemberViewController.swift
//  SlobPicker
//
//  Created by 孔令傑 on 2022/12/4.
//

import UIKit

class CurrentMemberViewController: UIViewController {
    @IBOutlet weak var currentMemberTableView: UITableView! {
        didSet {
            currentMemberTableView.dataSource = self
            currentMemberTableView.delegate = self
        }
    }
    
    var groupData: Group?
    var groupMemberInfo: [User] = []
    var membersUUID: Set<String> = []
    let group = DispatchGroup()
    let relationshipSB = UIStoryboard.relationship
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        groupMemberInfo = []
        fetchUserInfo()
    }
    
    func fetchUserInfo() {
        var _membersUUID: [String] = []
        if let groupData = groupData, let id = groupData.id {
            let groupRef = FirebaseManager.FirebaseCollectionRef
                .groups.ref.document(id)
            FirebaseManager.shared.getDocument(groupRef) {
                (group: Group?) in
                if let group = group {
                    _membersUUID = group.members
                    for userUUID in _membersUUID {
                        self.membersUUID.update(with: userUUID)
                        let userRef = FirebaseManager.FirebaseCollectionRef
                            .users.ref.document(userUUID)
                        FirebaseManager.shared.getDocument(userRef) {
                            (user: User?) in
                            if let user = user {
                                self.groupMemberInfo.append(user)
                            }
                            DispatchQueue.main.async {
                                self.currentMemberTableView.reloadData()
                            }
                        }
                    }
                }
            }
        }
    }
}

// MARK: TableView Delegate
extension CurrentMemberViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.row == 0 {
            guard let friendSelectVC = relationshipSB
                .instantiateViewController(withIdentifier: "\(FriendSelectViewController.self)")
                    as? FriendSelectViewController else {
                fatalError("error of instantiating FriendSelectViewController")
            }
            guard let userUUID = FirebaseManager.auth.currentUser?.uid else {
                fatalError("no user uuid")
            }
            let allFriendsQuery = FirebaseManager.FirebaseCollectionRef.usersFriends(userID: userUUID).ref.whereField("is_hidden", isEqualTo: false)
            FirebaseManager.shared.getDocuments(allFriendsQuery) {
                (friends: [Friend]) in
                let friendsUUID = friends.filter {
                    !self.membersUUID.contains($0.userUUID)
                }.map {
                    $0.userUUID
                }
                friendSelectVC.friendsUUID = friendsUUID
                friendSelectVC.mode = .fromManaging
                if let groupData = self.groupData,
                    let id = groupData.id {
                    friendSelectVC.currentGroupID = id
                }
                DispatchQueue.main.async {
                    self.show(friendSelectVC, sender: self)
                }
            }
        }
    }
}

// MARK: TableView DataSource
extension CurrentMemberViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.row == 0 {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "\(InviteNewMemberCell.self)",
                                                           for: indexPath)
                    as? InviteNewMemberCell else {
                fatalError("error of instantiating InviteNewMemberCell")
            }
            return cell
        } else {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "\(GroupMemberCell.self)",
                                                           for: indexPath)
                    as? GroupMemberCell else {
                fatalError("error of instantiating GroupMemberCell")
            }
            cell.configure(user: groupMemberInfo[indexPath.row-1])
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        groupMemberInfo.count + 1
    }
}
