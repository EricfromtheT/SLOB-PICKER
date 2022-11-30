//
//  PublicViewController.swift
//  SlobPicker
//
//  Created by 孔令傑 on 2022/11/7.
//

import UIKit
import DGElasticPullToRefresh
import ViewAnimator

class PublicViewController: UIViewController {
    @IBOutlet weak var hotTableView: UITableView! {
        didSet {
            hotTableView.dataSource = self
            hotTableView.delegate = self
            fetchPublicData()
        }
    }
    
    let group = DispatchGroup()
    let loadingView = DGElasticPullToRefreshLoadingViewCircle()
    var newest: [Picker] = []
    var hottest: [Picker] = []
    var lovest: [Picker] = []
    var block: Set<String> = []
    private let animations = [AnimationType.from(direction: .top, offset: 30)]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpDGE()
        setUpNavigation()
        FirebaseManager.auth.addStateDidChangeListener { auth, user in
            if user != nil {
                print("user has logged in")
            } else {
                let storyboard = UIStoryboard(name: "Main", bundle: nil)
                let loginVC = storyboard
                    .instantiateViewController(withIdentifier: "\(LoginViewController.self)")
                as! LoginViewController
                loginVC.superVC = self
                loginVC.modalPresentationStyle = .fullScreen
                self.present(loginVC, animated: false)
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let appearance = UINavigationBarAppearance()
        //        appearance.configureWithTransparentBackground()
        appearance.backgroundColor = UIColor.asset(.navigationbar2)
        // cancel navigationbar seperator
        appearance.shadowColor = nil
        appearance.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white]
        navigationItem.titleView?.tintColor = .white
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
    }
    
    // MARK: PULL DOWN third party
    func setUpDGE() {
        loadingView.tintColor = UIColor.white
        hotTableView.dg_addPullToRefreshWithActionHandler({ [weak self] () -> Void in
            guard let self = self else { return }
            self.fetchPublicData()
        }, loadingView: loadingView)
        hotTableView.dg_setPullToRefreshFillColor(UIColor.asset(.navigationbar2) ?? .clear)
        hotTableView.dg_setPullToRefreshBackgroundColor(hotTableView.backgroundColor!)
    }
    
    func fetchPublicData() {
        group.enter()
        FirebaseManager.shared.fetchNewestPublicPicker(completion: { result in
            switch result {
            case .success(let newest):
                self.newest = newest
            case .failure(let error):
                print(error, "error of getting newest public picker")
            }
            self.group.leave()
        })
        group.enter()
        FirebaseManager.shared.fetchHottestPublicPicker(completion: { result in
            switch result {
            case .success(let hottest):
                self.hottest = hottest
            case .failure(let error):
                print(error, "error of getting hottest public picker")
            }
            self.group.leave()
        })
        group.enter()
        FirebaseManager.shared.fetchLovestPublicPicker { result in
            switch result {
            case .success(let lovest):
                self.lovest = lovest
            case .failure(let error):
                print(error, "error of getting lovest public picker")
            }
            self.group.leave()
        }
        group.enter()
        guard let uuid = FirebaseManager.auth.currentUser?.uid else { fatalError("uuid is nil") }
        FirebaseManager.shared.getUserInfo(userUUID: uuid) { result in
            switch result {
            case .success(let user):
                if let blockList = user.block {
                    self.block = Set(blockList)
                } else {
                    print("user block list is not initialized")
                }
            case .failure(let error):
                return print(error, "error of getting self user info")
            }
            self.group.leave()
        }
        group.notify(queue: DispatchQueue.main) {
            self.hotTableView.reloadData()
            self.hotTableView.dg_stopLoading()
            UIView.animate(views: self.hotTableView.visibleCells, animations: self.animations, delay: 0.4, duration: 0.6)
        }
    }
    
    // MARK: Navigation
    func setUpNavigation() {
        // set up bar button
        let compose = UIBarButtonItem(image: UIImage(systemName: "square.and.pencil"), style: .plain, target: self, action: #selector(compose))
        // profile
        let profileMenu = UIMenu(children: [
            UIAction(title: "個人頁面") { action in
                let profileVC = UIStoryboard(name: "Profile", bundle: nil).instantiateViewController(withIdentifier: "\(ProfileViewController.self)")
                self.show(profileVC, sender: self)
            },
            UIAction(title: "登出") { action in
                FirebaseManager.shared.logOut()
                UserDefaults.standard.set(nil, forKey: UserInfo.userNameKey)
                UserDefaults.standard.set(nil, forKey: UserInfo.userIDKey)
            }
        ])
        let profile = UIBarButtonItem(image: UIImage(systemName: "person"), menu: profileMenu)
        // relationship
        let storyboard = UIStoryboard(name: "Relationship", bundle: nil)
        let relationshipMenu = UIMenu(children: [
            UIAction(title: "添加好友") { action in
                guard let friendVC = storyboard.instantiateViewController(withIdentifier: "\(SearchIDViewController.self)") as? SearchIDViewController else {
                    print("ERROR: SearchIDViewController didn't instanciate")
                    return
                }
                self.show(friendVC, sender: self)
            },
            UIAction(title: "創建群組") { action in
                
                guard let groupVC = storyboard.instantiateViewController(withIdentifier: "\(GroupCreateViewController.self)")
                        as? GroupCreateViewController else {
                    print("ERROR: GroupCreateViewController didn't instanciate")
                    return
                }
                self.show(groupVC, sender: self)
            }
        ])
        let relationship = UIBarButtonItem(image: UIImage(systemName: "plus.app"), menu: relationshipMenu)
        navigationItem.rightBarButtonItems = [compose, relationship, profile]
        navigationItem.leftBarButtonItems = [
            UIBarButtonItem(image: UIImage(named: "logo2"), style: .plain, target: nil, action: nil),
            UIBarButtonItem(title: "                    ", style: .done, target: nil, action: nil),
            UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: self, action: nil)
        ]
    }
    
    // call pickEditorViewController to edit a new picker
    @objc func compose() {
        let storyboard = UIStoryboard(name: "Interaction", bundle: nil)
        guard let editorVC = storyboard.instantiateViewController(withIdentifier: "\(PickerEditorViewController.self)")
                as? PickerEditorViewController else {
            fatalError("ERROR: cannot instantiate PickEditorViewController")
        }
        show(editorVC, sender: self)
    }
}

// MARK: TableView DataSource
extension PublicViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "\(HotCell.self)", for: indexPath)
                as? HotCell else {
            fatalError("ERROR: cannot instantiate HotCell")
        }
        if indexPath.section == 0 {
            let cleanHottest = hottest.filter {
                !block.contains($0.authorUUID)
            }
            cell.hottestPickers = cleanHottest
            cell.mode = .hottest
        } else if indexPath.section == 1 {
            let cleanNewest = newest.filter {
                !block.contains($0.authorUUID)
            }
            cell.newestPickers = cleanNewest
            cell.mode = .newest
        } else {
            let cleanLovest = lovest.filter {
                !block.contains($0.authorUUID)
            }
            cell.lovestPickers = cleanLovest
            cell.mode = .lovest
        }
        cell.superVC = self
        return cell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        1
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        3
    }
}

// MARK: TableView Delegate
extension PublicViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            return "熱門投票"
        } else if section == 1 {
            return "最新投票"
        } else {
            return "最受喜愛"
        }
    }
}
