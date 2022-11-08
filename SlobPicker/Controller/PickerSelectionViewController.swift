//
//  PickerSelectionViewController.swift
//  SlobPicker
//
//  Created by 孔令傑 on 2022/11/3.
//

import UIKit
import DropDown
import MJRefresh

class PickerSelectionViewController: UIViewController {
    @IBOutlet weak var pickersTableView: UITableView! {
        didSet {
            pickersTableView.dataSource = self
            FirebaseManager.shared.fetchAllPrivatePickers { result in
                switch result {
                case .success(let pickers):
                    self.pickers = pickers
                    DispatchQueue.main.async {
                        self.pickersTableView.reloadData()
                    }
                case .failure(let error):
                    print(error)
                }
            }
        }
    }
    @IBOutlet weak var composeImageView: UIImageView! {
        didSet {
            let gesture = UITapGestureRecognizer(target: self, action: #selector(compose))
            composeImageView.addGestureRecognizer(gesture)
        }
    }
    
    var pickers: [PrivatePicker] = []
    let dropDown = DropDown()
    let header = MJRefreshNormalHeader()
    
    // MARK: Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpNavigation()
        header.setRefreshingTarget(self, refreshingAction: #selector(self.headerRefresh))
        self.pickersTableView.mj_header = header
//        let storyboard = UIStoryboard(name: "Main", bundle: nil)
//        let loginVC = storyboard.instantiateViewController(withIdentifier: "\(LoginViewController.self)") as! LoginViewController
//        loginVC.superVC = self
//        loginVC.modalPresentationStyle = .fullScreen
//        present(loginVC, animated: true)
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        FirebaseManager.shared.fetchAllPrivatePickers { result in
            switch result {
            case .success(let pickers):
                self.pickers = pickers
                DispatchQueue.main.async {
                    self.pickersTableView.reloadData()
                }
            case .failure(let error):
                print(error)
            }
        }
    }
    
    @objc func headerRefresh() {
        FirebaseManager.shared.fetchAllPrivatePickers { result in
            switch result {
            case .success(let pickers):
                self.pickers = pickers
                DispatchQueue.main.async {
                    self.pickersTableView.reloadData()
                    self.pickersTableView.mj_header?.endRefreshing()
                }
            case .failure(let error):
                print(error)
            }
        }
    }
    
    func setUpNavigation() {
        navigationItem.title = "Pickers"
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "plus.app"), style: .plain, target: self, action: #selector(createNewGroup))
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
        cell.configure(data: pickers[indexPath.row], index: indexPath.row)
        return cell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        pickers.count
    }
}
