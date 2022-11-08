//
//  PublicViewController.swift
//  SlobPicker
//
//  Created by 孔令傑 on 2022/11/7.
//

import UIKit

class PublicViewController: UIViewController {
    @IBOutlet weak var hotTableView: UITableView! {
        didSet {
            hotTableView.dataSource = self
            hotTableView.delegate = self
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
            }
        }
    }
    
    let group = DispatchGroup()
    var newest: [Picker] = []
    var hottest: [Picker] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
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
