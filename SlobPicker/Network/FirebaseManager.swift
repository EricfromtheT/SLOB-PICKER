//
//  FirebaseManager.swift
//  SlobPicker
//
//  Created by 孔令傑 on 2022/10/31.
//

import FirebaseFirestore
import FirebaseFirestoreSwift
import FirebaseStorage

enum UserError: Error {
    case nodata
}

class FirebaseManager {
    static let shared = FirebaseManager()
    private let database = Firestore.firestore()
    let storageRef = Storage.storage().reference().child("imagesForPickers")
    private let privatePickersRef = Firestore.firestore().collection("privatePickers")
    private let groupRef = Firestore.firestore().collection("groups")
    
    // fetch picker info for picking
    func fetchPrivatePickInfo(pickerID: String, completion: @escaping (Result<Picker, Error>) -> Void) {
        privatePickersRef.document(pickerID).getDocument { querySnapshot, error in
            if let error = error {
                completion(.failure(error))
            } else {
                do {
                    if let pickInfo = try querySnapshot?.data(as: Picker.self) {
                        completion(.success(pickInfo))
                    }
                } catch {
                    completion(.failure(error))
                }
            }
        }
    }
    
    func fetchAllPrivatePickers(completion: @escaping (Result<[Picker], Error>) -> Void) {
        privatePickersRef.whereField("members_ids", arrayContains: FakeUserInfo.shared.userID).getDocuments { querySnapshot, error in
            if let error = error {
                completion(.failure(error))
            } else {
                do {
                    if let documents = querySnapshot?.documents {
                        let pickers = try documents.map { document in
                            try document.data(as: Picker.self)
                        }
                        completion(.success(pickers))
                    }
                } catch {
                    completion(.failure(error))
                }
            }
        }
    }
    
    
    // publish a new picker
    func publishPrivatePicker(pick: inout Picker, completion: @escaping (Result<String, Error>) -> Void) {
        let document = privatePickersRef.document()
        pick.id = document.documentID
        pick.createdTime = Date().millisecondsSince1970
        do {
            try document.setData(from: pick)
            completion(.success("Success"))
        } catch {
            completion(.failure(error))
        }
    }
    
    func updatePrivateComment(comment: Comment, pickerID: String) {
        // TODO: change document path to real userID
        privatePickersRef.document(pickerID).collection("all_comment").document(FakeUserInfo.shared.userID).setData([
            "comment": comment.comment,
            "created_time": Date().millisecondsSince1970,
            "type": comment.type,
            "user_id": FakeUserInfo.shared.userID
        ]) { error in
            if let error = error {
                print(error, "ERROR: updataPrivateComment method")
            }
        }
    }
    
    func updatePrivateResult(index: Int, pickerID: String) {
        privatePickersRef.document(pickerID).collection("results").document(FakeUserInfo.shared.userID).setData([
            "choice": index,
            "created_time": Date().millisecondsSince1970,
            // change to new user
            "user_id": FakeUserInfo.shared.userID
        ]) { error in
            if let error = error {
                print(error, "ERROR: updataPrivateResult method")
            }
        }
    }
    
    func fetchPickerResults(pickerID: String, completion: @escaping (Result<[PickResult], Error>) -> Void) {
        privatePickersRef.document(pickerID).collection("results").getDocuments { querySnapshot, error in
            if let error = error {
                completion(.failure(error))
            } else if let documents = querySnapshot?.documents {
                do {
                    let results = try documents.map { document in
                        try document.data(as: PickResult.self)
                    }
                    completion(.success(results))
                } catch {
                    completion(.failure(error))
                }
            }
        }
    }
    
    func fetchPickerComments(pickerID: String, completion: @escaping (Result<[Comment], Error>) -> Void) {
        privatePickersRef.document(pickerID).collection("all_comment").getDocuments { querySnapshot, error in
            if let error = error {
                completion(.failure(error))
            } else if let documents = querySnapshot?.documents {
                do {
                    let comments = try documents.map { document in
                        try document.data(as: Comment.self)
                    }
                    completion(.success(comments))
                } catch {
                    completion(.failure(error))
                    print("second error")
                }
            }
        }
    }
    
