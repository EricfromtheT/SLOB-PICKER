//
//  PublicViewController.swift
//  SlobPicker
//
//  Created by 孔令傑 on 2022/11/7.
//

import UIKit
import DGElasticPullToRefresh
import ViewAnimator
import FirebaseAuth
import DropDown

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
    let relationshipDropDown = DropDown()
    var newest: [Picker] = []
    var hottest: [Picker] = []
    private let animations = [AnimationType.from(direction: .top, offset: 30)]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpDGE()
        setUpNavigation()
        Auth.auth().addStateDidChangeListener { auth, user in
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
        navigationItem.title = "公開Pick"
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let appearance = UINavigationBarAppearance()
        appearance.backgroundColor = UIColor.asset(.navigationbar2)
        // cancel navigationbar seperator
        appearance.shadowColor = nil
        appearance.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white]
        navigationItem.titleView?.tintColor = .white
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
    }
    
    deinit {
        hotTableView.dg_removePullToRefresh()
    }
    
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
        group.notify(queue: DispatchQueue.main) {
            self.hotTableView.reloadData()
            self.hotTableView.dg_stopLoading()
            UIView.animate(views: self.hotTableView.visibleCells, animations: self.animations, delay: 0.4, duration: 0.6)
        }
    }
    
    func setUpNavigation() {
        navigationItem.title = "群組Pick"
        // set up bar button
        let relationship = UIBarButtonItem(image: UIImage(systemName: "plus.app"), style: .plain, target: self, action: #selector(createNewGroup))
        let compose = UIBarButtonItem(image: UIImage(systemName: "square.and.pencil"), style: .plain, target: self, action: #selector(compose))
        navigationItem.rightBarButtonItems = [compose, relationship]
        let menu = UIMenu(children: [
            UIAction(title: "登出") { action in
                FirebaseManager.shared.logOut()
            }
        ])
        let profile = UIBarButtonItem(image: UIImage(systemName: "person"), menu: menu)
        navigationItem.leftBarButtonItem = profile
        // relationship
        relationshipDropDown.anchorView = navigationItem.rightBarButtonItem
        relationshipDropDown.width = 200
        relationshipDropDown.dataSource = ["創建群組", "添加好友"]
        relationshipDropDown.direction = .bottom
        relationshipDropDown.bottomOffset = CGPoint(x: 0, y: 40)
        relationshipDropDown.selectionAction = { index, _ in
            let storyboard = UIStoryboard(name: "Relationship", bundle: nil)
            if index == 1 {
                guard let friendVC = storyboard.instantiateViewController(withIdentifier: "\(SearchIDViewController.self)") as? SearchIDViewController else {
                    print("ERROR: SearchIDViewController didn't instanciate")
                    return
                }
                self.show(friendVC, sender: self)
            } else {
                guard let groupVC = storyboard.instantiateViewController(withIdentifier: "\(GroupCreateViewController.self)")
                        as? GroupCreateViewController else {
                    print("ERROR: GroupCreateViewController didn't instanciate")
                    return
                }
                self.show(groupVC, sender: self)
            }
        }
    }
    
    @objc func createNewGroup() {
        relationshipDropDown.show()
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
            cell.hottestPickers = hottest
            cell.mode = .hottest
        } else {
            cell.newestPickers = newest
            cell.mode = .newest
        }
        cell.superVC = self
        return cell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        1
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        2
    }
}

// MARK: TableView Delegate
extension PublicViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        section == 0 ? "熱門Pickers" : "最新Pickers"
    }
}
