//
//  PublicViewController.swift
//  SlobPicker
//
//  Created by 孔令傑 on 2022/11/7.
//

import UIKit
import DGElasticPullToRefresh

class PublicViewController: UIViewController {
    @IBOutlet weak var hotTableView: UITableView! {
        didSet {
            hotTableView.dataSource = self
            hotTableView.delegate = self
            fetchPublicData()
            group.notify(queue: DispatchQueue.main) {
                self.hotTableView.reloadData()
            }
        }
    }
    
    let group = DispatchGroup()
    let loadingView = DGElasticPullToRefreshLoadingViewCircle()
    var newest: [Picker] = []
    var hottest: [Picker] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpDGE()
//        let storyboard = UIStoryboard(name: "Main", bundle: nil)
//        let loginVC = storyboard.instantiateViewController(withIdentifier: "\(LoginViewController.self)") as! LoginViewController
//        loginVC.superVC = self
//        loginVC.modalPresentationStyle = .fullScreen
//        present(loginVC, animated: true)
        navigationItem.title = "公開Pick"
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let appearance = UINavigationBarAppearance()
        appearance.backgroundColor = UIColor.asset(.navigationbar)
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
        loadingView.tintColor = UIColor(red: 78/255.0, green: 221/255.0, blue: 200/255.0, alpha: 1.0)
        hotTableView.dg_addPullToRefreshWithActionHandler({ [weak self] () -> Void in
            self?.fetchPublicData()
            self?.group.notify(queue: .main) {
                self?.hotTableView.reloadData()
                self?.hotTableView.dg_stopLoading()
            }
        }, loadingView: loadingView)
        hotTableView.dg_setPullToRefreshFillColor(UIColor(red: 152/255.0, green: 111/255.0, blue: 229/255.0, alpha: 1.0))
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
    }
}

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

extension PublicViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        section == 0 ? "熱門Pickers" : "最新Pickers"
    }
}
