//
//  PickerEditorViewController.swift
//  SlobPicker
//
//  Created by 孔令傑 on 2022/11/2.
//

import UIKit
import PhotosUI
import ProgressHUD

class PickerEditorViewController: UIViewController {
    @IBOutlet weak var editorTableView: UITableView! {
        didSet {
            editorTableView.dataSource = self
            guard let uuid = uuid else { fatalError("nil uuid") }
            let userGroupsRef = FirebaseManager.FirebaseCollectionRef.usersGroup(userID: uuid).ref
            FirebaseManager.shared.getDocuments(userGroupsRef) { (groupInfos: [GroupInfo]) in
                self.groupInfos = groupInfos
                self.editorTableView.reloadRows(at: [IndexPath(row: 2, section: 0)],
                                                with: .none)
            }
        }
    }
    private var willBeUploadedImages: [UIImage]? = []
    private var willBeUploadedStrings: [String]? = []
    private var imagesDict: [Int: UIImage?] = [:]
    private var stringsDict: [Int: String?] = [:]
    
    private var inputTitle: String?
    private var inputDp: String?
    private var urlStrings: [String]? = []
    private var mode: PickerType = .textType
    private var target: PrivacyMode?
    let uuid = FirebaseManager.auth.currentUser?.uid
    let userID = UserDefaults.standard.string(forKey: UserInfo.userIDKey)
    let userName = UserDefaults.standard.string(forKey: UserInfo.userNameKey)
    let group = DispatchGroup()
    let semaphore = DispatchSemaphore(value: 0)
    
    // Image mode properties
    var imageUploadCompletely: ((String, UIImage, Int) -> Void)?
    var clickIndex: Int?
    
    // others' properties
    var groupInfos: [GroupInfo] = []
    var selectedGroupIndex: Int?
    
