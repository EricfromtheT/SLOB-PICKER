//
//  PickerSelectionViewController.swift
//  SlobPicker
//
//  Created by 孔令傑 on 2022/11/3.
//

import UIKit
import DropDown
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
    let dropDown = DropDown()
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
        appearance.backgroundColor = UIColor.asset(.navigationbar2)
        // cancel navigationbar seperator
        appearance.shadowColor = nil
        appearance.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white]
        navigationItem.titleView?.tintColor = .white
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
    }
    
    deinit {
        pickersTableView.dg_removePullToRefresh()
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
        loadingView.tintColor = UIColor.white
        pickersTableView.dg_addPullToRefreshWithActionHandler({ [weak self] () -> Void in
            guard let self = self else {
                fatalError("no pickerselectionViewController")
            }
            self.users = []
            DispatchQueue.global().async {
                self.loadData()
            }
        }, loadingView: loadingView)
        pickersTableView.dg_setPullToRefreshFillColor(UIColor.asset(.navigationbar2) ?? .clear)
        pickersTableView.dg_setPullToRefreshBackgroundColor(pickersTableView.backgroundColor!)
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
        dropDown.anchorView = navigationItem.rightBarButtonItem
        dropDown.width = 200
        dropDown.dataSource = ["創建群組", "添加好友"]
        dropDown.direction = .bottom
        dropDown.bottomOffset = CGPoint(x: 0, y: 40)
        dropDown.selectionAction = { index, _ in
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
    
    // MARK: Action
    @objc func createNewGroup() {
        dropDown.show()
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
