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
        modeSegment.setTitleTextAttributes([NSAttributedString.Key.foregroundColor : UIColor.white], for: .selected)
        titleTextField.delegate = self
        dpTextView.delegate = self
        dpTextView.layer.cornerRadius = 8
        dpTextView.layer.borderWidth = 1.2
        dpTextView.layer.borderColor = UIColor.asset(.navigationbar2)?.cgColor
        dpTextView.text = "請輸入描述內容"
        dpTextView.textColor = UIColor.lightGray
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
    func textFieldDidChangeSelection(_ textField: UITextField) {
        if let content = textField.text {
            delegate?.titleHasChanged(title: content)
        }
    }
}

extension TitleInputCell: UITextViewDelegate {
    func textViewDidChangeSelection(_ textView: UITextView) {
        if let content = textView.text, content != "請輸入描述內容" {
            delegate?.dpHasChanged(description: content)
        }
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.textColor == UIColor.lightGray {
            textView.text = nil
            textView.textColor = UIColor.black
        }
    }
//    func textViewDidEndEditing(_ textView: UITextView) {
//        if textView.text.isEmpty {
//            textView.text = "請輸入描述內容"
//            textView.textColor = UIColor.lightGray
//        }
//    }
}
