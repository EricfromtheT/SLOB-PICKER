//
//  SPConstant.swift
//  SlobPicker
//
//  Created by 孔令傑 on 2022/10/31.
//

import UIKit

// SP for Slob Picker in short
struct SPConstant {
    static let screenWidth = UIScreen.main.bounds.width
    static let screenHeight = UIScreen.main.bounds.height
}

struct UserInfo {
    static var shared = UserInfo()
    static let userIDKey = "userID"
    static let userNameKey = "userName"
    var userID: String = UserDefaults.standard.string(forKey: "userID") ?? ""
    var userName: String = UserDefaults.standard.string(forKey: "userName") ?? ""
}
