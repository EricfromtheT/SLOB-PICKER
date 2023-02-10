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
            textField.layer.borderWidth = 2
            textField.layer.cornerRadius = 5
            textField.layer.borderColor = UIColor.asset(.navigationbar2)?.cgColor
            textField.delegate = self
            textField.tag = idx
        }
    }
}

extension TextOptionsCell: UITextFieldDelegate {
    
    func textFieldDidChangeSelection(_ textField: UITextField) {
        if let content = textField.text {
            self.completion?(content, textField.tag)
        }
    }
}