    // MARK: Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpNavigation()
        ProgressHUD.animationType = .lineScaling
        navigationItem.title = "編輯新picker"
    }
    
    func setUpNavigation() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "發布", style: .done, target: self, action: #selector(uploadContent))
    }
    
    @objc func uploadContent() {
        if inputTitle == nil || inputTitle == "" {
            let alert = UIAlertController(title: "請填入主題",
                                          message: "picker必須包含主題",
                                          preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "好的",
                                          style: .cancel))
            present(alert, animated: true)
            return
        }
        if target == nil {
            let alert = UIAlertController(title: "請選擇對象",
                                          message: nil,
                                          preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "好的",
                                          style: .cancel))
            present(alert, animated: true)
            return
        }
        if target == .forPrivate && selectedGroupIndex == nil {
            let alert = UIAlertController(title: "請選擇目標群組",
                                          message: nil,
                                          preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "好的",
                                          style: .cancel))
            present(alert, animated: true)
            return
        }
        
        ProgressHUD.show()
        for index in 0...3 {
            if let image = imagesDict[index], let image = image {
                willBeUploadedImages?.append(image)
            }
        }
        if mode == .imageType, willBeUploadedImages?.count == 0 {
            let alert = UIAlertController(title: "選項不足",
                                          message: "請至少新增一選項",
                                          preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "好的",
                                          style: .cancel))
            present(alert, animated: true)
            ProgressHUD.dismiss()
            return
        }
        guard let data = willBeUploadedImages else { fatalError("UIImages have not been found") }
        for image in data {
            // transform image file type
            if let uploadData = image.jpegData(compressionQuality: 0) {
                // Deal with png file uploading
                let uniqueString = UUID().uuidString
                group.enter()
                let dataRef = FirebaseManager.shared.storageRef.child("\(uniqueString).jpeg")
                dataRef.putData(uploadData) { data, error in
                    if let error = error {
                        print(error, "ERROR for uploading data to firebase storage")
                    } else {
                        dataRef.downloadURL { url, error in
                            guard let downloadURL = url else {
                                print(error, "ERROR: URL uploading issue")
                                return
                            }
                            self.urlStrings?.append(downloadURL.absoluteString)
                            self.group.leave()
                        }
                    }
                }
            }
        }
        group.notify(queue: DispatchQueue.main) {
            self.publishPicker()
        }
    }
    
    func publishPicker() {
        for index in 0...3 {
            if let string = stringsDict[index], let string = string {
                willBeUploadedStrings?.append(string)
            }
        }
        if mode == .textType, willBeUploadedStrings?.count == 0 {
            let alert = UIAlertController(title: "選項不足",
                                          message: "請至少新增一選項",
                                          preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "好的",
                                          style: .cancel))
            present(alert, animated: true)
            ProgressHUD.dismiss()
            return
        }
        if let title = inputTitle, let urls = urlStrings, let strings = willBeUploadedStrings {
            var contents: [String] = []
            var type = 0
            if mode == .textType {
                contents = strings.filter { string in
                    !string.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                }
            } else {
                type = 1
                contents = urls
            }
            guard let uuid = uuid, let userID = userID, let userName = userName
            else { fatalError("user info is nil") }
            switch target {
            case .forPrivate:
                let pickerRef = FirebaseManager.FirebaseCollectionRef.pickers(type: .forPrivate).ref.document()
                guard let index = selectedGroupIndex else {
                    print("groupindex is nil")
                    return }
                var privatePicker = Picker(id: pickerRef.documentID,
                                           title: title,
                                           description: inputDp ?? "",
                                           type: type,
                                           contents: contents,
                                           createdTime: Date.dateManager.millisecondsSince1970,
                                           authorID: userID,
                                           authorName: userName,
                                           authorUUID: uuid,
                                           groupID: groupInfos[index].groupID,
                                           groupName: groupInfos[index].groupName)
                FirebaseManager.shared.updateGroupPickersID(groupID: groupInfos[index].groupID,
                                                            pickersID: pickerRef.documentID)
                let groupRef = FirebaseManager.FirebaseCollectionRef.groups.ref.document(groupInfos[index].groupID)
                FirebaseManager.shared.getDocument(groupRef) { (groupInfo: Group?) in
                    if let groupInfo = groupInfo {
                        privatePicker.membersIDs = groupInfo.members
                    }
                    FirebaseManager.shared.setData(privatePicker, at: pickerRef) {
                        DispatchQueue.main.async {
                            ProgressHUD.dismiss()
                            NotificationCenter.default.post(name: NSNotification.Name("private"), object: self)
                            self.navigationController?.popToRootViewController(animated: true)
                        }
                    }
                }
            case .forPublic:
                let pickerRef = FirebaseManager.FirebaseCollectionRef.pickers(type: .forPublic).ref.document()
                let publicPicker = Picker(id: pickerRef.documentID,
                                          title: title,
                                          description: inputDp ?? "",
                                          type: type,
                                          contents: contents,
                                          createdTime: Date.dateManager.millisecondsSince1970,
                                          authorID: userID,
                                          authorName: userName,
                                          authorUUID: uuid,
                                          likedCount: 0,
                                          likedIDs: [],
                                          pickedCount: 0,
                                          pickedIDs: [])
                FirebaseManager.shared.setData(publicPicker, at: pickerRef) {
                    DispatchQueue.main.async {
                        ProgressHUD.dismiss()
                        NotificationCenter.default.post(name: NSNotification.Name("public"), object: self)
                        self.navigationController?.popToRootViewController(animated: true)
                    }
                }
            case .forLive:
                let random = String(Int.random(in: 100000...999999))
                let livePickerRef = FirebaseManager.FirebaseCollectionRef.pickers(type: .forLive).ref.document()
                var livePicker = LivePicker(accessCode: random,
                                            authorID: userID,
                                            status: "waiting",
                                            pickerID: livePickerRef.documentID,
                                            contents: contents,
                                            title: title,
                                            description: inputDp ?? "",
                                            type: type)
                FirebaseManager.shared.setData(livePicker, at: livePickerRef) {
                    goToLiveWaitingRoom(roomID: random)
                }
            case .none:
                break
            }
        }
    }
    
    func goToLiveWaitingRoom(roomID: String) {
        var picker: LivePicker?
        var userInfo: User?
        let livePickQuery = FirebaseManager.FirebaseCollectionRef.pickers(type: .forLive).ref.whereField("access_code", isEqualTo: roomID).whereField("status", isEqualTo: "waiting")
        FirebaseManager.shared.getDocuments(livePickQuery) { (livePicker: [LivePicker]) in
            if livePicker.isEmpty {
                let alert = UIAlertController(title: "No this Room",
                                              message: "No room with this ID",
                                              preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK",
                                              style: .cancel))
                self.present(alert, animated: true)
            } else {
                picker = livePicker[0]
            }
            guard let userID = UserDefaults.standard.string(forKey: UserInfo.userIDKey)
            else {
                return print("user id is not in user default")
            }
            let userQuery = FirebaseManager.FirebaseCollectionRef.users.ref.whereField("user_id", isEqualTo: userID)
            FirebaseManager.shared.getDocuments(userQuery) { (users: [User]) in
                userInfo = users[0]
                if let picker = picker, let pickerID = picker.pickerID,
                   let userInfo = userInfo {
                    let attendeeRef = FirebaseManager.FirebaseCollectionRef
                        .livePickAttendees(pickerID: pickerID).ref.document(userID)
                    FirebaseManager.shared.setData([
                        "attend_time": Date.dateManager.millisecondsSince1970,
                        "user_id": userID,
                        "profile_url": userInfo.profileURL
                    ], at: attendeeRef) {
                        let storyboard = UIStoryboard.interaction
                        guard let waitingVC = storyboard
                            .instantiateViewController(withIdentifier: "\(WaitingRoomViewController.self)")
                                as? WaitingRoomViewController else {
                            fatalError("error cannot instantiate WaitingRoomViewController")
                        }
                        waitingVC.livePicker = picker
                        waitingVC.modalTransitionStyle = .crossDissolve
                        waitingVC.modalPresentationStyle = .fullScreen
                        self.present(waitingVC, animated: true)
                        self.navigationController?.popViewController(animated: true)
                    }
                }
            }
        }
        ProgressHUD.dismiss()
    }
}
// MARK: TableViewDataSource
extension PickerEditorViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let row = indexPath.row
        if row == 0 {
            guard let cell = tableView.dequeueReusableCell(withIdentifier:
                                                            "\(TitleInputCell.self)",
                                                           for: indexPath) as? TitleInputCell else {
                fatalError("ERROR: TitleInputCell broke")
            }
            cell.delegate = self
            cell.configure()
            return cell
            
        } else if row == 1 {
            switch mode {
            case .textType:
                self.imagesDict = [:]
                guard let cell = tableView.dequeueReusableCell(withIdentifier:
                                                                "\(TextOptionsCell.self)",
                                                               for: indexPath)
                        as? TextOptionsCell else {
                    fatalError("ERROR: TextOptionsCell broke")
                }
                cell.configure()
                cell.completion = { content, index in
                    self.stringsDict.updateValue(content, forKey: index)
                }
                return cell
            case .imageType:
                self.stringsDict = [:]
                guard let cell = tableView
                    .dequeueReusableCell(withIdentifier: "\(ImageOptionsCell.self)",
                                         for: indexPath)
                        as? ImageOptionsCell else {
                    fatalError("ERROR: ImageOptionsCell broke")
                }
                cell.deleteCompletion = { index in
                    self.imagesDict.updateValue(nil, forKey: index)
                    cell.imageNameLabels[index].text = "請上傳照片"
                }
                cell.configure(superVC: self)
                return cell
            }
            
        } else {
            guard let cell = tableView.dequeueReusableCell(withIdentifier:
                                                            "\(TargetSettingCell.self)",
                                                           for: indexPath)
                    as? TargetSettingCell else {
                fatalError("ERROR: TargetSettingCell broke")
            }
            let names = groupInfos.map {
                $0.groupName
            }
            cell.setUpGroup(groups: names)
            cell.setUpTarget()
            cell.targetCompletion = { index in
                if index == 1 {
                    cell.groupBgView.isHidden = false
                    self.target = .forPrivate
                } else if index == 0 {
                    cell.groupBgView.isHidden = true
                    self.target = .forPublic
                } else {
                    cell.groupBgView.isHidden = true
                    self.target = .forLive
                }
            }
            cell.groupCompletion = { index in
                self.selectedGroupIndex = index
            }
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        3
    }
}

// MARK: TitleInputDelegate
extension PickerEditorViewController: TitleInputDelegate {
    func segmentModeHasChanged(mode: PickerType) {
        self.mode = mode
        editorTableView.reloadRows(at: [IndexPath(row: 1, section: 0)],
                                   with: .automatic)
    }
    
    func titleHasChanged(title: String) {
        self.inputTitle = title
    }
    
    func dpHasChanged(description: String) {
        self.inputDp = description
    }
}

// MARK: PHPickerViewControllerDelegate
extension PickerEditorViewController: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        let result = results.first
        let itemProvider = result?.itemProvider
        if let itemProvider = itemProvider, itemProvider.canLoadObject(ofClass: UIImage.self) {
            itemProvider.loadObject(ofClass: UIImage.self) { [weak self] (image, error) in
                DispatchQueue.main.async {
                    guard let image = image as? UIImage, let self = self else {
                        print("=========")
                        print(error ?? "no error")
                        return }
                    if let filename = itemProvider.suggestedName, let index = self.clickIndex {
                        self.imagesDict.updateValue(image, forKey: index)
                        self.imageUploadCompletely?(filename, image, index)
                    }
                }
            }
        }
    }
}
