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
            pickTableView.dataSource = self
            pickTableView.delegate = self
        }
    }
    private enum PickType {
        case imageType
        case textType
    }
    
    private var type: PickType? = .imageType
    var options: [String]? = [
        "https://api.appworks-school.tw/assets/201807202157/0.jpg",
        "https://api.appworks-school.tw/assets/201807202157/1.jpg",
        "https://api.appworks-school.tw/assets/201807202157/0.jpg",
        "https://api.appworks-school.tw/assets/201807202157/1.jpg"
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
}

extension PickViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let row = indexPath.row
        switch row {
        case 0:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "\(TitleCell.self)", for: indexPath)
                    as? TitleCell else {
                fatalError("ERROR: TitleCell cannot be dequeued")
            }
            cell.configure()
            return cell
        case 1:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "\(ChooseCell.self)", for: indexPath)
                    as? ChooseCell else {
                fatalError("ERROR: ChooseCell cannot be dequeued")
            }
            guard let options = options else { fatalError("Options array is nil") }
            switch type {
            case .textType:
                cell.layoutWithTextType(optionsString: options)
                return cell
            case .imageType:
                cell.layoutWithImageType(optionsURLString: options)
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
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        3
    }
}

extension PickViewController: UITableViewDelegate {
}
