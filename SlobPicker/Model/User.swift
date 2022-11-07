//
//  User.swift
//  SlobPicker
//
//  Created by 孔令傑 on 2022/11/4.
//

import Foundation

struct User: Codable {
    var userName: String
    var userID: String
    var profileURL: String
    
    enum CodingKeys: String, CodingKey {
        case userName = "user_name"
        case userID = "user_id"
        case profileURL = "profile_url"
    }
}

struct Friend: Codable {
    var userID: String
    var isHidden: Bool
    
    enum CodingKeys: String, CodingKey {
        case userID = "user_id"
        case isHidden = "is_hidden"
    }
}
