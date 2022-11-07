//
//  Group.swift
//  SlobPicker
//
//  Created by 孔令傑 on 2022/11/5.
//

import Foundation

struct Group: Codable {
    var title: String
    var members: [String]
    var pickersIDs: [String]
    var createdTime: Int
    var id: String?
    
    enum CodingKeys: String, CodingKey {
        case title
        case members
        case pickersIDs = "pickers_ids"
        case createdTime = "created_time"
        case id
    }
}

struct GroupInfo: Codable {
    var groupName: String
    var groupID: String
    
    enum CodingKeys: String, CodingKey {
        case groupName = "group_name"
        case groupID = "group_id"
    }
}
