//
//  FirebaseManager.swift
//  SlobPicker
//
//  Created by 孔令傑 on 2022/10/31.
//

import FirebaseFirestore
import FirebaseFirestoreSwift

class FirebaseManager {
    static let shared = FirebaseManager()
    private let db = Firestore.firestore()
    
    // fetch picker info for picking
    func fetchPrivatePickInfo(pickerID: String, completion: @escaping (Result<Pick, Error>) -> Void) {
        db.collection("privatePickers").document(pickerID).getDocument { querySnapshot, error in
            if let error = error {
                completion(.failure(error))
            } else {
                do {
                    if let pickInfo = try querySnapshot?.data(as: Pick.self) {
                        completion(.success(pickInfo))
                    }
                } catch {
                    completion(.failure(error))
                }
            }
        }
    }
    
    // publish a new picker
    func publishPrivatePick(pick: inout Pick, completion: @escaping (Result<String, Error>) -> Void) {
        let document = db.collection("privatePickers").document()
        pick.id = document.documentID
        pick.createdTime = Date().millisecondsSince1970
        do {
            try document.setData(from: pick)
        } catch {
            print("ERROR: something wrong to publish private picker")
        }
    }
}
