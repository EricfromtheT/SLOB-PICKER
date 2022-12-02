//
//  String+Extension.swift
//  SlobPicker
//
//  Created by 孔令傑 on 2022/11/23.
//

import Foundation

extension String {
    var isValid: Bool {
        return self.allSatisfy { character in
            character.isNumber || character.isLowercase
        }
    }
}
