//
//  FriendSelectViewController.swift
//  SlobPicker
//
//  Created by 孔令傑 on 2022/11/4.
//

import UIKit

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
    
    var friendsUUID: [String]? {
        didSet {
            // TODO: Use for loop to limit each request up to 10 friend ID
            if let friendsUUID = friendsUUID, !friendsUUID.isEmpty {
                FirebaseManager.shared.fetchFriendsProfile(friendsUUID: friendsUUID) { result in
                    switch result {
                    case .success(let users):
                        for user in users {
                            let object = FriendListObject(info: user, hasSelected: false)
                            self.friendsProfile.append(object)
                        }
                    case .failure(let error):
                        print(error, "error of getting friend's profile")
                    }
                    DispatchQueue.main.async {
                        self.friendListTableView.reloadData()
                    }
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
    
    var groupName: String?
    var didSelectNum: [Int] = []
    private var friendsProfile: [FriendListObject] = []
    let uuid = FirebaseManager.auth.currentUser?.uid
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpNavigation()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        view.layoutIfNeeded()
    }
    
    func setUpNavigation() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "創建社團", style: .done, target: self, action: #selector(createGroup))
    }
    
    @objc func createGroup() {
        if let groupName = groupName {
            let members = friendsProfile.filter { object in
                object.hasSelected == true
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
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "\(FriendSelectCell.self)", for: indexPath) as? FriendSelectCell else {
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
        guard let cell = tableView.cellForRow(at: IndexPath(row: indexPath.row, section: 0)) as? FriendSelectCell else {
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
