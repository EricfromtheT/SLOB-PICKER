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
        FirebaseManager.shared.fetchUserCurrentGroups() { result in
            switch result {
            case .success(let groupsInfo):
                self.usergroup = groupsInfo
            case .failure(let error):
                print(error, "error of getting current user's group data")
            }
            self.semaphore.signal()
        }
        semaphore.wait()
        for info in usergroup {
            group.enter()
            FirebaseManager.shared.fetchGroupInfo(groupID: info.groupID) {
                result in
                switch result {
                case .success(let group):
                    self.groupInfo.append(group)
                case .failure(let error):
                    print(error, "error of getting single group infos")
                }
                self.group.leave()
            }
        }
        group.notify(queue: .main) {
            self.filteredInfo = self.groupInfo
            ProgressHUD.dismiss()
            self.groupTableView.reloadData()
        }
    }
    
    @objc func createNewGroup() {
        let storyboard = SBStoryboard.relationship.storyboard
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
        let storyboard = SBStoryboard.relationship.storyboard
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
            groupTableView.reloadData()
        }
    }
    
    func search(_ searchTerm: String) {
        if searchTerm.isEmpty {
            self.filteredInfo = self.groupInfo
        } else {
            filteredInfo = groupInfo.filter {
                $0.title.contains(searchTerm.lowercased())
            }
        }
        groupTableView.reloadData()
    }
}
