//
//  TitleInputCell.swift
//  SlobPicker
//
//  Created by 孔令傑 on 2022/11/2.
//

import UIKit

protocol TitleInputDelegate: AnyObject{
    func segmentModeHasChanged(mode: PickerType)
    
    func titleHasChanged(title: String)
    
    func dpHasChanged(description: String)
}

class TitleInputCell: UITableViewCell {
    @IBOutlet weak var titleTextField: UITextField!
    @IBOutlet weak var dpTextView: UITextView!
    @IBOutlet weak var modeSegment: UISegmentedControl!
    
    weak var delegate: TitleInputDelegate?
    
    func configure() {
        titleTextField.delegate = self
        dpTextView.delegate = self
    }
    
    @IBAction func changeMode(_ sender: UISegmentedControl) {
        let tag = sender .selectedSegmentIndex
        if tag == 0 {
            delegate?.segmentModeHasChanged(mode: PickerType.textType)
        } else {
            delegate?.segmentModeHasChanged(mode: PickerType.imageType)
        }
    }
}

extension TitleInputCell: UITextFieldDelegate {
    func textFieldDidEndEditing(_ textField: UITextField) {
        if let content = textField.text {
            delegate?.titleHasChanged(title: content)
        }
        
    }
}

extension TitleInputCell: UITextViewDelegate {
    func textViewDidEndEditing(_ textView: UITextView) {
        if let content = textView.text {
            delegate?.dpHasChanged(description: content)
        }
    }
}
