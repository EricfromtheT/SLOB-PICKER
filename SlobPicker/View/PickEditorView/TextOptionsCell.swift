//
//  TextOptionsCell.swift
//  SlobPicker
//
//  Created by 孔令傑 on 2022/11/2.
//

import UIKit

class TextOptionsCell: UITableViewCell {
    @IBOutlet var textFields: [UITextField]!
    var completion: ((String, Int) -> ())?
    
    func configure() {
        for (idx, textField) in textFields.enumerated() {
            textField.delegate = self
            textField.text = nil
            textField.tag = idx
        }
    }
}

extension TextOptionsCell: UITextFieldDelegate {
//    func textFieldDidEndEditing(_ textField: UITextField) {
//        if let content = textField.text {
//            self.completion?(content, textField.tag)
//        }
//    }
    
    func textFieldDidChangeSelection(_ textField: UITextField) {
        if let content = textField.text {
            self.completion?(content, textField.tag)
        }
    }
}
