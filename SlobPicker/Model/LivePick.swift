//
//  LivePick.swift
//  SlobPicker
//
//  Created by 孔令傑 on 2022/11/11.
//

import Foundation

struct Attendee: Codable {
    var attendTime: Int
    var userID: String
    
    enum CodingKeys: String, CodingKey {
        case attendTime = "attend_time"
        case userID = "user_id"
    }
}
