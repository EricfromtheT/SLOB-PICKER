//
//  FirebaseManager.swift
//  SlobPicker
//
//  Created by 孔令傑 on 2022/10/31.
//

import FirebaseFirestore
import FirebaseFirestoreSwift
import FirebaseStorage

class FirebaseManager {
    static let shared = FirebaseManager()
    private let database = Firestore.firestore()
    let storageRef = Storage.storage().reference().child("imagesForPickers")
    
    
    // fetch picker info for picking
    func fetchPrivatePickInfo(pickerID: String, completion: @escaping (Result<Pick, Error>) -> Void) {
        database.collection("privatePickers").document(pickerID).getDocument { querySnapshot, error in
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
        let document = database.collection("privatePickers").document()
        pick.id = document.documentID
        pick.createdTime = Date().millisecondsSince1970
        do {
            try document.setData(from: pick)
        } catch {
            completion(.failure(error))
        }
        completion(.success("Success"))
    }
    
    func updatePrivateComment(comment: Comment, pickerID: String) {
        // TODO: change document path to real userID
        database.collection("privatePickers").document(pickerID).collection("all_comment").document(FakeUserInfo.userID).setData([
            "comment": comment.contents,
            "created_time": Date().millisecondsSince1970,
            "type": comment.type
        ])
    }
    
    func updatePrivateResult(index: Int, pickerID: String) {
        database.collection("privatePickers").document(pickerID).collection("results").document(FakeUserInfo.userID).setData([
            "choice": index,
            "created_time": Date().millisecondsSince1970
        ])
    }
}
