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
    @IBOutlet weak var targetBgView: UIView!
    @IBOutlet weak var groupBgView: UIView!
    let groupDropDown = DropDown()
    let targetDropDown = DropDown()
    var groupCompletion: ((Int) -> Void)?
    var targetCompletion: ((Int) -> Void)?
    
    func setUpGroup(groups: [String]) {
        groupBgView.layer.cornerRadius = 8
        groupBgView.layer.borderWidth = 2
        groupBgView.layer.borderColor = UIColor.asset(.chose)?.cgColor
        groupBgView.isHidden = true
        groupButton.addTarget(self, action: #selector(groupClick), for: .touchUpInside)
        groupDropDown.cornerRadius = 8
        groupDropDown.backgroundColor = .white
        groupDropDown.anchorView = groupBgView
        groupDropDown.width = groupBgView.bounds.width
        groupDropDown.bottomOffset = CGPoint(x: 0, y: 40)
        groupDropDown.dataSource = groups
        groupDropDown.selectionAction = { [unowned self] (index: Int, item: String) in
            groupButton.setTitle(item, for: .normal)
            groupCompletion?(index)
        }
    }
    
    func setUpTarget() {
        targetBgView.layer.cornerRadius = 8
        targetBgView.layer.borderColor = UIColor.asset(.chose)?.cgColor
        targetBgView.layer.borderWidth = 2
        targetButton.addTarget(self, action: #selector(targetClick), for: .touchUpInside)
        targetDropDown.anchorView = targetBgView
        targetDropDown.cornerRadius = 8
        targetDropDown.backgroundColor = .white
        targetDropDown.width = targetBgView.bounds.width
        targetDropDown.bottomOffset = CGPoint(x: 0, y: 40)
        targetDropDown.dataSource = ["公開", "群組", "限時picker"]
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
