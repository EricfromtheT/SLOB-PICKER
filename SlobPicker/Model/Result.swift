//
//  Result.swift
//  SlobPicker
//
//  Created by 孔令傑 on 2022/11/4.
//

import Foundation

struct PickResult: Codable {
    let choice: Int
    let createdTime: Int
    let userID: String
    enum CodingKeys: String, CodingKey {
        case choice, createdTime = "created_time", userID = "user_id"
    }
}

struct VoteResult {
    var choice: Int
    var votes: Int
}
