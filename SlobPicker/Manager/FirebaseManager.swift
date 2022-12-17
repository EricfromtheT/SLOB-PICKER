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
    lazy var privatePickersRef = database.collection("privatePickers")
    lazy var publicPickersRef = database.collection("publicPickers")
    private let groupRef = Firestore.firestore().collection("groups")
    typealias CollectionRef = CollectionReference
    typealias DocumentRef = DocumentReference
    
    enum FirebaseCollectionRef {
        case groups
        case pickers(type: PrivacyMode)
        case reportedPost
        case users
        case usersFriends(userID: String)
        case usersGroup(userID: String)
        case pickerComments(type: PrivacyMode, pickerID: String)
        case pickerResults(type: PrivacyMode, pickerID: String)
        case livePickAttendees(pickerID: String)
        
        var ref: CollectionReference {
            let database = Firestore.firestore()
            let users = database.collection("users")
            switch self {
            case .groups:
                return database.collection("groups")
            case .pickers(let type):
                return database.collection(type.rawValue)
            case .reportedPost:
                return database.collection("reportedPost")
            case .users:
                return users
            case .usersFriends(let userID):
                return users.document(userID).collection("friends")
            case .usersGroup(let userID):
                return users.document(userID).collection("groups")
            case .pickerComments(let type, let pickerID):
                return database.collection(type.rawValue).document(pickerID).collection("all_comment")
            case .pickerResults(let type, let pickerID):
                return database.collection(type.rawValue).document(pickerID).collection("results")
            case .livePickAttendees(let pickerID):
                return database.collection("livePickers").document(pickerID).collection("attendees")
            }
        }
    }
    
    // MARK: Firebase API method
    func getDocument<T: Decodable>(_ docRef: DocumentReference, completion: @escaping (T?) -> Void) {
        docRef.getDocument { snapshot, error in
            completion(self.parseDocument(snapshot: snapshot, error: error))
        }
    }

    func getDocuments<T: Decodable>(_ query: Query, completion: @escaping ([T]) -> Void) {
        query.getDocuments { snapshot, error in
            completion(self.parseDocuments(snapshot: snapshot, error: error))
        }
    }
    
    func delete(_ docRef: DocumentReference, completion: (() -> Void)?) {
        docRef.delete()
        completion?()
    }

    func setData(_ documentData: [String : Any], at docRef: DocumentReference, completion: (() -> Void)?) {
        docRef.setData(documentData)
        completion?()
    }
    
    func update(_ documentData: [String: Any], at docRef: DocumentReference, completion: @escaping (() -> Void)) {
        docRef.updateData(documentData) { error in
            if let error = error {
                print(error.localizedDescription, "error of updating document fields")
            } else {
                completion()
            }
        }
    }

    func setData<T: Encodable>(_ data: T, at docRef: DocumentReference, completion: () -> Void) {
        do {
            try docRef.setData(from: data)
            completion()
        } catch {
            print("DEBUG: Error encoding \(data.self) data -", error.localizedDescription)
        }
    }
    
    private func parseDocument<T: Decodable>(snapshot: DocumentSnapshot?, error: Error?) -> T? {
        guard let snapshot = snapshot, snapshot.exists else {
            let errorMessage = error?.localizedDescription ?? ""
            print("DEBUG: Nil document", errorMessage)
            return nil
        }

        var model: T?
        do {
            model = try snapshot.data(as: T.self)
        } catch {
            print("DEBUG: Error decoding \(T.self) data -", error.localizedDescription)
        }
        return model
    }

    private func parseDocuments<T: Decodable>(snapshot: QuerySnapshot?, error: Error?) -> [T] {
        guard let snapshot = snapshot else {
            let errorMessage = error?.localizedDescription ?? ""
            print("DEBUG: Error fetching snapshot -", errorMessage)
            return []
        }

        var models: [T] = []
        snapshot.documents.forEach { document in
            do {
                let item = try document.data(as: T.self)
                models.append(item)
            } catch {
                print("DEBUG: Error decoding \(T.self) data -", error.localizedDescription)
            }
        }
        return models
    }
    
    // MARK: Private picker
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
    
    func addFriend(userUUID: String) {
        // TODO: 不可讓雙方自動變為好友
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
    
    // MARK: Public
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
    func fetchHottestPublicPicker(completion: @escaping (Result<[Picker], Error>) -> Void) {
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
    // MARK: Authentication
    func logOut() {
        do {
            try FirebaseManager.auth.signOut()
        } catch let error as NSError {
            print("error signing out: %@", error)
        }
    }
}
