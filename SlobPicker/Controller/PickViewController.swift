//
//  PickViewController.swift
//  SlobPicker
//
//  Created by 孔令傑 on 2022/10/30.
//

import UIKit

class PickViewController: UIViewController {
    @IBOutlet weak var pickTableView: UITableView! {
        didSet {
            pickTableView.delegate = self
            pickTableView.dataSource = self
        }
    }
    var pickerID: String? {
        didSet {
            guard let pickerID = pickerID else { fatalError("pickerID was wrong") }
            FirebaseManager.shared.fetchPrivatePickInfo(pickerID: pickerID) { [weak self] result in
                switch result {
                case .success(let pickInfo):
                    self?.pickInfo = pickInfo
                    self?.type = pickInfo.type == 0 ? .textType : .imageType
                    self?.pickTableView.reloadData()
                case .failure(let error):
                    print("fetchData.failure: \(error)")
                }
            }
        }
    }
    private var pickInfo: Pick?
    private var type: PickType?
    private var chosenIndex: Int?
    private var additionalComment: String?
    
    // MARK: Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        configureNavigation()
    }
    
    func configureNavigation() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Pick", style: .done, target: self, action: #selector(donePick))
    }
    
    @objc func donePick() {
        if let chosenIndex = chosenIndex, let pickerID = pickerID {
            FirebaseManager.shared.updatePrivateResult(index: chosenIndex, pickerID: pickerID)
            if let comment = additionalComment, comment != "" {
                let commentInfo = Comment(userID: FakeUserInfo.userID, type: 0, contents: comment, createdTime: Date().millisecondsSince1970)
                FirebaseManager.shared.updatePrivateComment(comment: commentInfo, pickerID: pickerID)
            }
        } else {
            let alert = UIAlertController(title: "vote", message: "you haven't vote", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .cancel))
            present(alert, animated: true)
        }
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