    func searchUserID(userID: String, completion: @escaping (Result<User, Error>) -> Void) {
        database.collection("users").whereField("user_id", isEqualTo: userID).getDocuments { qrry, error in
            if let error = error {
                completion(.failure(error))
            } else {
                do {
                    if let userInfo = try qrry?.documents.first?.data(as: User.self) {
                        completion(.success(userInfo))
                    } else {
                        completion(.failure(UserError.nodata))
                    }
                } catch {
                    completion(.failure(error))
                }
            }
        }
    }
    
    func addFriend(userID: String) {
        // TODO: 不可讓雙方自動變為好友
        // add to yourself's
        database.collection("users").document(FakeUserInfo.shared.userID).collection("friends").document(userID).setData([
            "is_hidden": false,
            "user_id": userID
        ]) { error in
            if let error = error {
                print(error, "ERROR: add friend to yourself")
            }
        }
        // add to friend's
        database.collection("users").document(userID).collection("friends").document(FakeUserInfo.shared.userID).setData([
            "is_hidden": false,
            "user_id": FakeUserInfo.shared.userID
        ]) { error in
            if let error = error {
                print(error, "ERROR: add friend to theirs'")
            }
        }
    }
    
    func fetchAllFriendsID(completion: @escaping (Result<[Friend], Error>) -> Void) {
        database.collection("users").document(FakeUserInfo.shared.userID).collection("friends")
            .whereField("is_hidden", isEqualTo: false).getDocuments { qrry, error in
                if let error = error {
                    completion(.failure(error))
                } else if let documents = qrry?.documents {
                    do {
                        let friends = try documents.map { document in
                            try document.data(as: Friend.self)
                        }
                        completion(.success(friends))
                    } catch {
                        completion(.failure(error))
                    }
                }
            }
    }
    
    func fetchFriendsProfile(friendsID: [String], completion: @escaping (Result<[User], Error>) -> Void) {
        // TODO: 一次最高可以填入10個friendsID
        database.collection("users").whereField("user_id", in: friendsID).getDocuments { qrry, error in
            if let error = error {
                completion(.failure(error))
            } else if let documents = qrry?.documents {
                do {
                    let friends = try documents.map { document in
                        try document.data(as: User.self)
                    }
                    completion(.success(friends))
                } catch {
                    completion(.failure(error))
                }
            }
        }
    }
    
    func publishNewGroup(group: inout Group, completion: @escaping (Result<String, Error>) -> Void) {
        let document = groupRef.document()
        let id = document.documentID
        group.id = id
        do {
            try document.setData(from: group)
            completion(.success("publish new group Successfully"))
            for member in group.members {
                addUserGroupInfo(userID: member, groupID: id, groupName: group.title)
            }
            
        } catch {
            completion(.failure(error))
        }
    }
    
    func fetchGroupInfo(groupID: String, completion: @escaping (Result<Group, Error>) -> Void) {
        database.collection("groups").document(groupID).getDocument { qrry, error in
            if let error = error {
                completion(.failure(error))
            } else {
                do {
                    if let groupInfo = try qrry?.data(as: Group.self) {
                        completion(.success(groupInfo))
                    }
                } catch {
                    completion(.failure(error))
                }
            }
        }
    }
    
    func addUserGroupInfo(userID: String, groupID: String, groupName: String) {
        database.collection("users").document(userID).collection("groups").document(groupID).setData([
            "group_name": groupName,
            "group_id": groupID
        ]) { error in
            if let error = error {
                print(error, "ERROR update group info")
            }
        }
    }
    
    func fetchUserCurrentGroups(completion: @escaping (Result<[GroupInfo], Error>) -> Void) {
        database.collection("users").document(FakeUserInfo.shared.userID).collection("groups").getDocuments {
            qrry, error in
            if let error = error {
                completion(.failure(error))
            } else if let documents = qrry?.documents {
                do {
                    let groupInfos = try documents.map { try $0.data(as: GroupInfo.self) }
                    completion(.success(groupInfos))
                } catch {
                    completion(.failure(error))
                }
            }
        }
    }
}
