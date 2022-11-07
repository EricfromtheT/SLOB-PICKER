//
//  LoginViewController.swift
//  SlobPicker
//
//  Created by 孔令傑 on 2022/11/7.
//

import UIKit

class LoginViewController: UIViewController {
    @IBOutlet weak var idField: UITextField!
    @IBOutlet weak var nameField: UITextField!
    var superVC: PickerSelectionViewController!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func done() {
        if let id = idField.text, let name = nameField.text {
            UserDefaults.standard.set(id, forKey: "userID")
            UserDefaults.standard.set(name, forKey: "userName")
            FakeUserInfo.shared.userID = id
            FakeUserInfo.shared.userName = name
            superVC.dismiss(animated: true)
        }
    }
}
