//
//  PickResultViewController.swift
//  SlobPicker
//
//  Created by 孔令傑 on 2022/11/4.
//

import UIKit

class PickResultViewController: UIViewController {
    @IBOutlet weak var resultTableView: UITableView! {
        didSet {
            resultTableView.dataSource = self
        }
    }
    var pickerResults: [PickResult] = []
    var pickerComments: [Comment] = []
    var voteResults: [VoteResult] = []
    var group = DispatchGroup()
    // data should be pre supplied
    var mode: PrivacyMode = .forPrivate
    var pickInfo: Picker? {
        didSet {
            if let pickInfo = pickInfo, let pickID = pickInfo.id {
                fetchResult(pickID: pickID)
            } else {
                print("ERROR: pickInfo or pickID is nil")
            }
        }
    }
    
    var livePickInfo: LivePicker? {
        didSet {
            if let livePickInfo = livePickInfo, let pickID = livePickInfo.pickerID {
                fetchResult(pickID: pickID)
            } else {
                print("ERROR: wrong with livePick pickID")
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    func fetchResult(pickID: String) {
        group.enter()
        FirebaseManager.shared.fetchResults(collection: mode.rawValue, pickerID: pickID) { result in
            switch result {
            case .success(let results):
                self.pickerResults = results
                self.organizeResult(data: self.pickerResults)
            case .failure(let error):
                print(error, "ERROR of getting picker results")
            }
            self.group.leave()
        }
        group.enter()
        FirebaseManager.shared.fetchComments(collection: mode.rawValue, pickerID: pickID) { result in
            switch result {
            case .success(let comments):
                self.pickerComments = comments
            case .failure(let error):
                print(error, "ERROR of getting picker comments")
            }
            self.group.leave()
        }
        group.notify(queue: DispatchQueue.main) {
            self.resultTableView.reloadData()
        }
    }
    
    func organizeResult(data: [PickResult]) {
        switch mode {
        case .forLive:
            if let pickInfo = livePickInfo {
                for index in 0..<pickInfo.contents.count {
                    let result = data.filter { datum in
                        datum.choice == index
                    }
                    let vote = VoteResult(choice: index, votes: result.count)
                    voteResults.append(vote)
                }
            } else {
                print("ERROR: pickinfo is nil")
            }
        default:
            if let pickInfo = pickInfo {
                for index in 0..<pickInfo.contents.count {
                    let result = data.filter { datum in
                        datum.choice == index
                    }
                    let vote = VoteResult(choice: index, votes: result.count)
                    voteResults.append(vote)
                }
            } else {
                print("ERROR: pickinfo is nil")
            }
        }
    }
}

// MARK: TableView DataSource
extension PickResultViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.row == 0 {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "\(PickResultCell.self)", for: indexPath) as? PickResultCell else {
                fatalError("ERROR of dequeuing pickResultCell")
            }
            switch mode {
            case .forLive:
                if let pickInfo = livePickInfo {
                    cell.configureLive(results: voteResults, data: pickInfo)
                } else {
                    print("ERROR: pickInfo is nil")
                }
            default:
                if let pickInfo = pickInfo {
                    cell.configure(results: voteResults, data: pickInfo)
                } else {
                    print("ERROR: pickInfo is nil")
                }
            }
            return cell
        } else {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "\(PickCommentsCell.self)", for: indexPath) as? PickCommentsCell else {
                fatalError("ERROR of dequeuing pickResultCell")
            }
            cell.configure(data: pickerComments[indexPath.row - 1])
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        pickerComments.count + 1
    }
}
