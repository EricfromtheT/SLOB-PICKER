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
    
    var groupData: Group? // 這邊需要抓最新資料
    var groupMemberInfo: [User] = []
    var membersUUID: Set<String> = []
    let group = DispatchGroup()
    let relationshipSB = UIStoryboard(name: "Relationship", bundle: nil)
    
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
            // fetch group info
            FirebaseManager.shared.fetchGroupInfo(groupID: id) {
                result in
                switch result {
                case .success(let group):
                    _membersUUID = group.members
                case.failure(let error):
                    print(error, "error of getting groupData")
                }
                // fetch user info
                for userUUID in _membersUUID {
                    self.group.enter()
                    self.membersUUID.update(with: userUUID)
                    FirebaseManager.shared.getUserInfo(userUUID: userUUID) { result in
                        switch result {
                        case.success(let user):
                            self.groupMemberInfo.append(user)
                        case .failure(let error):
                            print(error, "error of getting user info")
                        }
                        self.group.leave()
                    }
                }
                self.group.notify(queue: .main) {
                    self.currentMemberTableView.reloadData()
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
            // search friend list, filter who is in the group already.
            FirebaseManager.shared.fetchAllFriendsID() { result in
                switch result {
                case .success(let friends):
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
                case .failure(let error):
                    return print(error, "error of fetching all friends info")
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
