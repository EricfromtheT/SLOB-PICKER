//
//  RoomIDInputView.swift
//  SlobPicker
//
//  Created by 孔令傑 on 2022/11/10.
//

import UIKit

class RoomIDInputView: UIView {
    @IBOutlet weak var inputTextField: UITextField! {
        didSet {
            inputTextField.delegate = self
        }
    }
    @IBOutlet weak var confirmButton: UIButton!
    var completion: ((String) -> ())?
}

extension RoomIDInputView: UITextFieldDelegate {
    func textFieldDidEndEditing(_ textField: UITextField) {
        if let content = textField.text {
            completion?(content)
        }
    }
}
