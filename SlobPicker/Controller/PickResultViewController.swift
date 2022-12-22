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
        let resultRef = FirebaseManager.FirebaseCollectionRef
            .pickerResults(type: mode, pickerID: pickID).ref
        FirebaseManager.shared.getDocuments(resultRef) { (results: [PickResult]) in
            self.pickerResults = results
            self.organizeResult(data: self.pickerResults)
            self.semaphore.signal()
        }
        
        let commentRef = FirebaseManager.FirebaseCollectionRef
            .pickerComments(type: mode, pickerID: pickID).ref
        FirebaseManager.shared.getDocuments(commentRef) { (comments: [Comment]) in
            self.pickerComments = comments
            self.semaphore.signal()
        }
        
        self.semaphore.wait()
        self.semaphore.wait()
        let userUUIDs = Set(self.pickerComments.map {
            $0.userUUID
        })
        for uuid in userUUIDs {
            group.enter()
            let userRef = FirebaseManager.FirebaseCollectionRef
                .users.ref.document(uuid)
            FirebaseManager.shared.getDocument(userRef) { (user: User?) in
                if let user = user {
                    self.users.append(user)
                }
                self.group.leave()
            }
        }
        group.notify(queue: DispatchQueue.main) {
            if let tableView = self.resultTableView {
                tableView.reloadData()
                UIView.animate(views: self.resultTableView.visibleCells,
                               animations: self.animations,
                               delay: 0.4,
                               duration: 0.4)
                ProgressHUD.dismiss()
            }
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
    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var contents: [String] = []
        var type = 0
        switch mode {
        case .forLive:
            if let pickInfo = livePickInfo {
                contents = pickInfo.contents
                type = pickInfo.type
            }
        default:
            if let pickInfo = pickInfo {
                contents = pickInfo.contents
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
                cell.configure(title: pickInfo.title,
                               description: pickInfo.description)
            } else if let pickInfo = livePickInfo {
                cell.configure(title: pickInfo.title,
                               description: pickInfo.description)
            }
            return cell
        } else if indexPath.row <= contents.count {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "\(PickResultCell.self)",
                                                           for: indexPath)
                as? PickResultCell else {
                fatalError("ERROR of dequeuing pickResultCell")
            }
            if type == 0 {
                cell.configureText(content: contents[voteResults[indexPath.row-1].choice],
                                   votes: voteResults[indexPath.row-1].votes,
                                   total: pickerResults.count,
                                   index: indexPath.row-1)
            } else {
                cell.configureImage(content: contents[voteResults[indexPath.row-1].choice],
                                    votes: voteResults[indexPath.row-1].votes,
                                    total: pickerResults.count,
                                    index: indexPath.row-1)
            }
            return cell
        } else {
            guard let cell = tableView
                .dequeueReusableCell(withIdentifier: "\(PickCommentsCell.self)",
                                     for: indexPath) as? PickCommentsCell else {
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
