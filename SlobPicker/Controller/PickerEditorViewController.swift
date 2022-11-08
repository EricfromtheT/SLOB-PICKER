//
//  PickerEditorViewController.swift
//  SlobPicker
//
//  Created by 孔令傑 on 2022/11/2.
//

import UIKit
import PhotosUI

class PickerEditorViewController: UIViewController {
    @IBOutlet weak var editorTableView: UITableView! {
        didSet {
            editorTableView.dataSource = self
            FirebaseManager.shared.fetchUserCurrentGroups { result in
                switch result {
                case .success(let groupInfos):
                    self.groupInfos = groupInfos
                    self.editorTableView.reloadRows(at: [IndexPath(row: 2, section: 0)], with: .none)
                case .failure(let error):
                    print(error, "ERROR of getting user's current groups")
                }
            }
        }
    }
    // TODO: can be refactor to struct
    private var willBeUploadedImages: [UIImage]? = []
    private var willBeUploadedStrings: [String]? = []
    
    private var inputTitle: String?
    private var inputDp: String?
    private var urlStrings: [String]? = []
    private var mode: PickerType = .textType
    let group = DispatchGroup()
    let semaphore = DispatchSemaphore(value: 0)
    
    // Image mode properties
    var imageUploadCompletely: ((String, Int) -> Void)?
    var clickIndex: Int?
    
    // others' properties
    var groupInfos: [GroupInfo] = []
    var selectedGroupIndex: Int?
    
    // MARK: Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpNavigation()
    }
    
    func setUpNavigation() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Publish", style: .done, target: self, action: #selector(uploadImages))
    }
    
    @objc func uploadImages() {
        guard let data = willBeUploadedImages else { fatalError("UIImages have not been found") }
        for image in data {
            // transform image file type
            if let uploadData = image.jpegData(compressionQuality: 0.001) {
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
                            // TODO: showing progressing indicator to users til uploading ends
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
        if let title = inputTitle, let urls = urlStrings, let strings = willBeUploadedStrings, let index = selectedGroupIndex {
            var contents: [String] = []
            var type = 0
            var membersID: [String] = []
            if mode == .textType {
                contents = strings.filter { string in
                    !string.isEmpty
                }
            } else {
                type = 1
                contents = urls
            }
            print(groupInfos[index].groupID) // 確定有東西
            // fetch group's member list
            // 1
            var privatePicker = Picker(title: title, description: inputDp ?? "", type: type, contents: contents, authorID: FakeUserInfo.shared.userID, authorName: FakeUserInfo.shared.userName, group: groupInfos[index].groupID)
            FirebaseManager.shared.fetchGroupInfo(groupID: groupInfos[index].groupID, completion: {
                result in
                print("==========")
                switch result {
                case .success(let groupInfo):
                    membersID = groupInfo.members
                    privatePicker.membersIDs = membersID
                    self.publish(picker: &privatePicker)
                case .failure(let error):
                    print(error, "拿單一群組資料有問題")
                }
            })
            

        }
    }
    
    func publish(picker: inout Picker) {
        FirebaseManager.shared.publishPrivatePicker(pick: &picker) { result in
            switch result {
            case .success(let success):
                print(success)
            case .failure(let error):
                print(error, "ERROR")
            }
            DispatchQueue.main.async {
                self.navigationController?.popToRootViewController(animated: true)
            }
        }
    }
}
// MARK: TableViewDataSource
extension PickerEditorViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let row = indexPath.row
        if row == 0 {
            guard let cell = tableView.dequeueReusableCell(withIdentifier:
                                                            "\(TitleInputCell.self)", for: indexPath) as? TitleInputCell else {
                fatalError("ERROR: TitleInputCell broke")
            }
            cell.delegate = self
            cell.configure()
            return cell
            
        } else if row == 1 {
            switch mode {
            case .textType:
                self.willBeUploadedImages = []
                guard let cell = tableView.dequeueReusableCell(withIdentifier:
                                                                "\(TextOptionsCell.self)", for: indexPath) as? TextOptionsCell else {
                    fatalError("ERROR: TextOptionsCell broke")
                }
                cell.configure()
                cell.completion = { content, index in
                    if self.willBeUploadedStrings?.count ?? 0 >= index + 1 {
                        self.willBeUploadedStrings?.remove(at: index)
                    }
                    self.willBeUploadedStrings?.insert(content, at: index)
                }
                return cell
            case .imageType:
                self.willBeUploadedStrings = []
                guard let cell = tableView.dequeueReusableCell(withIdentifier:
                                                                "\(ImageOptionsCell.self)", for: indexPath) as? ImageOptionsCell else {
                    fatalError("ERROR: ImageOptionsCell broke")
                }
//                let names = groupInfos.map {
//                    $0.name
//                }
                cell.configure(superVC: self)
                return cell
            }
            
        } else {
            //TODO: choose group or friends
            guard let cell = tableView.dequeueReusableCell(withIdentifier:
                                                            "\(TargetSettingCell.self)", for: indexPath) as? TargetSettingCell else {
                fatalError("ERROR: TargetSettingCell broke")
            }
            let names = groupInfos.map {
                $0.groupName
            }
            cell.setUp(groups: names)
            cell.completion = { index in
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
        editorTableView.reloadRows(at: [IndexPath(row: 1, section: 0)], with: .automatic)
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
                    // UI updates, images name
                    // TODO: 需要限制圖片上傳順序，按鈕依序開放 or else error
                    if let filename = itemProvider.suggestedName, let index = self.clickIndex {
                        if self.willBeUploadedImages?.count ?? 0 >= index + 1 {
                            self.willBeUploadedImages?.remove(at: index)
                        }
                        self.willBeUploadedImages?.insert(image, at: index)
                        self.imageUploadCompletely?(filename, index)
                    }
                }
            }
        }
    }
}