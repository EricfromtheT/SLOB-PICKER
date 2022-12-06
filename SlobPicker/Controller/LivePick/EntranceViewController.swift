//
//  LivePickViewController.swift
//  SlobPicker
//
//  Created by 孔令傑 on 2022/11/10.
//

import UIKit
import Lottie

class EntranceViewController: UIViewController {
    @IBOutlet weak var roomIDTextField: UITextField! {
        didSet {
            roomIDTextField.delegate = self
        }
    }
    @IBOutlet weak var entryButton: UIButton!
    @IBOutlet weak var cancelImageView: UIImageView! {
        didSet {
            cancelImageView.isUserInteractionEnabled = true
            let gesture = UITapGestureRecognizer(target: self, action: #selector(cancel))
            cancelImageView.addGestureRecognizer(gesture)
        }
    }
    @IBOutlet weak var buttonShadow: UIView!
    var roomID: String?
    var animationView: LottieAnimationView?
    let textFieldWidth = 300
    let entryButtonWidth = 250
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "即時pick"
        setUpTextField()
        addBGAnimation()
        setUpEntryButton()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        customNav()
        animationView?.play()
        entryButton.isEnabled = true
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        animateElement()
    }
    
    func customNav() {
        let appearance = UINavigationBarAppearance()
        //cancel navigationbar seperator
        appearance.shadowColor = nil
        appearance.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white]
        navigationItem.titleView?.tintColor = .white
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
    }
    
    func setUpTextField() {
        roomIDTextField.attributedPlaceholder = NSAttributedString(string: "請輸入房號", attributes: [NSAttributedString.Key.foregroundColor: UIColor.lightGray])
        roomIDTextField.frame = CGRect(x: (Int(SPConstant.screenWidth) - textFieldWidth) / 2, y: Int(SPConstant.screenHeight), width: 0, height: 40)
    }
    
    func setUpEntryButton() {
        entryButton.frame = CGRect(x: (Int(SPConstant.screenWidth) - entryButtonWidth) / 2, y: Int(SPConstant.screenHeight), width: entryButtonWidth, height: 50)
        entryButton.layer.cornerRadius = 10
        buttonShadow.layer.cornerRadius = 10
    }
    
    func animateElement() {
        UIView.animate(withDuration: 0.4) {
            self.roomIDTextField.frame = CGRect(x: (Int(SPConstant.screenWidth) - self.textFieldWidth) / 2, y: Int(SPConstant.screenHeight) / 2 - 100, width: self.textFieldWidth, height: 40)
            self.entryButton.frame = CGRect(x: (Int(SPConstant.screenWidth) - self.entryButtonWidth) / 2, y: Int(SPConstant.screenHeight) / 2 + 100, width: self.entryButtonWidth, height: 50)
            self.view.layoutIfNeeded()
        }
    }
    
    func addBGAnimation() {
        animationView = .init(name: "gameRoom")
        animationView?.loopMode = .loop
        animationView?.frame = CGRect(x: 0, y: -100, width: SPConstant.screenWidth, height: SPConstant.screenHeight + 100)
        animationView?.contentMode = .scaleAspectFill
        animationView?.animationSpeed = 1
        view.addSubview(animationView!)
        view.sendSubviewToBack(animationView!)
    }
    
    @objc func cancel() {
        dismiss(animated: true)
    }
    
    @IBAction func confirm() {
        //取得該房號所屬的picker資料，提取出pickerID後索取此議題目前的參加者，進行Waiting room第一次的畫面渲染
        UIView.animate(withDuration: 0.1) {
            self.entryButton.transform = CGAffineTransform(translationX: 0, y: 5)
        } completion: { _ in
            self.entryButton.transform = CGAffineTransform(translationX: 0, y: 0)
        }
        var picker: LivePicker?
        var userInfo: User?
        if let roomID = roomID {
            FirebaseManager.shared.fetchLivePicker(roomID: roomID) { result in
                switch result {
                case .success(let livePicker):
                    picker = livePicker
                    self.entryButton.isEnabled = false
                case .failure(let error):
                    if error as? UserError == .nodata {
                        let alert = UIAlertController(title: "No this Room",
                                                      message: "No room with this ID",
                                                      preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: "OK", style: .cancel))
                        self.present(alert, animated: true)
                        return
                    } else {
                        print(error, "error of getting LivePicker")
                    }
                }
                guard let userID = UserDefaults.standard.string(forKey: UserInfo.userIDKey)
                else {
                    return print("user id is not in user default")
                }
                FirebaseManager.shared.searchUser(userID: userID) {
                    result in
                    switch result {
                    case .success(let user):
                        userInfo = user
                    case .failure(let error):
                        return print(error, "error of getting userdata from firebase")
                    }
                    if let picker = picker,
                        let pickerID = picker.pickerID,
                        let userInfo = userInfo {
                        FirebaseManager.shared.attendLivePick(livePickerID: pickerID, user: userInfo) {
                            result in
                            switch result {
                            case .success( _):
                                let storyboard = UIStoryboard(name: "Interaction", bundle: nil)
                                guard let waitingVC = storyboard
                                    .instantiateViewController(withIdentifier: "\(WaitingRoomViewController.self)")
                                        as? WaitingRoomViewController else {
                                    fatalError("error cannot instantiate WaitingRoomViewController")
                                }
                                waitingVC.livePicker = picker
                                waitingVC.modalPresentationStyle = .fullScreen
                                waitingVC.modalTransitionStyle = .crossDissolve
                                self.present(waitingVC, animated: true)
                                
                            case .failure(let error):
                                print(error, "error of attending a live pick")
                            }
                        }
                    }
                }
            }
        }
    }
}

extension EntranceViewController: UITextFieldDelegate {
    func textFieldDidChangeSelection(_ textField: UITextField) {
        if let content = textField.text {
            self.roomID = content
        }
    }
}
