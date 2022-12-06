//
//  FirebaseManager.swift
//  SlobPicker
//
//  Created by 孔令傑 on 2022/10/31.
//

import FirebaseFirestore
import FirebaseFirestoreSwift
import FirebaseStorage
import FirebaseAuth

enum UserError: Error {
    case nodata
}

class FirebaseManager {
    static let shared = FirebaseManager()
    static let auth = Auth.auth()
    let database = Firestore.firestore()
    let storageRef = Storage.storage().reference().child("imagesForPickers")
    let profileImageRef = Storage.storage().reference().child("imagesForProfile")
    private let privatePickersRef = Firestore.firestore().collection("privatePickers")
    private let groupRef = Firestore.firestore().collection("groups")
    
    // MARK: Private picker
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
        guard let uuid = FirebaseManager.auth.currentUser?.uid else { fatalError("uuid is nil") }
        privatePickersRef.whereField("members_ids", arrayContains: uuid).order(by: "created_time", descending: true).getDocuments { querySnapshot, error in
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
        if let groupID = pick.groupID {
            updateGroupPickersID(groupID: groupID, pickersID: document.documentID)
        } else {
            completion(.success("Failed to update group picker id"))
        }
        do {
            try document.setData(from: pick)
            completion(.success("Success"))
        } catch {
            completion(.failure(error))
        }
    }
    
    func updatePrivateComment(comment: Comment, pickerID: String) {
        // TODO: change document path to real userID
        privatePickersRef.document(pickerID).collection("all_comment").document(comment.userUUID).setData([
            "comment": comment.comment,
            "created_time": Date().millisecondsSince1970,
            "type": comment.type,
            "user_uuid": comment.userUUID,
            "user_id": comment.userID
        ]) { error in
            if let error = error {
                print(error, "ERROR: updataPrivateComment method")
            }
        }
    }
    
    func updatePrivateResult(index: Int, pickerID: String) {
        guard let uuid = FirebaseManager.auth.currentUser?.uid else { fatalError("uuid is nil") }
        privatePickersRef.document(pickerID).collection("results").document(uuid).setData([
            "choice": index,
            "created_time": Date().millisecondsSince1970,
            // change to new user
            "user_uuid": uuid
        ]) { error in
            if let error = error {
                print(error, "ERROR: updataPrivateResult method")
            }
        }
    }
    
    func fetchResults(collection: String, pickerID: String, completion: @escaping (Result<[PickResult], Error>) -> Void) {
        database.collection(collection).document(pickerID).collection("results").getDocuments { querySnapshot, error in
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
    
    
    
    func fetchComments(collection: String, pickerID: String, completion: @escaping (Result<[Comment], Error>) -> Void) {
        database.collection(collection).document(pickerID).collection("all_comment").getDocuments { querySnapshot, error in
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
                    print("decoding error")
                }
            }
        }
    }
    
    func updateGroupPickersID(groupID: String, pickersID: String) {
        database.collection("groups").document(groupID).updateData([
            "pickers_ids": FieldValue.arrayUnion([pickersID])
        ]) { error in
            if let error = error {
                print(error, "error of updating group pickers ID")
            }
        }
    }
    
