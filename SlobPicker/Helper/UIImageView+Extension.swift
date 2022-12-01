//
//  UIImageView+Extension.swift
//  SlobPicker
//
//  Created by 孔令傑 on 2022/12/1.
//

import UIKit

extension UIImageView {
    
    func applyshadowWithCorner(containerView: UIView, cornerRadious: CGFloat) {
        containerView.layer.shadowColor = UIColor.gray.cgColor
        containerView.layer.shadowOpacity = 0.7
        containerView.layer.shadowOffset = CGSize(width: 0, height: 5)
        containerView.layer.shadowRadius = 2
        containerView.layer.cornerRadius = cornerRadious
        containerView.layer.shadowPath = UIBezierPath(roundedRect: CGRect(x: 0,
                                                                          y: 0,
                                                                          width: containerView.bounds.width+1,
                                                                          height: containerView.bounds.height),
                                                      cornerRadius: cornerRadious).cgPath
        self.clipsToBounds = true
        self.layer.cornerRadius = cornerRadious
    }
}
