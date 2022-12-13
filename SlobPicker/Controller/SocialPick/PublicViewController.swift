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
        FirebaseManager.auth.addStateDidChangeListener { auth, user in
            if user != nil {
                print("user has logged in")
            } else {
                let storyboard = UIStoryboard.main
                let loginVC = storyboard
                    .instantiateViewController(withIdentifier: "\(LoginViewController.self)")
                as! LoginViewController
                loginVC.superVC = self
                loginVC.modalPresentationStyle = .fullScreen
                self.present(loginVC, animated: false)
            }
        }
    }
    
    func setUpDGE() {
        loadingView.tintColor = UIColor.asset(.navigationbar2)
        hotTableView.dg_addPullToRefreshWithActionHandler({ [weak self] () -> Void in
            guard let self = self else { return }
            self.fetchPublicData()
        }, loadingView: loadingView)
        hotTableView.dg_setPullToRefreshFillColor(UIColor.asset(.background) ?? .clear)
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
            UIView.animate(views: self.hotTableView.visibleCells, animations: self.animations, delay: 0.4, duration: 0.4)
        }
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
