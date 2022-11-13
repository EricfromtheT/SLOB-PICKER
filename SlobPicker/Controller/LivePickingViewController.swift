//
//  LivePickingViewController.swift
//  SlobPicker
//
//  Created by 孔令傑 on 2022/11/12.
//

import UIKit
import FirebaseFirestore

class LivePickingViewController: UIViewController {
    @IBOutlet weak var bgView: UIView!
    @IBOutlet weak var countdownLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var rankTableView: UITableView!
    
    var livePicker: LivePicker?
    var voteResults: [VoteResult] = []
    var counter = 5
    var dataSource: UITableViewDiffableDataSource<Int, VoteResult>!
    var resultListener: ListenerRegistration?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        start()
        updateUI()
        configureDataSource()
    }
    
    func configureDataSource() {
        dataSource = UITableViewDiffableDataSource<Int, VoteResult>(tableView: rankTableView) {
            (tableView, indexPath, result) -> UITableViewCell? in
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
        }
    }
    
    func configureSnap() {
        var snapShot = NSDiffableDataSourceSnapshot<Int, VoteResult>()
        snapShot.appendSections([0])
        snapShot.appendItems(voteResults)
        dataSource.apply(snapShot)
    }
    
    func addResultListener() {
        if let livePicker = livePicker {
            resultListener = FirebaseManager.shared.database.collection("livePickers").document(livePicker.pickerID).collection("results").addSnapshotListener { qrry, error in
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
        Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(updateCounter), userInfo: nil, repeats: true)
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
            countdownLabel.text = counter == 0 ? "開始" : "\(counter)"
        } else {
            bgView.isHidden = true
            addResultListener()
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
