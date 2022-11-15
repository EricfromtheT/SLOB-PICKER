//
//  LivePickViewController.swift
//  SlobPicker
//
//  Created by 孔令傑 on 2022/11/10.
//

import UIKit
import DGElasticPullToRefresh

class EntranceViewController: UIViewController {
    var roomID: String?
    let loadingView = DGElasticPullToRefreshLoadingViewCircle()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "即時pick"
        showRoomIDInputView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let appearance = UINavigationBarAppearance()
        appearance.backgroundColor = UIColor.asset(.navigationbar)
        // cancel navigationbar seperator
        appearance.shadowColor = nil
        appearance.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white]
        navigationItem.titleView?.tintColor = .white
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
    }
    
    func showRoomIDInputView() {
        if let roomView = Bundle.main.loadNibNamed("RoomIDInputView", owner: nil)?.first as? RoomIDInputView {
            view.addSubview(roomView)
            roomView.completion = { content in
                self.roomID = content
            }
            roomView.confirmButton.addTarget(self, action: #selector(confirm), for: .touchUpInside)
            roomView.translatesAutoresizingMaskIntoConstraints = false
            roomView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
            roomView.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
            roomView.widthAnchor.constraint(equalToConstant: SPConstant.screenWidth).isActive = true
            roomView.heightAnchor.constraint(equalToConstant: SPConstant.screenHeight * 0.15).isActive = true
        }
    }
    
    @objc func confirm() {
        // 取得該房號所屬的picker資料，提取出pickerID後索取此議題目前的參加者，進行Waiting room第一次的畫面渲染
        var picker: LivePicker?
        if let roomID = roomID {
            FirebaseManager.shared.fetchLivePicker(roomID: roomID) { result in
                print(result)
                switch result {
                case .success(let livePicker):
                    picker = livePicker
                case .failure(let error):
                    if error as? UserError == .nodata {
                        let alert = UIAlertController(title: "No this Room", message: "No room with this ID", preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: "OK", style: .cancel))
                        self.present(alert, animated: true)
                    } else {
                        print(error, "error of getting LivePicker")
                    }
                }
                if let picker = picker, let pickerID = picker.pickerID {
                    FirebaseManager.shared.attendLivePick(livePickerID: pickerID) {
                        result in
                        switch result {
                        case .success( _):
                            let storyboard = UIStoryboard(name: "Interaction", bundle: nil)
                            guard let waitingVC = storyboard.instantiateViewController(withIdentifier: "\(WaitingRoomViewController.self)") as? WaitingRoomViewController else {
                                fatalError("error cannot instantiate WaitingRoomViewController")
                            }
                            waitingVC.livePicker = picker
                            self.show(waitingVC, sender: self)
                        case .failure(let error):
                            print(error, "error of attending a live pick")
                        }
                    }
                }
            }
        }
    }
}
