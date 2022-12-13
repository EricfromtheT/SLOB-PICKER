//
//  WaitingRoomViewController.swift
//  SlobPicker
//
//  Created by 孔令傑 on 2022/11/11.
//

import UIKit
import FirebaseFirestore
import Lottie

class WaitingRoomViewController: UIViewController {
    // MARK: IBOutlet
    @IBOutlet weak var attendeeCollectionView: UICollectionView! {
        didSet {
            attendeeCollectionView.delegate = self
        }
    }
    @IBOutlet weak var startButton: UIButton! {
        didSet {
            guard let userId = userId else { fatalError("uuid in keychain is nil") }
            if livePicker?.authorID == userId {
                startButton.isHidden = false
                startButton.layer.cornerRadius = 15
                startButton.layer.borderWidth = 2
                startButton.layer.borderColor = UIColor.white.cgColor
            } else {
                startButton.isHidden = true
            }
        }
    }
    @IBOutlet weak var accessCodeLabel: UILabel! {
        didSet {
            accessCodeLabel.text = livePicker?.accessCode
        }
    }
    
    // MARK: Variables
    var dataSource: UICollectionViewDiffableDataSource<Int, Attendee>!
    var waitingListener: ListenerRegistration?
    var votingListener: ListenerRegistration?
    var group = DispatchGroup()
    var isFirstTime = true
    var animationView: LottieAnimationView?
    var livePicker: LivePicker?
    var attendees: [Attendee]?
    let userId = UserDefaults.standard.string(forKey: UserInfo.userIDKey)
    
    // MARK: Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        configureDataSource()
        setUpLottie()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        addWaitingListener()
        addVotingListener()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(true)
        waitingListener?.remove()
        votingListener?.remove()
    }
    
    @objc func attendeeHasChanged() {
        attendees?.sort {
            $0.attendTime < $1.attendTime
        }
        group.notify(queue: DispatchQueue.main) {
            self.configureSnap()
        }
    }
    
    func setUpLottie() {
        animationView = .init(name: "waiting")
        animationView?.loopMode = .loop
        animationView?.contentMode = .scaleAspectFill
        animationView?.animationSpeed = 1
        view.addSubview(animationView!)
        animationView?.translatesAutoresizingMaskIntoConstraints = false
        animationView?.heightAnchor
            .constraint(equalToConstant: 40).isActive = true
        animationView?.widthAnchor
            .constraint(equalToConstant: 100).isActive = true
        animationView?.bottomAnchor
            .constraint(equalTo: accessCodeLabel.topAnchor).isActive = true
        animationView?.centerXAnchor
            .constraint(equalTo: accessCodeLabel.centerXAnchor).isActive = true
        view.sendSubviewToBack(animationView!)
        animationView?.play()
    }
    
    func configureDataSource() {
        dataSource = UICollectionViewDiffableDataSource<Int, Attendee>(collectionView: attendeeCollectionView) {
            (collectionView, indexPath, user) -> UICollectionViewCell? in
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "\(AttendeeCell.self)", for: indexPath)
                    as? AttendeeCell else {
                fatalError("error, attendeeCell cannot be instantiated")
            }
            cell.configure(data: user)
            return cell
        }
    }
    
    func configureSnap() {
        var snapShot = NSDiffableDataSourceSnapshot<Int, Attendee>()
        snapShot.appendSections([0])
        if let attendees = attendees {
            snapShot.appendItems(attendees)
        }
        dataSource.apply(snapShot)
    }
    
    func addWaitingListener() {
        // TODO: get document ID
        guard let livePicker = livePicker, let pickerID = livePicker.pickerID
        else { fatalError("error of missing livePicker's ID") }
        waitingListener = FirebaseManager.shared.database.collection("livePickers").document(pickerID).collection("attendees").addSnapshotListener { qrry, error in
            if let error = error {
                print(error, "error of getting live picker's attendee data")
            } else if let documents = qrry?.documents {
                do {
                    let attendeeData = try documents.map {
                        try $0.data(as: Attendee.self)
                    }
                    print(attendeeData, "================")
                    self.attendees = attendeeData
                    NSObject.cancelPreviousPerformRequests(withTarget: self)
                    self.perform(#selector(self.attendeeHasChanged), with: nil, afterDelay: 0.8)
                } catch {
                    print(error, "error of decoding LivePicker data")
                }
            }
        }
    }
    
    func addVotingListener() {
        guard let livePicker = livePicker, let pickerID = livePicker.pickerID
        else { fatalError("error of missing livePicker's ID") }
        votingListener = FirebaseManager.shared.database.collection("livePickers").document(pickerID).addSnapshotListener {
            qrry, error in
            if let error = error {
                print(error, "error of getting live Picker's data")
            } else {
                do {
                    let picker = try qrry?.data(as: LivePicker.self)
                    if picker?.status == "voting" {
                        // enter gaming room
                        let storyboard = SBStoryboard.interaction.storyboard
                        guard let liveVC = storyboard.instantiateViewController(withIdentifier: "\(LivePickingViewController.self)") as? LivePickingViewController else {
                            fatalError("ERROR: LivePickingViewController cannot be instantiated")
                        }
                        liveVC.modalPresentationStyle = .fullScreen
                        if let picker = picker {
                            liveVC.livePicker = picker
                        }
                        self.present(liveVC, animated: false)
                    }
                } catch {
                    print(error, "error of decoding live picker")
                }
            }
        }
    }
    
    @IBAction func startGame() {
        if let livePicker = livePicker, let pickerID = livePicker.pickerID {
            FirebaseManager.shared.startLivePick(livePickerID: pickerID, status: "voting") {
                result in
                switch result {
                case .success(let success):
                    print(success)
                case .failure(let error):
                    print(error, "error of updating status to gaming")
                }
            }
        }
    }
    
    @IBAction func leave() {
        let alert = UIAlertController(title: "是否確定離開?", message: "", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        alert.addAction(UIAlertAction(title: "確認", style: .default) { alert in
            self.confirmToleave()
        })
        present(alert, animated: true)
    }
    
    func confirmToleave() {
        if let livePicker = livePicker, let pickerID = livePicker.pickerID {
            FirebaseManager.shared.leaveLiveRoom(pickerID: pickerID) { result in
                switch result {
                case .success(let success):
                    print(success)
                case .failure(let error):
                    print(error, "error of deleting attendee")
                }
                self.dismiss(animated: true)
            }
        }
    }
}

// MARK: CollectionView Delegate FlowLayout
extension WaitingRoomViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        CGSize(width: SPConstant.screenWidth * 0.25, height: SPConstant.screenHeight * 0.2)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
    }
}
