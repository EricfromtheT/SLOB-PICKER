//
//  GroupEditorViewController.swift
//  SlobPicker
//
//  Created by 孔令傑 on 2022/12/2.
//

import UIKit

class GroupEditorViewController: UIViewController {
    @IBOutlet weak var editorTableView: UITableView! {
        didSet {
            editorTableView.dataSource = self
            editorTableView.delegate = self
        }
    }
    
    var groupInfo: GroupInfo?
    var groupData: Group?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.backButtonTitle = " "
        navigationItem.title = "編輯群組"
    }
}

extension GroupEditorViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let storyboard = UIStoryboard.relationship
        if let cell = tableView.cellForRow(at: indexPath) {
            if let nameCell = cell as? GroupNameCell {
                guard let groupNameVC = storyboard.instantiateViewController(withIdentifier: "\(NameEditViewController.self)") as?
                        NameEditViewController else {
                    fatalError("error of instantiating GroupNameEditViewController")
                }
                if let groupInfo = groupInfo {
                    groupNameVC.originalName = groupInfo.groupName
                    groupNameVC.groupID = groupInfo.groupID
                }
                groupNameVC.completion = { name in
                    nameCell.nameLabel.text = name
                }
                self.show(groupNameVC, sender: self)
                
            } else if let _ = cell as? MemberManageCell {
                guard let memberVC = storyboard.instantiateViewController(withIdentifier: "\(CurrentMemberViewController.self)")
                        as? CurrentMemberViewController else {
                    fatalError("error of instantiating CurrentMemberViewController")
                }
                memberVC.groupData = self.groupData
                self.show(memberVC, sender: self)
                
            } else if let _ = cell as? LeaveGroupCell {
                let alert = UIAlertController(title: "是否確定離開?", message: "離開群組後將無法自行重新加入。", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "取消",
                                              style: .cancel))
                alert.addAction(UIAlertAction(title: "確定離開",
                                              style: .destructive) { action in
                    guard let groupInfo = self.groupInfo,
                            let uuid = FirebaseManager.auth.currentUser?.uid
                    else { fatalError("uuid is nil") }
                    FirebaseManager.shared.leaveGroup(groupID: groupInfo.groupID) {
                        result in
                        switch result {
                        case .success( _):
                            break
                        case .failure(let error):
                            print(error, "error of leave group")
                        }
                        FirebaseManager.shared.groupDeleteUser(groupID: groupInfo.groupID,
                                                               userUUID: uuid) {
                            result in
                            switch result {
                            case .success( _):
                                break
                            case .failure(let error):
                                print(error, "error of deleting user from group")
                            }
                            self.navigationController?.popViewController(animated: true)
                        }
                    }
                })
                self.present(alert, animated: true)
            }
        }
    }
}

extension GroupEditorViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.row == 0 {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "\(GroupNameCell.self)", for: indexPath)
                    as? GroupNameCell else {
                fatalError("error of dequeing GroupNameCell")
            }
            if let groupInfo = groupInfo {
                cell.configure(name: groupInfo.groupName)
            }
            return cell
        } else if indexPath.row == 1 {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "\(MemberManageCell.self)", for: indexPath)
                    as? MemberManageCell else {
                fatalError("error of dequeing GroupMemberCell")
            }
            return cell
        } else {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "\(LeaveGroupCell.self)", for: indexPath)
                    as? LeaveGroupCell else {
                fatalError("error of dequeuing LeaveGroupCell")
            }
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        3
    }
}
