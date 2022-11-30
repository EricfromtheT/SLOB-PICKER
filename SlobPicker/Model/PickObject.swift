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

enum PublicMode {
    case hottest
    case newest
    case lovest
}

enum PrivacyMode: String {
    case forPublic = "publicPickers"
    case forPrivate = "privatePickers"
    case forLive = "livePickers"
}

struct Picker: Codable {
    var id: String?
    var title: String
    var description: String
    var type: Int
    var contents: [String]
    var createdTime: Int?
    var authorID: String
    var authorName: String
    var authorUUID: String
    // for private
    var groupID: String?
    var groupName: String?
    var membersIDs: [String]?
    // for public
    var likedCount: Int?
    var likedIDs: [String]?
    var pickedCount: Int?
    var pickedIDs: [String]?
    
    
    enum CodingKeys: String, CodingKey {
        case title, description, type, contents, id
        case createdTime = "created_time"
        case authorID = "author_id"
        case authorName = "author_name"
        case likedCount = "liked_count"
        case likedIDs = "liked_ids"
        case pickedCount = "picked_count"
        case groupID = "group_id"
        case groupName = "group_name"
        case membersIDs = "members_ids"
        case pickedIDs = "picked_ids"
        case authorUUID = "author_uuid"
    }
}

struct Comment: Codable {
    var userUUID: String
    var userID: String
    var type: Int
    var comment: String
    var createdTime: Int
    
    enum CodingKeys: String, CodingKey {
        case userUUID = "user_uuid"
        case type
        case comment
        case createdTime = "created_time"
        case userID = "user_id"
    }
    
    func toDict() -> [String: Any] {
        let dict: [String: Any] = [
            "user_uuid": userUUID,
            "type": type,
            "comment": comment,
            "created_time": createdTime
        ]
        return dict
    }
}

struct LivePicker: Codable {
    var accessCode: String
    var authorID: String
    var status: String
    var pickerID: String?
    var startTime: Int?
    var contents: [String]
    var title: String
    var description: String
    var type: Int
    
    enum CodingKeys: String, CodingKey {
        case accessCode = "access_code"
        case authorID = "author_id"
        case status
        case pickerID = "picker_id"
        case startTime = "start_time"
        case contents
        case title
        case description
        case type
    }
}


