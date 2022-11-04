//
//  PickSelectionViewController.swift
//  SlobPicker
//
//  Created by 孔令傑 on 2022/11/3.
//

import UIKit
import DropDown

class PickSelectionViewController: UIViewController {
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
    
    var pickers: [Pick] = []
    let dropDown = DropDown()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpNavigation()
    }
    
    func setUpNavigation() {
        navigationItem.title = "Pickers"
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "plus.app"), style: .plain, target: self, action: #selector(createNewGroup))
        dropDown.anchorView = navigationItem.rightBarButtonItem
        dropDown.width = 200
        dropDown.dataSource = ["創建群組", "添加好友"]
        dropDown.direction = .bottom
    }
    
    @objc func createNewGroup() {
        dropDown.show()
    }
}

extension PickSelectionViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "\(PickSelectionCell.self)", for: indexPath)
                as? PickSelectionCell else {
            fatalError("ERROR: pickSelectionCell broke")
        }
        cell.configure(data: pickers[indexPath.row])
        return cell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        pickers.count
    }
}
