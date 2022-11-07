//
//  TargetSettingCell.swift
//  SlobPicker
//
//  Created by 孔令傑 on 2022/11/2.
//

import UIKit
import DropDown

class TargetSettingCell: UITableViewCell {
    @IBOutlet weak var targetButton: UIButton!
    let dropDown = DropDown()
    var completion: ((Int) -> Void)?
    
    func setUp(groups: [String]) {
        targetButton.addTarget(self, action: #selector(click), for: .touchUpInside)
        dropDown.anchorView = targetButton
        dropDown.width = 300
        dropDown.dataSource = groups
        dropDown.selectionAction = { [unowned self] (index: Int, item: String) in
            targetButton.setTitle(item, for: .normal)
            completion?(index)
        }
    }
    
    @objc func click() {
        dropDown.show()
    }
}
