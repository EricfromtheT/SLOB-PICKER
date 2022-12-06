//
//  PickerSelectionViewController.swift
//  SlobPicker
//
//  Created by 孔令傑 on 2022/11/3.
//

import UIKit
import DGElasticPullToRefresh
import ViewAnimator

class PickerSelectionViewController: UIViewController {
    @IBOutlet weak var pickersTableView: UITableView! {
        didSet {
            pickersTableView.dataSource = self
            DispatchQueue.global().async {
                self.loadData()
            }
        }
    }
    
    var pickers: [Picker] = []
    var users: [User] = []
    let loadingView = DGElasticPullToRefreshLoadingViewCircle()
    let group = DispatchGroup()
    let semaphore = DispatchSemaphore(value: 0)
    private let animations = [AnimationType.from(direction: .top, offset: 40)]
    
    // MARK: Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpNavigation()
        setUpDGE()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let appearance = UINavigationBarAppearance()
        appearance.backgroundColor = UIColor.asset(.background)
        // cancel navigationbar seperator
        appearance.shadowColor = nil
        appearance.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.asset(.navigationbar2) as Any]
//        navigationItem.titleView?.tintColor = UIColor.asset(.navigationbar2)
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
    }
    
    // MARK: SetUp
    func loadData() {
        FirebaseManager.shared.fetchAllPrivatePickers { result in
            switch result {
            case .success(let pickers):
                self.pickers = pickers
            case .failure(let error):
                print(error)
            }
            self.semaphore.signal()
        }
        semaphore.wait()
        //
        let authors = Set(pickers.map { $0.authorUUID })
        authors.forEach {
            group.enter()
            FirebaseManager.shared.getUserInfo(userUUID: $0) { result in
                switch result {
                case .success(let user):
                    self.users.append(user)
                case .failure(let error):
                    print(error, "error of getting user's info")
                }
                self.group.leave()
            }
        }
        group.notify(queue: .main) {
            self.pickersTableView.reloadData()
            self.pickersTableView.dg_stopLoading()
            UIView.animate(views: self.pickersTableView.visibleCells, animations: self.animations, duration: 0.6)
        }
    }
    
    func setUpDGE() {
        loadingView.tintColor = UIColor.asset(.navigationbar2)
        pickersTableView.dg_addPullToRefreshWithActionHandler({ [weak self] () -> Void in
            guard let self = self else {
                fatalError("no pickerselectionViewController")
            }
            self.users = []
            DispatchQueue.global().async {
                self.loadData()
            }
        }, loadingView: loadingView)
        pickersTableView.dg_setPullToRefreshFillColor(UIColor.asset(.background) ?? .clear)
        pickersTableView.dg_setPullToRefreshBackgroundColor(pickersTableView.backgroundColor!)
    }
    
    // MARK: Navigationbar
    func setUpNavigation() {
        // set up bar button
        let compose = UIBarButtonItem(image: UIImage(systemName: "square.and.pencil"), style: .plain, target: self, action: #selector(compose))
        let menu = UIMenu(children: [
            UIAction(title: "個人頁面") { action in
                let profileVC = UIStoryboard(name: "Profile", bundle: nil).instantiateViewController(withIdentifier: "\(ProfileViewController.self)")
                self.show(profileVC, sender: self)
            },
            UIAction(title: "登出") { action in
                FirebaseManager.shared.logOut()
            }
        ])
        let profile = UIBarButtonItem(image: UIImage(systemName: "gearshape"), menu: menu)
        let storyboard = UIStoryboard(name: "Relationship", bundle: nil)
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
        let relationship = UIBarButtonItem(image: UIImage(systemName: "person.2"), menu: relationshipMenu)
        navigationItem.rightBarButtonItems = [compose, relationship, profile]
        navigationItem.leftBarButtonItems = [
            UIBarButtonItem(image: UIImage(named: "logo2"), style: .plain, target: nil, action: nil),
            UIBarButtonItem(title: "                    ", style: .done, target: nil, action: nil),
            UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: self, action: nil),
        ]
    }
    
    // MARK: Action
    // call pickEditorViewController to edit a new picker
    @objc func compose() {
        let storyboard = UIStoryboard(name: "Interaction", bundle: nil)
        guard let editorVC = storyboard.instantiateViewController(withIdentifier: "\(PickerEditorViewController.self)")
                as? PickerEditorViewController else {
            fatalError("ERROR: cannot instantiate PickEditorViewController")
        }
        show(editorVC, sender: self)
    }
    
    // see picker's voting result
    @IBAction func goToResult(_ sender: UIButton) {
        let storyboard = UIStoryboard(name: "PickerSelection", bundle: nil)
        guard let resultVC = storyboard.instantiateViewController(withIdentifier: "\(PickResultViewController.self)")
                as? PickResultViewController else {
            print("PickResultViewController rendering error")
            return
        }
        resultVC.pickInfo = pickers[sender.tag]
        show(resultVC, sender: self)
    }
    
    // go to pick
    @IBAction func goToPick(_ sender: UIButton) {
        let storyboard = UIStoryboard(name: "Interaction", bundle: nil)
        guard let pickVC = storyboard.instantiateViewController(withIdentifier: "\(PickViewController.self)")
                as? PickViewController else {
            print("PickViewController rendering error")
            return
        }
        pickVC.mode = .forPrivate
        pickVC.pickInfo = pickers[sender.tag]
        show(pickVC, sender: self)
    }
}

// MARK: TableView Datasource
extension PickerSelectionViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "\(PickSelectionCell.self)", for: indexPath)
                as? PickSelectionCell else {
            fatalError("ERROR: pickSelectionCell broke")
        }
        let user = users.filter { $0.userUUID == pickers[indexPath.row].authorUUID }[0]
        cell.configure(data: pickers[indexPath.row], index: indexPath.row, url: user.profileURL)
        return cell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        users.isEmpty ? 0 : pickers.count
    }
}
