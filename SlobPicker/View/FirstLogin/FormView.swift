//
//  FormView.swift
//  SlobPicker
//
//  Created by 孔令傑 on 2022/11/22.
//

import UIKit
import PhotosUI
import ProgressHUD

class FormView: UIView {
    @IBOutlet weak var profileImage: UIImageView!
    @IBOutlet weak var imageSettingButton: UIButton!
    @IBOutlet weak var idTextField: UITextField! {
        didSet {
            idTextField.delegate = self
        }
    }
    @IBOutlet weak var nickNameTextField: UITextField! {
        didSet {
            nickNameTextField.delegate = self
        }
    }
    @IBOutlet weak var alertLabel: UILabel!
    weak var superVC: NewUserViewController?
    var idCompletion: ((String) -> Void)?
    var nickNameCompletion: ((String) -> Void)?
    
    func configure(superVC: NewUserViewController) {
        self.superVC = superVC
        profileImage.layer.cornerRadius = profileImage.bounds.width / 2
        idTextField.attributedPlaceholder = NSAttributedString(string: "設定ID(必填)", attributes: [NSAttributedString.Key.foregroundColor: UIColor.lightGray])
        nickNameTextField.attributedPlaceholder = NSAttributedString(string: "設定暱稱(必填)", attributes: [NSAttributedString.Key.foregroundColor: UIColor.lightGray])
        superVC.pickImageCompletion = { image in
            self.profileImage.image = image
        }
        superVC.searchCompletion = { status in
            if status == "can" {
                self.alertLabel.text = "可以使用此ID"
                self.alertLabel.textColor = .green
            } else if status == "cannot" {
                self.alertLabel.text = "ID已被使用"
                self.alertLabel.textColor = .red
            } else if status == "empty" {
                self.alertLabel.text = "ID不可為空"
                self.alertLabel.textColor = .red
            } else {
                self.alertLabel.text = "ID只可包含數字及英文字母"
                self.alertLabel.textColor = .red
            }
        }
    }
    
    @IBAction func pickPicture() {
        var configuration = PHPickerConfiguration()
        configuration.filter = .images
        let picker = PHPickerViewController(configuration: configuration)
        guard let superVC = superVC else {
            print("ERROR: vc has not been import")
            return }
        picker.delegate = superVC
        superVC.present(picker, animated: true)
    }
}

extension FormView: UITextFieldDelegate {
    func textFieldDidChangeSelection(_ textField: UITextField) {
        if let content = textField.text {
            if textField == idTextField {
                idCompletion?(content)
            } else if textField == nickNameTextField {
                nickNameCompletion?(content)
            }
        }
    }
}

