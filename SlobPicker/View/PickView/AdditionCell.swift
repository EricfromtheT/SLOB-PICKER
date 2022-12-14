//
//  AdditionCell.swift
//  SlobPicker
//
//  Created by 孔令傑 on 2022/10/31.
//

import UIKit

class AdditionCell: UITableViewCell {
    @IBOutlet weak var additionTextField: UITextField! {
        didSet {
            additionTextField.delegate = self
        }
    }
    var completion: ((String) -> ())?
    
    func configure() {
    }
}

extension AdditionCell: UITextFieldDelegate {
//    func textFieldDidEndEditing(_ textField: UITextField) {
//        if let text = textField.text {
//            completion?(text)
//        }
//    }
    
    func textFieldDidChangeSelection(_ textField: UITextField) {
        if let text = textField.text {
            completion?(text)
        }
    }
}
