//
//  PickEditorViewController.swift
//  SlobPicker
//
//  Created by 孔令傑 on 2022/11/2.
//

import UIKit
import PhotosUI

class PickEditorViewController: UIViewController {
    @IBOutlet weak var editorTableView: UITableView! {
        didSet {
            editorTableView.dataSource = self
        }
    }
    
    private var willBeUploadedImages: [UIImage]? = []
    private var willBeUploadedStrings: [String]? = []
    private var inputTitle: String?
    private var inputDp: String?
    private var urlStrings: [String]? = []
    private var mode: PickType = .textType
    let group = DispatchGroup()
    
    // Image mode properties
    var imageUploadCompletely: ((String, Int) -> ())?
    var clickIndex: Int?
    
    // MARK: Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpNavigation()
    }
    
    func setUpNavigation() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Publish", style: .done, target: self, action: #selector(publishPicker))
    }
    
    @objc func publishPicker() {
        guard let data = willBeUploadedImages else { fatalError("UIImages have not been found") }
        // TODO: GCD group management
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
            self.packPickerInfo()
        }
    }
    
    func packPickerInfo() {
        if let title = inputTitle, let description = inputDp, let urls = urlStrings,
           let strings = willBeUploadedStrings {
            var contents: [String] = []
            var type = 0
            if mode == .textType {
                contents = strings.filter { string in
                    !string.isEmpty
                }
            } else {
                type = 1
                contents = urls
            }
            var privatePicker = Pick(title: title, description: description, type: type, contents: contents)
            FirebaseManager.shared.publishPrivatePick(pick: &privatePicker, completion: { result in
                switch result {
                case .success(let success):
                    print(success)
                case .failure(let error):
                    print(error, "ERROR")
                }
            })
        }
    }
}
// MARK: TableViewDataSource
extension PickEditorViewController: UITableViewDataSource {
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
                guard let cell = tableView.dequeueReusableCell(withIdentifier:
                                                                "\(ImageOptionsCell.self)", for: indexPath) as? ImageOptionsCell else {
                    fatalError("ERROR: ImageOptionsCell broke")
                }
                cell.configure(superVC: self)
                return cell
            }
            
        } else {
            //TODO: chose group or friends
            guard let cell = tableView.dequeueReusableCell(withIdentifier:
                                                            "\(TargetSettingCell.self)", for: indexPath) as? TargetSettingCell else {
                fatalError("ERROR: TargetSettingCell broke")
            }
            cell.setUp()
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        3
    }
}

// MARK: TitleInputDelegate
extension PickEditorViewController: TitleInputDelegate {
    func segmentModeHasChanged(mode: PickType) {
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
extension PickEditorViewController: PHPickerViewControllerDelegate {
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
