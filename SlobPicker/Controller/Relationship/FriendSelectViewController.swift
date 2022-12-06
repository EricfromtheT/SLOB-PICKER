//
//  FriendSelectViewController.swift
//  SlobPicker
//
//  Created by 孔令傑 on 2022/11/4.
//

import UIKit
import ProgressHUD

struct FriendListObject {
    var info: User
    var hasSelected: Bool
}

class FriendSelectViewController: UIViewController {
    @IBOutlet weak var friendListTableView: UITableView! {
        didSet {
            friendListTableView.dataSource = self
            friendListTableView.delegate = self
        }
    }
    let group = DispatchGroup()
    
    // pre-provided data
    var friendsUUID: [String]? {
        didSet {
            // TODO: Use for loop to limit each request up to 10 friend ID
            if let friendsUUID = friendsUUID, !friendsUUID.isEmpty {
                for uuid in friendsUUID {
                    group.enter()
                    FirebaseManager.shared.getUserInfo(userUUID: uuid) { result in
                        switch result {
                        case .success(let user):
                            let object = FriendListObject(info: user, hasSelected: false)
                            self.friendsProfile.append(object)
                        case .failure(let error):
                            print(error, "error of getting friend's profile")
                        }
                        self.group.leave()
                    }
                }
                group.notify(queue: .main) {
                    self.friendListTableView.reloadData()
                }
            } else {
                let label = UILabel()
                label.text = "你沒有任何好友"
                label.font = UIFont.systemFont(ofSize: 25)
                view.addSubview(label)
                label.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
                label.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
                navigationItem.rightBarButtonItem?.isEnabled = false
                friendListTableView.isHidden = true
            }
        }
    }
    
    var currentGroupID: String?
    var groupName: String?
    var completion: (([String]) -> Void)?
    private var didSelectNum: [Int] = []
    private var friendsProfile: [FriendListObject] = []
    let uuid = FirebaseManager.auth.currentUser?.uid
    
    // MARK: Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpNavigation()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        view.layoutIfNeeded()
    }
    
    func setUpNavigation() {
        if let vcCounts = navigationController?.viewControllers.count,
           let navController = self.navigationController {
            if navController.viewControllers[vcCounts-2] is GroupCreateViewController {
                navigationItem.rightBarButtonItem = UIBarButtonItem(title: "創建社團",
                                                                    style: .done,
                                                                    target: self,
                                                                    action: #selector(createGroup))
            } else {
                navigationItem.rightBarButtonItem = UIBarButtonItem(title: "添加",
                                                                    style: .done,
                                                                    target: self,
                                                                    action: #selector(invite))
            }
        }
    }
    
    @objc func invite() {
        let invitedPeople = friendsProfile.filter { person in
            person.hasSelected == true
        }
        let uuids = invitedPeople.map { member in
            member.info.userUUID
        }
        guard let id = currentGroupID else { return print("no group id to invite new member") }
        ProgressHUD.show()
        group.enter()
        FirebaseManager.shared.addGroupPeople(groupID: id,
                                              newMembersUUID: uuids,
                                              completion: {
            result in
            switch result {
            case .success( _):
                break
            case .failure(let error):
                return print(error, "error of adding group people")
            }
            self.group.leave()
        })
        for uuid in uuids {
            group.enter()
            FirebaseManager.shared.addUserGroupInfo(userUUID: uuid, groupID: id, groupName: "") {
                self.group.leave()
            }
        }
        group.notify(queue: .main) {
            ProgressHUD.dismiss()
            self.navigationController?.popViewController(animated: true)
        }
    }
    
    @objc func createGroup() {
        if let groupName = groupName {
            let members = friendsProfile.filter { person in
                person.hasSelected == true
            }
            var membersUUID = members.map { member in
                member.info.userUUID
            }
            guard let uuid = uuid else { fatalError("uuid in keychain is nil") }
            // add yourself to group
            membersUUID.append(uuid)
            var newGroup = Group(title: groupName, members: membersUUID, pickersIDs: [], createdTime: Date().millisecondsSince1970)
            FirebaseManager.shared.publishNewGroup(group: &newGroup) { result in
                switch result {
                case .success(let success):
                    print(success)
                case .failure(let error):
                    print(error, "Publish new group fail")
                }
                DispatchQueue.main.async {
                    self.navigationController?.popToRootViewController(animated: true)
                }
            }
        }
    }
}

// MARK: TableView datasource
extension FriendSelectViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "\(FriendSelectCell.self)",
                                                       for: indexPath) as? FriendSelectCell else {
            fatalError("ERROR: FriendSelectCell cannot be instantiated")
        }
        cell.configure(data: friendsProfile[indexPath.row])
        cell.chosenMarkImageView.isHidden = !friendsProfile[indexPath.row].hasSelected
        return cell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        friendsProfile.count
    }
}

// MARK: TableView Delegate
extension FriendSelectViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let cell = tableView.cellForRow(at: IndexPath(row: indexPath.row,
                                                            section: 0)) as? FriendSelectCell else {
            fatalError("ERROR: FriendSelectCell cannot be instantiated")
        }
        if friendsProfile[indexPath.row].hasSelected {
            friendsProfile[indexPath.row].hasSelected = false
            cell.chosenMarkImageView.isHidden = true
        } else {
            friendsProfile[indexPath.row].hasSelected = true
            cell.chosenMarkImageView.isHidden = false
        }
    }
}
