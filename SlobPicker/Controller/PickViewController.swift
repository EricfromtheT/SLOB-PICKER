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
    var mode: PrivacyMode?
    var publicCompletion: (() -> Void)?
    let uuid = FirebaseManager.auth.currentUser?.uid
    
    // MARK: Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        configureNavigation()
        ProgressHUD.animationType = .lineScaling
    }
    
    func configureNavigation() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Pick", style: .done, target: self, action: #selector(donePick))
    }
    
    // confirm your selecting result
    @objc func donePick() {
        ProgressHUD.show()
        guard let uuid = uuid else { fatalError("uuid in keychain is nil") }
        if let chosenIndex = chosenIndex, let pickerID = pickerID {
            switch mode {
            case .forPrivate:
                FirebaseManager.shared.updatePrivateResult(index: chosenIndex, pickerID: pickerID)
                if let comment = additionalComment, !comment.isEmpty {
                    let commentInfo = Comment(userUUID: uuid, type: 0, comment: comment, createdTime: Date().millisecondsSince1970)
                    FirebaseManager.shared.updatePrivateComment(comment: commentInfo, pickerID: pickerID)
                }
            case .forPublic:
                publicCompletion?()
                FirebaseManager.shared.updatePublicResult(index: chosenIndex, pickerID: pickerID)
                if let comment = additionalComment, !comment.isEmpty {
                    let commentInfo = Comment(userUUID: uuid, type: 0, comment: comment, createdTime: Date().millisecondsSince1970)
                    FirebaseManager.shared.updatePublicComment(comment: commentInfo, pickerID: pickerID)
                }
                FirebaseManager.shared.pickPicker(pickerID: pickerID)
            default:
                print("something wrong with pick result uploading")
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
            cell.additionTextField.delegate = cell
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
