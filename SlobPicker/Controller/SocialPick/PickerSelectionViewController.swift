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
        setUpDGE()
    }
    
    // MARK: SetUp
    func loadData() {
        guard let uuid = FirebaseManager.auth.currentUser?.uid else { fatalError() }
        let query = FirebaseManager.shared.privatePickersRef.whereField("members_ids", arrayContains: uuid).order(by: "created_time", descending: true)
        FirebaseManager.shared.getDocuments(query) { (pickers: [Picker]) in
            self.pickers = pickers
            self.semaphore.signal()
        }
        semaphore.wait()
        //
        let authors = Set(pickers.map { $0.authorUUID })
        authors.forEach {
            group.enter()
            let ref = FirebaseManager.FirebaseCollectionRef.users.ref.document($0)
            FirebaseManager.shared.getDocument(ref) { (user: User?) in
                if let user = user {
                    self.users.append(user)
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
    
    // MARK: Action
    @objc func compose() {
        let storyboard = UIStoryboard.interaction
        guard let editorVC = storyboard.instantiateViewController(withIdentifier: "\(PickerEditorViewController.self)")
                as? PickerEditorViewController else {
            fatalError("ERROR: cannot instantiate PickEditorViewController")
        }
        show(editorVC, sender: self)
    }
    
    // see picker's voting result
    @IBAction func goToResult(_ sender: UIButton) {
        let storyboard = UIStoryboard.pickerSelection
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
        let storyboard = UIStoryboard.interaction
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
