//
//  UIImage+Extension.swift
//  SlobPicker
//
//  Created by 孔令傑 on 2022/11/16.
//

import UIKit


enum assetImage: String {
    case Icons_24px_CleanAll
    case image
    case deleteButton
    case rainbow
    case user
}

extension UIImage {
    static func asset(_ asset: assetImage) -> UIImage? {
        return UIImage(named: asset.rawValue)
    }
}
