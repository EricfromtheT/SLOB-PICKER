//
//  GroupNameEditViewController.swift
//  SlobPicker
//
//  Created by 孔令傑 on 2022/12/3.
//

import UIKit
import ProgressHUD

enum EditMode {
    case fromGroup
    case fromProfile
}

class NameEditViewController: UIViewController {
    @IBOutlet weak var nameTextField: UITextField! {
        didSet {
            nameTextField.text = originalName
            nameTextField.layer.cornerRadius = 5
            nameTextField.layer.borderWidth = 2
            nameTextField.layer.borderColor = UIColor.asset(.navigationbar2)?.cgColor
        }
    }
    @IBOutlet weak var saveButton: UIButton! {
        didSet {
            saveButton.layer.cornerRadius = 10
            saveButton.layer.borderWidth = 2
            saveButton.layer.borderColor = UIColor.systemGray2.cgColor
        }
    }
    
    var completion: ((String) -> Void)?
    var originalName: String?
    var groupID: String?
    var mode: EditMode = .fromGroup
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if mode == .fromGroup {
            navigationItem.title = "編輯群組名稱"
        } else {
            navigationItem.title = "編輯個人暱稱"
        }
        
    }
    
    @IBAction func save() {
        if let content = nameTextField.text {
            if content == "" {
                let alert = UIAlertController(title: "欄位不可為空", message: "請輸入名稱", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "好的", style: .cancel))
                self.present(alert, animated: true)
            } else {
                ProgressHUD.show()
                let newName = content.trimmingCharacters(in: .whitespacesAndNewlines)
                completion?(newName)
                renewDB(newName: newName) {
                    ProgressHUD.dismiss()
                    self.navigationController?.popViewController(animated: true)
                }
                
            }
        }
    }
    
    func renewDB(newName: String, completion: @escaping (() -> Void)) {
        if mode == .fromGroup {
            if let groupID = groupID {
                FirebaseManager.shared.changeGroupName(name: newName, groupID: groupID) { result in
                    switch result {
                    case .success( _):
                        break
                    case .failure(let error):
                        print(error, "error of changing group name")
                    }
                    completion()
                }
            }
        } else {
            guard let userUUID = FirebaseManager.auth.currentUser?.uid else {
                fatalError("no user uuid")
            }
            let data = ["user_name": newName]
            let ref = FirebaseManager.FirebaseCollectionRef.users.ref.document(userUUID)
            FirebaseManager.shared.update(data, at: ref) {
                completion()
            }
        }
    }
}
