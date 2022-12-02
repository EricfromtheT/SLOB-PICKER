//
//  PickResultViewController.swift
//  SlobPicker
//
//  Created by 孔令傑 on 2022/11/4.
//

import UIKit
import ProgressHUD
import Lottie
import ViewAnimator

class PickResultViewController: UIViewController {
    @IBOutlet weak var resultTableView: UITableView! {
        didSet {
            resultTableView.dataSource = self
        }
    }
    @IBOutlet weak var leaveButton: UIButton! {
        didSet {
            if mode != .forLive {
                leaveButton.isHidden = true
            }
        }
    }
    var animationView: LottieAnimationView?
    var pickerResults: [PickResult] = []
    var pickerComments: [Comment] = []
    var voteResults: [VoteResult] = []
    var users: [User] = []
    let group = DispatchGroup()
    let semaphore = DispatchSemaphore(value: 0)
    private let animations = [AnimationType.from(direction: .top, offset: 30)]
    // data should be pre supplied
    var mode: PrivacyMode = .forPrivate
    var pickInfo: Picker? {
        didSet {
            if let pickInfo = pickInfo, let pickID = pickInfo.id {
                DispatchQueue.global().async {
                    self.fetchResult(pickID: pickID)
                }
            } else {
                print("ERROR: pickInfo or pickID is nil")
            }
        }
    }
    
    var livePickInfo: LivePicker? {
        didSet {
            if let livePickInfo = livePickInfo, let pickID = livePickInfo.pickerID {
                DispatchQueue.global().async {
                    self.fetchResult(pickID: pickID)
                }
            } else {
                print("ERROR: wrong with livePick pickID")
            }
        }
    }
    var contentCount = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        ProgressHUD.animationType = .lineScaling
        if mode != .forLive {
            ProgressHUD.show()
        }
        navigationItem.title = "投票結果"
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if mode == .forLive {
            addBGAnimation()
        }
    }
    
    func addBGAnimation() {
        animationView = .init(name: "congrats")
        animationView?.loopMode = .loop
        animationView?.frame = CGRect(x: 0, y: 0, width: SPConstant.screenWidth, height: SPConstant.screenHeight)
        animationView?.contentMode = .scaleAspectFill
        animationView?.animationSpeed = 1
        resultTableView.addSubview(animationView!)
        resultTableView.sendSubviewToBack(animationView!)
        animationView?.play()
    }
    
    func fetchResult(pickID: String) {
        FirebaseManager.shared.fetchResults(collection: mode.rawValue, pickerID: pickID) { result in
            switch result {
            case .success(let results):
                self.pickerResults = results
                self.organizeResult(data: self.pickerResults)
            case .failure(let error):
                print(error, "ERROR of getting picker results")
            }
            self.semaphore.signal()
        }

        FirebaseManager.shared.fetchComments(collection: mode.rawValue, pickerID: pickID) { result in
            switch result {
            case .success(let comments):
                self.pickerComments = comments
            case .failure(let error):
                print(error, "ERROR of getting picker comments")
            }
            self.semaphore.signal()
        }
        self.semaphore.wait()
        self.semaphore.wait()
        let userUUIDs = Set(self.pickerComments.map {
            $0.userUUID
        })
        for uuid in userUUIDs {
            group.enter()
            FirebaseManager.shared.getUserInfo(userUUID: uuid) { result in
                switch result {
                case .success(let user):
                    self.users.append(user)
                case .failure(let error):
                    return print(error, "error of getting user info")
                }
                self.group.leave()
            }
        }
        group.notify(queue: DispatchQueue.main) {
            if let tableView = self.resultTableView {
                tableView.reloadData()
                UIView.animate(views: self.resultTableView.visibleCells, animations: self.animations, delay: 0.4, duration: 0.4)
                ProgressHUD.dismiss()
            }
        }
    }
    
    // TODO: 現在有user的uuid，要再擷取each user資料來顯示留言以及最終投票結果
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
                    voteResults.sort {
                        $0.votes > $1.votes
                    }
                    contentCount = voteResults.count
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
                    voteResults.sort() {
                        $0.votes > $1.votes
                    }
                    contentCount = voteResults.count
                }
            } else {
                print("ERROR: pickinfo is nil")
            }
        }
    }
    
    @IBAction func goToRootView() {
        let rootVC = UIApplication.shared.windows.first?.rootViewController
        rootVC?.dismiss(animated: true)
    }
}

// MARK: TableView DataSource
extension PickResultViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var contents: [String] = []
        var type = 0
        switch mode {
        case .forLive:
            if let pickInfo = livePickInfo {
                contents = pickInfo.contents
                title = pickInfo.title
                type = pickInfo.type
            }
        default:
            if let pickInfo = pickInfo {
                contents = pickInfo.contents
                title = pickInfo.title
                type = pickInfo.type
            }
        }
        if indexPath.row == 0 {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "\(PickResultTitleCell.self)",
                                                           for: indexPath)
                    as? PickResultTitleCell else {
                fatalError("ERROR of dequeuing pickResultTitleCell")
            }
            if let pickInfo = pickInfo {
                cell.configure(title: pickInfo.title, description: pickInfo.description)
            } else if let pickInfo = livePickInfo {
                cell.configure(title: pickInfo.title, description: pickInfo.description)
            }
            return cell
        } else if indexPath.row <= contents.count {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "\(PickResultCell.self)",
                                                           for: indexPath)
                as? PickResultCell else {
                fatalError("ERROR of dequeuing pickResultCell")
            }
            if type == 0 {
                cell.configureText(content: contents[voteResults[indexPath.row-1].choice], votes: voteResults[indexPath.row-1].votes, total: pickerResults.count, index: indexPath.row-1)
            } else {
                cell.configureImage(content: contents[voteResults[indexPath.row-1].choice], votes: voteResults[indexPath.row-1].votes, total: pickerResults.count, index: indexPath.row-1)
            }
            return cell
        } else {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "\(PickCommentsCell.self)", for: indexPath) as? PickCommentsCell else {
                fatalError("ERROR of dequeuing pickResultCell")
            }
            let userInfo = self.users.filter {
                $0.userUUID == pickerComments[indexPath.row-1-contentCount].userUUID
            }
            cell.configure(data: pickerComments[indexPath.row-1-contentCount],
                           userInfo: userInfo[0])
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        contentCount != 0 ? pickerComments.count + contentCount + 1 : 0
    }
}
