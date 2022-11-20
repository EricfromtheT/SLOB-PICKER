//
//  KeychainService.swift
//  SlobPicker
//
//  Created by 孔令傑 on 2022/11/20.
//

import Foundation

class KeychainService {
    
    static let keychainManager = KeychainService()
    private let accountForUUID = "uuidForUser"
    
    func saveUserUID(uid: String, for account: String = "uuidForUser") {
        let uid = uid.data(using: String.Encoding.utf8)!
        let query: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
                                    kSecAttrAccount as String: account,
                                    kSecValueData as String: uid]
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else { return print("save error") }
    }
    
    func retriveUID(for account: String) -> String? {
        let query: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
                                    kSecAttrAccount as String: account,
                                    kSecMatchLimit as String: kSecMatchLimitOne,
                                    kSecReturnData as String: kCFBooleanTrue as Any]
        
        
        var retrivedData: AnyObject? = nil
        let _ = SecItemCopyMatching(query as CFDictionary, &retrivedData)
        
        
        guard let data = retrivedData as? Data else {return nil}
        return String(data: data, encoding: String.Encoding.utf8)
    }
}
