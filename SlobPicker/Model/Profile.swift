//
//  Profile.swift
//  SlobPicker
//
//  Created by 孔令傑 on 2022/12/8.
//

import Foundation

protocol ProfileCell {
    func configure(data: CellModel)
}

protocol CellModel {
    
}

struct ProfileImage: CellModel {
    var imageURL: String
    var superVC: ProfileViewController
}

struct UserID: CellModel {
    var userID: String
}

struct UserNickName: CellModel {
    var userNickName: String
}
