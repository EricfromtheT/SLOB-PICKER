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

struct FakeUserInfo {
    static var shared = FakeUserInfo()
    var userID: String = UserDefaults.standard.string(forKey: "userID") ?? "5487549"
    var userName: String = UserDefaults.standard.string(forKey: "userName") ?? "Eric"
}