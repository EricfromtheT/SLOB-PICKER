//
//  GroupNameEditViewController.swift
//  SlobPicker
//
//  Created by 孔令傑 on 2022/12/3.
//

import UIKit
import ProgressHUD

class GroupNameEditViewController: UIViewController {
    @IBOutlet weak var nameTextField: UITextField! {
        didSet {
            nameTextField.text = groupName
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
    var groupName: String?
    var groupID: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "編輯群組名稱"
    }
    
    @IBAction func save() {
        if let content = nameTextField.text {
            if content == "" {
                let alert = UIAlertController(title: "名稱不可為空", message: "請輸入名稱", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "好的", style: .cancel))
                self.present(alert, animated: true)
            } else {
                ProgressHUD.show()
                let newName = content.trimmingCharacters(in: .whitespacesAndNewlines)
                completion?(newName)
                if let groupID = groupID {
                    FirebaseManager.shared.changeGroupName(name: newName, groupID: groupID) {
                        result in
                        switch result {
                        case .success( _):
                            break
                        case .failure(let error):
                            print(error, "error of changing group name")
                        }
                        ProgressHUD.dismiss()
                        self.navigationController?.popViewController(animated: true)
                    }
                }
            }
        }
    }
}
