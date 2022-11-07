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
    
    var friendsID: [String]? {
        didSet {
            // TODO: Use for loop to limit each request up to 10 friend ID
            if let friendsID = friendsID {
                FirebaseManager.shared.fetchFriendsProfile(friendsID: friendsID) { result in
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
            }
        }
    }
    
    var groupName: String?
    var didSelectNum: [Int] = []
    private var friendsProfile: [FriendListObject] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpNavigation()
    }
    
    func setUpNavigation() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "創建社團", style: .done, target: self, action: #selector(createGroup))
    }
    
    @objc func createGroup() {
        if let groupName = groupName {
            let members = friendsProfile.filter { object in
                object.hasSelected == true
            }
            var membersID = members.map { member in
                member.info.userID
            }
            membersID.append(FakeUserInfo.shared.userID)
            var newGroup = Group(title: groupName, members: membersID, pickersIDs: [], createdTime: Date().millisecondsSince1970)
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
