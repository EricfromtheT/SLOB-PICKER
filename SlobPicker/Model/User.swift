//
//  User.swift
//  SlobPicker
//
//  Created by 孔令傑 on 2022/11/4.
//

import Foundation

struct User: Codable, Hashable {
    var userName: String
    var userID: String
    var profileURL: String
    // for live picker sorting
    var time: Int?

    func hash(into hasher: inout Hasher) {
        hasher.combine(userID)
    }
    
    static func == (lhs: User, rhs: User) -> Bool {
        lhs.userID == rhs.userID
    }
    
    enum CodingKeys: String, CodingKey {
        case userName = "user_name"
        case userID = "user_id"
        case profileURL = "profile_url"
        case time
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
