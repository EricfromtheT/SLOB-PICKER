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
    var userUUID: String
    var profileURL: String
    var block: [String]?
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
        case userUUID = "user_uuid"
        case time
        case block
    }
}

struct Friend: Codable {
    var userUUID: String
    var isHidden: Bool
    
    enum CodingKeys: String, CodingKey {
        case userUUID = "user_uuid"
        case isHidden = "is_hidden"
    }
}
