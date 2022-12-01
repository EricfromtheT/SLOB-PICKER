//
//  UIColor+Extension.swift
//  SlobPicker
//
//  Created by 孔令傑 on 2022/11/14.
//

import UIKit

enum assetColor: String {
    case card1left
    case card1right
    case card2left
    case card2right
    case card3left
    case card3right
    case card4left
    case card4right
    case navigationbar
    case navigationbar2
    case livePick
    case livePickBG
    case choose
    case chose
    case result1
    case result2
    case result3
    case result4
}

extension UIColor {
    static func asset(_ asset: assetColor) -> UIColor? {
        return UIColor(named: asset.rawValue)
    }
}
