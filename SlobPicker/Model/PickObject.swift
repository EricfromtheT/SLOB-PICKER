//
//  PickObject.swift
//  SlobPicker
//
//  Created by 孔令傑 on 2022/11/1.
//

import Foundation

struct Pick: Codable {
    var id: String?
    var title: String
    var description: String
    var type: Int
    var contents: [String]
    var createdTime: Int64?
    var comments: Comments?
    
    enum CodingKeys: String, CodingKey {
        case title, description, type, contents, comments, id
        case createdTime = "created_time"
    }
}

struct Comments: Codable {
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
}
