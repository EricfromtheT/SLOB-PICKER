//
//  ProfileViewController.swift
//  SlobPicker
//
//  Created by 孔令傑 on 2022/11/24.
//

import UIKit

class ProfileViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func deleteAccount() {
        let alert = UIAlertController(title: "是否確定要刪除帳號", message: "帳號刪除後將無法找回任何個人資料及使用紀錄", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        alert.addAction(UIAlertAction(title: "確認刪除", style: .destructive){ action in
            
        })
        present(alert, animated: true)
    }
    
    func deleteFirebaseAccount() {
        // 清空user在DB裡的資料
        // 刪除帳號
    }
}
