//
//  UIStoryboard+Extension.swift
//  SlobPicker
//
//  Created by 孔令傑 on 2022/12/13.
//

import UIKit

extension UIStoryboard {
    static var main: UIStoryboard {
        return UIStoryboard(name: SBStoryboard.main.rawValue, bundle: nil)
    }
    static var profile: UIStoryboard {
        return UIStoryboard(name: SBStoryboard.profile.rawValue, bundle: nil)
    }
    static var pickerSelection: UIStoryboard {
        return UIStoryboard(name: SBStoryboard.pickerSelection.rawValue, bundle: nil)
    }
    static var interaction: UIStoryboard {
        return UIStoryboard(name: SBStoryboard.interaction.rawValue, bundle: nil)
    }
    static var relationship: UIStoryboard {
        return UIStoryboard(name: SBStoryboard.relationship.rawValue, bundle: nil)
    }
    static var _public: UIStoryboard {
        return UIStoryboard(name: SBStoryboard._public.rawValue, bundle: nil)
    }
}
