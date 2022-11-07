//
//  PickObject.swift
//  SlobPicker
//
//  Created by 孔令傑 on 2022/11/1.
//

import Foundation

enum PickerType {
    case textType
    case imageType
}

// TODO: 新增group ID 確認歸屬區
struct Picker: Codable {
    var id: String?
    var title: String
    var description: String
    var type: Int
    var contents: [String]
    var createdTime: Int?
    var authorID: String
    var authorName: String
    var group: String?
    var membersIDs: [String]?
    
    enum CodingKeys: String, CodingKey {
        case title, description, type, contents, id
        case createdTime = "created_time"
        case authorID = "author_id"
        case authorName = "author_name"
        case group
        case membersIDs = "members_ids"
    }
}

struct Comment: Codable {
    var userID: String
    var type: Int
    var comment: String
    var createdTime: Int
    
    enum CodingKeys: String, CodingKey {
        case userID = "user_id"
        case type
        case comment
        case createdTime = "created_time"
    }
    
    func toDict() -> [String: Any] {
        let dict: [String: Any] = [
            "user_id": userID,
            "type": type,
            "comment": comment,
            "created_time": createdTime
        ]
        return dict
    }
}


