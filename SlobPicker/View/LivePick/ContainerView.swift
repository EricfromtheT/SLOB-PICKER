//
//  ContainerView.swift
//  SlobPicker
//
//  Created by 孔令傑 on 2022/11/10.
//

import UIKit

class ContainerView: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        if let nib = Bundle.main.loadNibNamed("RoomIDInputView", owner: self),
           let nibView = nib.first as? RoomIDInputView {
            nibView.frame = bounds
            nibView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            addSubview(nibView)
        }
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        if let nib = Bundle.main.loadNibNamed("RoomIDInputView", owner: self),
           let nibView = nib.first as? RoomIDInputView {
            nibView.frame = bounds
            nibView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            addSubview(nibView)
        }
    }
}
