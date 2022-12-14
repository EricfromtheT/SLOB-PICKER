//
//  CustomNavigationController.swift
//  SlobPicker
//
//  Created by 孔令傑 on 2022/12/11.
//

import UIKit

class CustomNavigationController: UINavigationController {
    override func viewDidLoad() {
        super.viewDidLoad()
        customAppearance()
        setUpBarItem()
    }
    
    // MARK: Appearance
    func customAppearance() {
        let appearance = UINavigationBarAppearance()
        appearance.backgroundColor = UIColor.asset(.background)
        appearance.shadowColor = nil
        appearance.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.asset(.navigationbar2) as Any]
        self.navigationBar.standardAppearance = appearance
        self.navigationBar.scrollEdgeAppearance = appearance
    }
    
    // MARK: BarItem
    func setUpBarItem() {
        let compose = UIBarButtonItem(image: UIImage(systemName: "square.and.pencil"),
                                      style: .plain,
                                      target: self,
                                      action: #selector(compose))
        // profile
        let profileMenu = UIMenu(children: [
            UIAction(title: "個人頁面") { action in
                let storyboard = UIStoryboard.profile
                let profileVC = storyboard.instantiateViewController(withIdentifier: "\(ProfileViewController.self)")
                self.show(profileVC, sender: self)
            },
            UIAction(title: "登出") { action in
                FirebaseManager.shared.logOut()
                UserDefaults.standard.set(nil,
                                          forKey: UserInfo.userNameKey)
                UserDefaults.standard.set(nil,
                                          forKey: UserInfo.userIDKey)
            }
        ])
        let profile = UIBarButtonItem(image: UIImage(systemName: "gearshape"),
                                      menu: profileMenu)
        // relationship
        let storyboard = UIStoryboard.relationship
        let relationshipMenu = UIMenu(children: [
            UIAction(title: "添加好友") { action in
                guard let friendVC = storyboard.instantiateViewController(withIdentifier: "\(SearchIDViewController.self)") as? SearchIDViewController else {
                    print("ERROR: SearchIDViewController didn't instanciate")
                    return
                }
                self.show(friendVC, sender: self)
            },
            UIAction(title: "管理群組") { action in
                guard let groupVC = storyboard.instantiateViewController(withIdentifier: "\(GroupManageViewController.self)")
                        as? GroupManageViewController else {
                    print("ERROR: GroupManageViewController didn't instanciate")
                    return
                }
                self.show(groupVC, sender: self)
            }
        ])
        let relationship = UIBarButtonItem(image: UIImage(systemName: "person.2"),
                                           menu: relationshipMenu)
        topViewController?.navigationItem.rightBarButtonItems = [compose, relationship, profile]
        topViewController?.navigationItem.leftBarButtonItems = [
            UIBarButtonItem(image: UIImage(named: "logo2"),
                            style: .plain,
                            target: nil,
                            action: nil),
            UIBarButtonItem(title: "                    ",
                            style: .done,
                            target: nil,
                            action: nil),
            UIBarButtonItem(barButtonSystemItem: .flexibleSpace,
                            target: self,
                            action: nil)
        ]
    }
    
    @objc func compose() {
        let storyboard = UIStoryboard.interaction
        guard let editorVC = storyboard.instantiateViewController(withIdentifier: "\(PickerEditorViewController.self)")
                as? PickerEditorViewController else {
            fatalError("ERROR: cannot instantiate PickEditorViewController")
        }
        show(editorVC, sender: self)
    }
}
