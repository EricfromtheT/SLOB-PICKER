//
//  PickObject.swift
//  SlobPicker
//
//  Created by 孔令傑 on 2022/11/1.
//

import Foundation

enum PickType {
    case textType
    case imageType
}

struct Pick: Codable {
    var id: String?
    var title: String
    var description: String
    var type: Int
    var contents: [String]
    var createdTime: Int64?
    var comments: [Comment]?
    var results: [Int: Int]?
    
    enum CodingKeys: String, CodingKey {
        case title, description, type, contents, comments, id, results
        case createdTime = "created_time"
    }
}

struct Comment: Codable {
    var userID: String
    var type: Int
    var contents: String
    var createdTime: Int64
    
    enum CodingKeys: String, CodingKey {
        case userID = "user_id"
        case type
        case contents
        case createdTime = "created_time"
    }
    
    func toDict() -> [String: Any] {
        let dict: [String: Any] = [
            "user_id": userID,
            "type": type,
            "contents": contents,
            "created_time": createdTime
        ]
        return dict
    }
}
