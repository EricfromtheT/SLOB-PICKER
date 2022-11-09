//
//  TargetSettingCell.swift
//  SlobPicker
//
//  Created by 孔令傑 on 2022/11/2.
//

import UIKit
import DropDown

class TargetSettingCell: UITableViewCell {
    @IBOutlet weak var groupButton: UIButton!
    @IBOutlet weak var targetButton: UIButton!
    let groupDropDown = DropDown()
    let targetDropDown = DropDown()
    var groupCompletion: ((Int) -> Void)?
    var targetCompletion: ((Int) -> Void)?
    
    func setUpGroup(groups: [String]) {
        groupButton.isHidden = true
        groupButton.addTarget(self, action: #selector(groupClick), for: .touchUpInside)
        groupDropDown.anchorView = groupButton
        groupDropDown.width = 200
        groupDropDown.bottomOffset = CGPoint(x: 0, y: 40)
        groupDropDown.dataSource = groups
        groupDropDown.selectionAction = { [unowned self] (index: Int, item: String) in
            groupButton.setTitle(item, for: .normal)
            groupCompletion?(index)
        }
    }
    
    func setUpTarget() {
        targetButton.addTarget(self, action: #selector(targetClick), for: .touchUpInside)
        targetDropDown.anchorView = targetButton
        targetDropDown.width = 150
        targetDropDown.bottomOffset = CGPoint(x: 0, y: 40)
        targetDropDown.dataSource = ["公開", "群組"]
        targetDropDown.selectionAction = { [unowned self] (index: Int, item: String) in
            targetButton.setTitle(item, for: .normal)
            targetCompletion?(index)
        }
    }
    
    @objc func groupClick() {
        groupDropDown.show()
    }
    
    @objc func targetClick() {
        targetDropDown.show()
    }
    
}
