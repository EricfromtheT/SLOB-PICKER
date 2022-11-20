//
//  LivePickingViewController.swift
//  SlobPicker
//
//  Created by 孔令傑 on 2022/11/12.
//

import UIKit
import FirebaseFirestore
import MagicTimer
import Lottie

class LivePickingViewController: UIViewController {
    @IBOutlet weak var bgView: UIView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var rankTableView: UITableView!
    @IBOutlet weak var magicTimer: MagicTimerView!
    
    var livePicker: LivePicker?
    var voteResults: [VoteResult] = []
    var counter = 2.5
    var dataSource: UITableViewDiffableDataSource<Int, VoteResult>!
    var resultListener: ListenerRegistration?
    var myTimer: Timer?
    var animationView: LottieAnimationView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        start()
        setUpTimer()
        addCountDownAnimation()
        animationView?.play()
        updateUI()
        configureDataSource()
    }
    
    func setUpTimer() {
        var remainTime: Int = 0
        if let livePicker = livePicker, let startTime = livePicker.startTime {
            let endTime = startTime + 30000
            remainTime = endTime - Date().millisecondsSince1970
        }
        magicTimer.isActiveInBackground = true
        magicTimer.font = UIFont.systemFont(ofSize: 20, weight: .bold)
        magicTimer.mode = .countDown(fromSeconds: Double(remainTime / 1000))
        magicTimer.delegate = self
    }
    
    func configureDataSource() {
        dataSource = UITableViewDiffableDataSource<Int, VoteResult>(tableView: rankTableView) { [weak self]
            (tableView, indexPath, result) -> UITableViewCell? in
            guard let `self` = self else {
                fatalError()
            }
            if self.livePicker?.type == 0 {
                guard let cell = tableView.dequeueReusableCell(withIdentifier: "\(ChoiceCell.self)", for: indexPath)
                        as? ChoiceCell else {
                    fatalError("error of ChoiceCell cannot be instatiated")
                }
                if let livePicker = self.livePicker {
                    cell.configure(title: livePicker.contents[result.choice], result: result)
                } else {
                    fatalError("livePicker no data")
                }
                return cell
            } else {
                guard let cell = tableView.dequeueReusableCell(withIdentifier: "\(ChoiceImageCell.self)", for: indexPath)
                        as? ChoiceImageCell else {
                    fatalError("error of ChoiceImageCell cannot be instatiated")
                }
                if let livePicker = self.livePicker {
                    cell.configure(url: livePicker.contents[result.choice], result: result)
                } else {
                    fatalError("livePicker no data")
                }
                return cell
            }
        }
    }
    
    func configureSnap() {
        var snapShot = NSDiffableDataSourceSnapshot<Int, VoteResult>()
        snapShot.appendSections([0])
        snapShot.appendItems(voteResults)
        dataSource.apply(snapShot)
    }
    
    func addResultListener() {
        if let livePicker = livePicker, let pickerID = livePicker.pickerID {
            resultListener = FirebaseManager.shared.database.collection("livePickers").document(pickerID).collection("results").addSnapshotListener { [weak self] (qrry, error) in
                guard let `self` = self else {
                    fatalError()
                }
                if let error = error {
                    print(error, "error of getting livePickers results")
                } else {
                    self.voteResults = []
                    if let documents = qrry?.documents {
                        let choices = documents.map {
                            $0.data()
                        }
                        for index in 0..<livePicker.contents.count {
                            let results = choices.filter {
                                $0["choice"] as? Int == index
                            }
                            let vote = VoteResult(choice: index, votes: results.count)
                            self.voteResults.append(vote)
                        }
                        self.voteResults.sort {
                            $0.votes > $1.votes
                        }
                        self.configureSnap()
                    }
                }
            }
        }
    }
    
    func start() {
        myTimer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(updateCounter), userInfo: nil, repeats: true)
    }
    
    func addCountDownAnimation() {
        animationView = .init(name: "countDown")
        animationView?.loopMode = .playOnce
        animationView?.frame = CGRect(x: 0, y: SPConstant.screenHeight / 4, width: SPConstant.screenWidth, height: SPConstant.screenHeight / 2)
        animationView?.contentMode = .scaleAspectFill
        animationView?.animationSpeed = 1
        view.addSubview(animationView!)
//        view.sendSubviewToBack(animationView!)
    }
    
    func updateUI() {
        if let livePicker = livePicker {
            titleLabel.text = livePicker.title
            descriptionLabel.text = livePicker.description
        }
    }
    
    @objc func updateCounter() {
        if counter > 0 {
            counter -= 1
        } else {
            bgView.isHidden = true
            setUpTimer()
            addResultListener()
            myTimer?.invalidate()
            magicTimer.startCounting()
        }
    }
    
    @IBAction func choose() {
        let storyboard = UIStoryboard(name: "Interaction", bundle: nil)
        guard let optionsVC = storyboard.instantiateViewController(withIdentifier: "\(LiveOptionsViewController.self)") as? LiveOptionsViewController else {
            fatalError("error of instantiating LiveOptionsViewController")
        }
        if let livePicker = livePicker {
            optionsVC.livePicker = livePicker
        }
        present(optionsVC, animated: true)
    }
}

extension LivePickingViewController: MagicTimerViewDelegate {
    func timerElapsedTimeDidChange(timer: MagicTimerView, elapsedTime: TimeInterval) {
        if elapsedTime == TimeInterval(floatLiteral: 0) {
            // show result controller
            self.presentedViewController?.dismiss(animated: true)
            print("Times up")
            timer.stopCounting()
            timer.isActiveInBackground = false
            let storyboard = UIStoryboard(name: "PickerSelection", bundle: nil)
            guard let resultVC = storyboard.instantiateViewController(withIdentifier: "\(PickResultViewController.self)") as? PickResultViewController else {
                fatalError("errro of instantiating pickresultViewController in live picking")
            }
            if let livePicker = livePicker {
                resultVC.mode = .forLive
                print(livePicker, "data is here")
                resultVC.livePickInfo = livePicker
                resultVC.modalPresentationStyle = .fullScreen
                present(resultVC, animated: true)
            }
        }
    }
}
