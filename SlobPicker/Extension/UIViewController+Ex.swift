//
//  UIViewController_Ex.swift
//  SlobPicker
//
//  Created by 孔令傑 on 2023/2/10.
//

import UIKit

extension UIViewController {
    func showAlert(title: String, message: String?) {
        let alert = UIAlertController(title: title,
                                      message: message,
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "好的",
                                      style: .cancel))
        self.present(alert, animated: true)
    }
}
