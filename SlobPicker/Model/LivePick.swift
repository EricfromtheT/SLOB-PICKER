//
//  LivePick.swift
//  SlobPicker
//
//  Created by 孔令傑 on 2022/11/11.
//

import Foundation

struct Attendee: Codable, Hashable {
    var attendTime: Int
    var userID: String
    var profileURL: String
    
    enum CodingKeys: String, CodingKey {
        case attendTime = "attend_time"
        case userID = "user_id"
        case profileURL = "profile_url"
    }
}
