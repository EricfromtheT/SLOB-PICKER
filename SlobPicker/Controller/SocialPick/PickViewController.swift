//
//  PickViewController.swift
//  SlobPicker
//
//  Created by 孔令傑 on 2022/10/30.
//

import UIKit
import ProgressHUD

class PickViewController: UIViewController {
    @IBOutlet weak var pickTableView: UITableView! {
        didSet {
            pickTableView.delegate = self
            pickTableView.dataSource = self
        }
    }
    
    var pickerID: String?
    var pickInfo: Picker? {
        didSet {
            self.type = pickInfo?.type == 0 ? .textType : .imageType
            self.pickerID = pickInfo?.id
        }
    }
    private var type: PickerType?
    private var chosenIndex: Int?
    private var additionalComment: String?
    var mode: PrivacyMode = .forPublic
    var publicCompletion: (() -> Void)?
    let uuid = FirebaseManager.auth.currentUser?.uid
    let userID = UserDefaults.standard.string(forKey: UserInfo.userIDKey)
    
    // MARK: Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        configureNavigation()
        ProgressHUD.animationType = .lineScaling
        navigationItem.title = "投票"
    }
    
    func configureNavigation() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Pick", style: .done, target: self, action: #selector(donePick))
    }
    
    
    // confirm your selecting result
    @objc func donePick() {
        ProgressHUD.show()
        guard let uuid = uuid, let userID = userID else { fatalError("uuid in keychain is nil") }
        var resultRef: FirebaseManager.DocumentRef?
        if let chosenIndex = chosenIndex, let pickerID = pickerID {
            let result = PickResult(choice: chosenIndex, createdTime: Date.dateManager.millisecondsSince1970, userUUID: uuid)
            switch mode {
            case .forPrivate:
                resultRef = FirebaseManager.FirebaseCollectionRef
                    .pickerResults(type: mode, pickerID: pickerID).ref.document(uuid)
            case .forPublic:
                publicCompletion?()
                resultRef = FirebaseManager.FirebaseCollectionRef
                    .pickerResults(type: mode, pickerID: pickerID).ref.document(uuid)
                FirebaseManager.shared.pickPicker(pickerID: pickerID)
            default:
                return print("something wrong with pick result uploading")
            }
            if let resultRef = resultRef {
                FirebaseManager.shared.setData(result, at: resultRef) {}
                if let comment = additionalComment, !comment.isEmpty {
                    let commentInfo = Comment(userUUID: uuid,
                                              userID: userID,
                                              type: 0,
                                              comment: comment,
                                              createdTime: Date.dateManager.millisecondsSince1970)
                    let commentRef = FirebaseManager.FirebaseCollectionRef
                        .pickerComments(type: mode, pickerID: pickerID).ref.document(uuid)
                    FirebaseManager.shared.setData(commentInfo, at: commentRef) {}
                }
            }
        } else {
            let alert = UIAlertController(title: "vote", message: "you haven't vote", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .cancel))
            present(alert, animated: true)
        }
        navigationController?.popToRootViewController(animated: true)
        ProgressHUD.dismiss()
    }
}

// MARK: TableView Datasource
extension PickViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let pickInfo = pickInfo else { fatalError("pickInfo is nil") }
        let row = indexPath.row
        switch row {
        case 0:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "\(TitleCell.self)", for: indexPath)
                    as? TitleCell else {
                fatalError("ERROR: TitleCell cannot be dequeued")
            }
            cell.configure(data: pickInfo)
            return cell
        case 1:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "\(ChooseCell.self)", for: indexPath)
                    as? ChooseCell else {
                fatalError("ERROR: ChooseCell cannot be dequeued")
            }
            switch type {
            case .textType:
                cell.layoutWithTextType(optionsString: pickInfo.contents)
                cell.completion = { [weak self] index in
                    self?.chosenIndex = index
                }
                return cell
            case .imageType:
                cell.layoutWithImageType(optionsURLString: pickInfo.contents)
                cell.completion = { [weak self] index in
                    self?.chosenIndex = index
                }
                return cell
            case .none:
                fatalError("ERROR: Pick type crashed")
            }
        default:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "\(AdditionCell.self)", for: indexPath)
                    as? AdditionCell else {
                fatalError("ERROR: AdditionCell cannot be dequeued")
            }
            cell.configure()
            cell.completion = { [weak self] text in
                self?.additionalComment = text
            }
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        pickInfo == nil ? 0 : 3
    }
}

// MARK: TableView Delegate
extension PickViewController: UITableViewDelegate {
}
