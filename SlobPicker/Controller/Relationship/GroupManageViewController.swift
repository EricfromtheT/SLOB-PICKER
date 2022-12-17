//
//  GroupManageViewController.swift
//  SlobPicker
//
//  Created by 孔令傑 on 2022/12/2.
//

import UIKit
import ProgressHUD

class GroupManageViewController: UIViewController {
    @IBOutlet weak var groupTableView: UITableView! {
        didSet {
            groupTableView.delegate = self
            groupTableView.dataSource = self
        }
    }
    @IBOutlet weak var searchBar: UISearchBar! {
        didSet {
            self.searchBar.delegate = self
        }
    }
    var usergroup: [GroupInfo] = []
    var groupInfo: [Group] = []
    var filteredInfo: [Group] = []
    let semaphore = DispatchSemaphore(value: 0)
    let group = DispatchGroup()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpNav()
        navigationItem.title = "群組管理"
        navigationItem.backButtonTitle = " "
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        groupInfo = []
        ProgressHUD.animationType = .lineScaling
        ProgressHUD.show()
        DispatchQueue.global().async {
            self.fetchGroupData()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        ProgressHUD.dismiss()
    }
    
    func setUpNav() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "plus"),
                                                            style: .plain,
                                                            target: self,
                                                            action: #selector(createNewGroup))
    }
    
    func fetchGroupData() {
        guard let userUUID = FirebaseManager.auth.currentUser?.uid else {
            fatalError("no uid")
        }
        group.enter()
        let userGroupRed = FirebaseManager.FirebaseCollectionRef.usersGroup(userID: userUUID).ref
        FirebaseManager.shared.getDocuments(userGroupRed) { (groupsInfo: [GroupInfo]) in
            self.usergroup = groupsInfo
            self.group.leave()
        }
        group.wait()
        for info in usergroup {
            group.enter()
            let groupRef = FirebaseManager.FirebaseCollectionRef.groups.ref.document(info.groupID)
            FirebaseManager.shared.getDocument(groupRef) { (group: Group?) in
                if let group = group {
                    self.groupInfo.append(group)
                    self.group.leave()
                }
            }
        }
        group.notify(queue: .main) {
            self.filteredInfo = self.groupInfo
            self.filteredInfo.sort {
                $0.title < $1.title
            }
            ProgressHUD.dismiss()
            self.groupTableView.reloadData()
        }
    }
    
    @objc func createNewGroup() {
        let storyboard = UIStoryboard.relationship
        guard let newGroupVC = storyboard.instantiateViewController(withIdentifier:
                                                                        "\(GroupCreateViewController.self)") as?
                GroupCreateViewController else {
            fatalError("error of instantiating GroupNewViewController")
        }
        show(newGroupVC, sender: self)
    }
}

// MARK: TableView Datasource
extension GroupManageViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "\(GroupManageCell.self)",
                                                       for: indexPath) as? GroupManageCell
        else {
            fatalError("error of dequeuing Group Cell")
        }
        cell.configure(groupTitle: self.filteredInfo[indexPath.row].title)
        return cell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        filteredInfo.count
    }
}

// MARK: TableView Delegate
extension GroupManageViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let storyboard = UIStoryboard.relationship
        guard let groupEditVC = storyboard
            .instantiateViewController(withIdentifier: "\(GroupEditorViewController.self)")
                as? GroupEditorViewController else {
            fatalError("error of instantiating groupEditorViewController")
        }
        
        guard let id = filteredInfo[indexPath.row].id else {
            fatalError("missing group id")
        }
        groupEditVC.groupData = filteredInfo[indexPath.row]
        groupEditVC.groupInfo = GroupInfo(
            groupName: self.filteredInfo[indexPath.row].title,
            groupID: id)
        self.show(groupEditVC, sender: self)
    }
}

// MARK: Search Bar Delegate
extension GroupManageViewController: UISearchBarDelegate {
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        let searchTerm = searchBar.text ?? ""
        search(searchTerm)
        searchBar.resignFirstResponder()
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText.isEmpty {
            filteredInfo = groupInfo
            filteredInfo.sort {
                $0.title < $1.title
            }
            groupTableView.reloadData()
        }
    }
    
    func search(_ searchTerm: String) {
        if searchTerm.isEmpty {
            filteredInfo = groupInfo
        } else {
            filteredInfo = groupInfo.filter {
                $0.title.contains(searchTerm.lowercased())
            }
        }
        filteredInfo.sort {
            $0.title < $1.title
        }
        groupTableView.reloadData()
    }
}
