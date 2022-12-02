//
//  Result.swift
//  SlobPicker
//
//  Created by 孔令傑 on 2022/11/4.
//

import Foundation

struct PickResult: Codable {
    let choice: Int
    let createdTime: Int?
    let userUUID: String
    enum CodingKeys: String, CodingKey {
        case choice, createdTime = "created_time", userUUID = "user_uuid"
    }
}

struct VoteResult: Hashable {
    var choice: Int
    var votes: Int
}
