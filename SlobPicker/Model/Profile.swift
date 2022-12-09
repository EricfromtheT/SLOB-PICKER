//
//  Profile.swift
//  SlobPicker
//
//  Created by 孔令傑 on 2022/12/8.
//

import UIKit

protocol ProfileCell: UITableViewCell {
    func configure(data: User)
}

enum MyCell: CaseIterable {
    case photoCell
    case idCell
    case nameCell
    case privacyCell
    case deleteAccountCell
    
    var cellIdentifier: String {
        switch self {
        case .photoCell:
            return ProfileImageCell.identifier
        case .idCell:
            return UserIDCell.identifier
        case .nameCell:
            return UserNickNameCell.identifier
        case .privacyCell:
            return PrivacyCell.identifier
        case .deleteAccountCell:
            return DeleteAccountCell.identifier
        }
    }
}