    // MARK: Users
    func setUserToNone(completion: @escaping (Result<String, Error>) -> Void) {
        guard let uuid = FirebaseManager.auth.currentUser?.uid else {
            fatalError("no uuid with this user")
        }
        database.collection("users").document(uuid).updateData([
            "profile_url": "",
            "user_id": "此用戶已被刪除"
        ]) { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success("Success"))
            }
        }
    }
    
    func block(authorID: String, completion: @escaping (Result<String, Error>) -> Void) {
        guard let uuid = FirebaseManager.auth.currentUser?.uid else { fatalError("uuid is nil") }
        database.collection("users").document(uuid).updateData([
            "block": FieldValue.arrayUnion([authorID])
        ]) { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success("Success"))
            }
        }
    }
    
    func reportPicker(pickerID: String, completion: @escaping (Result<String, Error>) -> Void) {
        guard let uuid = FirebaseManager.auth.currentUser?.uid else { fatalError("uuid is nil") }
        database.collection("reportedPost").document().setData([
            "picker_id": pickerID,
            "user_uuid": uuid,
            "created_time": Date().millisecondsSince1970
        ]) { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success("Success"))
            }
        }
    }
    
    func createNewUser(user: inout User, completion: @escaping (Result<String, Error>) -> Void) {
        guard let uuid = FirebaseManager.auth.currentUser?.uid else { fatalError("uuid is nil") }
        let documentRef = database.collection("users").document(uuid)
        do {
            try documentRef.setData(from: user)
            completion(.success("Success"))
        } catch {
            completion(.failure(error))
        }
    }
    
    func getUserInfo(userUUID: String, completion: @escaping (Result<User, Error>) -> Void) {
        database.collection("users").whereField("user_uuid", isEqualTo: userUUID).getDocuments { qrry, error in
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
    
    func searchUser(userID: String, completion: @escaping (Result<User, Error>) -> Void) {
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
    
    func addFriend(userUUID: String) {
        // TODO: 不可讓雙方自動變為好友
        // add to yourself's
        // FIXME: 問題點，要先拿到對方的uuid
        guard let uuid = FirebaseManager.auth.currentUser?.uid else { fatalError("uuid is nil") }
        database.collection("users").document(uuid).collection("friends").document(userUUID).setData([
            "is_hidden": false,
            "user_uuid": userUUID
        ]) { error in
            if let error = error {
                print(error, "ERROR: add friend to yourself")
            }
        }
        // add to friend's
        database.collection("users").document(userUUID).collection("friends").document(uuid).setData([
            "is_hidden": false,
            "user_uuid": uuid
        ]) { error in
            if let error = error {
                print(error, "ERROR: add friend to theirs'")
            }
        }
    }
    
    func fetchAllFriendsID(completion: @escaping (Result<[Friend], Error>) -> Void) {
        guard let uuid = FirebaseManager.auth.currentUser?.uid else { fatalError("uuid is nil") }
        database.collection("users").document(uuid).collection("friends")
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
    
    
    // MARK: Group
    func addGroupPeople(groupID: String, newMembersUUID: [String], completion: @escaping (Result<String, Error>) -> Void) {
        database.collection("groups").document(groupID).updateData([
            "members": FieldValue.arrayUnion(newMembersUUID)
        ]) { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success("Success"))
            }
        }
    }
    
    func leaveGroup(groupID: String, completion: @escaping (Result<String, Error>) -> Void) {
        guard let uuid = FirebaseManager.auth.currentUser?.uid else { fatalError("uuid is nil") }
        database.collection("users").document(uuid).collection("groups").document(groupID).delete() { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success("Success"))
            }
        }
    }
    
    func groupDeleteUser(groupID: String, userUUID: String, completion: @escaping (Result<String, Error>) -> Void) {
        database.collection("groups").document(groupID).updateData([
            "members": FieldValue.arrayRemove([userUUID])
        ]) { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success("Success"))
            }
        }
    }
    
    func changeGroupName(name: String, groupID: String, completion: @escaping (Result<String, Error>) -> Void) {
        database.collection("groups").document(groupID).updateData([
            "title": name
        ]) { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success("Success"))
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
                addUserGroupInfo(userUUID: member, groupID: id, groupName: group.title) {
                    print("Success")
                }
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
    
    func addUserGroupInfo(userUUID: String, groupID: String, groupName: String, completion: @escaping (() -> Void)) {
        database.collection("users").document(userUUID).collection("groups").document(groupID).setData([
            "group_name": groupName,
            "group_id": groupID
        ]) { error in
            if let error = error {
                print(error, "ERROR update group info")
            } else {
                completion()
            }
        }
    }
    
    func fetchUserCurrentGroups(completion: @escaping (Result<[GroupInfo], Error>) -> Void) {
        guard let uuid = FirebaseManager.auth.currentUser?.uid else { fatalError("uuid is nil") }
        database.collection("users").document(uuid).collection("groups").getDocuments {
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
    
    // MARK: Public
    func publishPublicPicker(pick: inout Picker, completion: @escaping (Result<String, Error>) -> Void) {
        let document = database.collection("publicPickers").document()
        pick.id = document.documentID
        pick.createdTime = Date().millisecondsSince1970
        do {
            try document.setData(from: pick)
            completion(.success("Success"))
        } catch {
            completion(.failure(error))
        }
    }
    
    func fetchNewestPublicPicker(completion: @escaping (Result<[Picker], Error>) -> Void) {
        // newest picker
        database.collection("publicPickers").order(by: "created_time", descending: true)
            .getDocuments{ qrry, error in
                if let error = error {
                    completion(.failure(error))
                } else if let documents = qrry?.documents {
                    do {
                        let pickers = try documents.map {
                            try $0.data(as: Picker.self)
                        }
                        completion(.success(pickers))
                    } catch {
                        completion(.failure(error))
                    }
                }
            }
    }
    //    whereField("created_time", isGreaterThan: mlseconds)
    func fetchHottestPublicPicker(completion: @escaping (Result<[Picker], Error>) -> Void) {
        //        let calendar = Calendar.current
        //        let date = Date()
        //        let today = calendar.startOfDay(for: date)
        //        let mlseconds = today.millisecondsSince1970
        database.collection("publicPickers").order(by: "picked_count", descending: true).getDocuments { qrry, error in
            if let error = error {
                completion(.failure(error))
            } else if let documents = qrry?.documents {
                do {
                    let pickers = try documents.map {
                        try $0.data(as: Picker.self)
                    }
                    completion(.success(pickers))
                } catch {
                    completion(.failure(error))
                }
            }
        }
    }
    
    func fetchLovestPublicPicker(completion: @escaping (Result<[Picker], Error>) -> Void) {
        database.collection("publicPickers").order(by: "liked_count", descending: true).getDocuments {
            qrry, error in
            if let error = error {
                completion(.failure(error))
            } else if let documents = qrry?.documents {
                do {
                    let pickers = try documents.map {
                        try $0.data(as: Picker.self)
                    }
                    completion(.success(pickers))
                } catch {
                    completion(.failure(error))
                }
            }
        }
    }
    
    func likePicker(pickerID: String) {
        guard let uuid = FirebaseManager.auth.currentUser?.uid else { fatalError("uuid is nil") }
        let ref = database.collection("publicPickers").document(pickerID)
        ref.updateData([
            "liked_count": FieldValue.increment(Int64(1)),
            "liked_ids": FieldValue.arrayUnion([uuid])
        ])
    }
    
    func dislikePicker(pickerID: String) {
        guard let uuid = FirebaseManager.auth.currentUser?.uid else { fatalError("uuid is nil") }
        let ref = database.collection("publicPickers").document(pickerID)
        ref.updateData([
            "liked_count": FieldValue.increment(Int64(-1)),
            "liked_ids": FieldValue.arrayRemove([uuid])
        ])
    }
    
    func pickPicker(pickerID: String) {
        guard let uuid = FirebaseManager.auth.currentUser?.uid else { fatalError("uuid is nil") }
        let ref = database.collection("publicPickers").document(pickerID)
        ref.updateData([
            "picked_count": FieldValue.increment(Int64(1)),
            "picked_ids": FieldValue.arrayUnion([uuid])
        ])
    }
    
    func updatePublicComment(comment: Comment, pickerID: String) {
        database.collection("publicPickers").document(pickerID).collection("all_comment").document(comment.userUUID).setData([
            "comment": comment.comment,
            "created_time": Date().millisecondsSince1970,
            "type": comment.type,
            "user_uuid": comment.userUUID,
            "user_id": comment.userID
        ]) { error in
            if let error = error {
                print(error, "ERROR: updatePublicComment method")
            }
        }
    }
    
    func updatePublicResult(index: Int, pickerID: String) {
        guard let uuid = FirebaseManager.auth.currentUser?.uid else { fatalError("uuid is nil") }
        database.collection("publicPickers").document(pickerID).collection("results").document(uuid).setData([
            "choice": index,
            "created_time": Date().millisecondsSince1970,
            // change to new user
            "user_uuid": uuid
        ]) { error in
            if let error = error {
                print(error, "ERROR: updataPublicResult method")
            }
        }
    }
    
    // MARK: Live Picker
    func publishLivePicker(picker: inout LivePicker, completion: (Result<String, Error>) -> Void) {
        let document = database.collection("livePickers").document()
        let pickerID = document.documentID
        picker.pickerID = pickerID
        do {
            try document.setData(from: picker)
            completion(.success("Success"))
        } catch {
            completion(.failure(error))
        }
        
    }
    
    func fetchLivePicker(roomID: String, completion: @escaping (Result<LivePicker, Error>) -> Void) {
        database.collection("livePickers").whereField("access_code", isEqualTo: roomID).whereField("status", isEqualTo: "waiting").getDocuments { qrry, error in
            if let error = error {
                completion(.failure(error))
            } else if let documents = qrry?.documents {
                if documents.isEmpty {
                    completion(.failure(UserError.nodata))
                    return
                }
                do {
                    let livePicker = try documents[0].data(as: LivePicker.self)
                    completion(.success(livePicker))
                } catch {
                    completion(.failure(error))
                }
            }
        }
    }
    
    func fetchAttendees(documentID: String, completion: @escaping (Result<[Attendee], Error>) -> Void) {
        database.collection("livePickers").document(documentID).collection("attendees").getDocuments {
            qrry, error in
            if let error = error {
                completion(.failure(error))
            } else if let documents = qrry?.documents {
                do {
                    let attendees = try documents.map {
                        try $0.data(as: Attendee.self)
                    }
                    completion(.success(attendees))
                } catch {
                    completion(.failure(error))
                }
            }
        }
    }
    
    func attendLivePick(livePickerID: String, user: User ,completion: @escaping (Result<String, Error>) -> Void) {
        guard let userId = UserDefaults.standard.string(forKey: UserInfo.userIDKey) else { fatalError("No this user") }
        database.collection("livePickers").document(livePickerID).collection("attendees").document(userId).setData([
            "attend_time": Date().millisecondsSince1970,
            "user_id": userId,
            "profile_url": user.profileURL
        ]) { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success("Success"))
            }
        }
    }
    
    func startLivePick(livePickerID: String, status: String , completion: @escaping (Result<String, Error>) -> Void) {
        database.collection("livePickers").document(livePickerID).updateData([
            "status": status,
            "start_time": Date().millisecondsSince1970 + 4500
        ]) { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success("Success"))
            }
        }
    }
    
    func voteForLivePicker(pickerID: String, choice: Int) {
        guard let uuid = FirebaseManager.auth.currentUser?.uid else { fatalError("uuid is nil") }
        database.collection("livePickers").document(pickerID).collection("results").document(uuid).setData([
            "choice": choice,
            "user_uuid": uuid
        ])
    }
    
    func leaveLiveRoom(pickerID: String, completion: @escaping (Result<String, Error>) -> Void)  {
        guard let userID = UserDefaults.standard.string(forKey: UserInfo.userIDKey) else {
            fatalError("no userID in UserDefault")
        }
        database.collection("livePickers").document(pickerID).collection("attendees").document(userID).delete() { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success("Success"))
            }
        }
    }
    
    // MARK: Authentication
    func logOut() {
        do {
            try FirebaseManager.auth.signOut()
        } catch let error as NSError {
            print("error signing out: %@", error)
        }
    }
}
