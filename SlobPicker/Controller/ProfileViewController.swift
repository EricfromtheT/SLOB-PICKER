//
//  ProfileViewController.swift
//  SlobPicker
//
//  Created by 孔令傑 on 2022/11/24.
//

import UIKit
import AuthenticationServices
import CryptoKit
import SwiftJWT
import FirebaseAuth
import SafariServices
import PhotosUI
import ProgressHUD

private struct MyClaims: Claims {
    let iss: String
    let iat: Date
    let sub: String
    let exp: Date
    let aud: String
    let admin: Bool
}

private struct RefreshResponse: Codable {
    let accessToken: String
    let tokenType: String
    let expiresIn: Int
    let refreshToken: String
    let idToken: String
    
    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case tokenType = "token_type"
        case expiresIn = "expires_in"
        case refreshToken = "refresh_token"
        case idToken = "id_token"
    }
}

class ProfileViewController: UIViewController, SFSafariViewControllerDelegate {
    @IBOutlet weak var menuTableView: UITableView! {
        didSet {
            menuTableView.delegate = self
            menuTableView.dataSource = self
        }
    }
    fileprivate var currentNonce: String?
    var profilePhotoCompletion: ((UIImage) -> Void)?
    var data: User?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "個人頁面設定"
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        fetchProfile()
    }
    
    func fetchProfile() {
        guard let userUUID = FirebaseManager.auth.currentUser?.uid else { fatalError("no user uuid") }
        let docuRef = FirebaseManager.FirebaseCollectionRef.users.ref.document(userUUID)
        FirebaseManager.shared.getDocument(docuRef) { (user: User?) in
            if let user = user {
                self.data = user
            }
            self.menuTableView.reloadData()
        }
    }
    
    // MARK: Delete account
    func deleteAccount() {
        let alert = UIAlertController(title: "是否確定要刪除帳號",
                                      message:
                                        "確認刪除後需進行重新登入以驗證您的身份，" +
                                      "帳號刪除後將無法找回任何個人資料及使用紀錄，" +
                                      "並會解除SLOB PICKER與apple帳戶的連結。"
                                      ,
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        alert.addAction(UIAlertAction(title: "確認刪除", style: .destructive){ action in
            self.deleteFirebaseAppleAccount()
        })
        present(alert, animated: true)
    }
    
    // MARK: Privacy policy
    func openPrivacy() {
        if let url =
            URL(string: "https://www.privacypolicies.com/" +
                "live/4062ac64-f047-4818-bc02-22aea3d81b03") {
            let safari = SFSafariViewController(url: url)
            safari.delegate = self
            present(safari, animated: true)
        }
    }
}

// MARK: TableView DataSource
extension ProfileViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let actor = MyCell.allCases[indexPath.row]
        guard let cell = tableView.dequeueReusableCell(withIdentifier: actor.cellIdentifier,
                                                       for: indexPath) as? ProfileCell,
              let data = data
        else {
            fatalError("error of dequeuing ProfileCell")
        }
        cell.configure(data: data)
        return cell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        data == nil ? 0 : 5
    }
}

// MARK: TableView Delegate
extension ProfileViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let rowType = MyCell(rawValue: indexPath.row)
        switch rowType {
        case .nameCell:
            let storyboard = SBStoryboard.relationship.storyboard
            guard let editVC = storyboard.instantiateViewController(withIdentifier: "\(NameEditViewController.self)") as?
                    NameEditViewController else {
                fatalError("NameEditViewController cannot be instatiated")
            }
            editVC.mode = .fromProfile
            editVC.originalName = data?.userName
            show(editVC, sender: nil)
        case .privacyCell:
            openPrivacy()
        case .deleteAccountCell:
            deleteAccount()
        default:
            break
        }
    }
}

// MARK: PHPickerViewControllerDelegate
extension ProfileViewController: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        let result = results.first
        let itemProvider = result?.itemProvider
        if let itemProvider = itemProvider, itemProvider.canLoadObject(ofClass: UIImage.self) {
            itemProvider.loadObject(ofClass: UIImage.self) { [weak self] (image, error) in
                DispatchQueue.main.async {
                    guard let image = image as? UIImage, let self = self else {
                        if let error = error {
                            print(error.localizedDescription)
                        }
                        return
                    }
                    // upload to firebase and refetch the data for profile page
                    ProgressHUD.show()
                    if let uploadData = image.jpegData(compressionQuality: 0) {
                        let uniqueString = UUID().uuidString
                        let dataRef = FirebaseManager.shared.profileImageRef.child("\(uniqueString).jpeg")
                        dataRef.putData(uploadData) { data, error in
                            if let error = error {
                                print(error, "ERROR for uploading data to firebase storage")
                            } else {
                                dataRef.downloadURL { url, error in
                                    if let error = error {
                                        ProgressHUD.dismiss()
                                        return print(error.localizedDescription)
                                    }
                                    guard let downloadURL = url else {
                                        ProgressHUD.dismiss()
                                        return print("url is nil")
                                    }
                                    guard let userUUID = FirebaseManager.auth.currentUser?.uid else {
                                        fatalError("userUUID is nil")
                                    }
                                    let data = ["profile_url": downloadURL.absoluteString]
                                    let ref = FirebaseManager.FirebaseCollectionRef.users.ref.document(userUUID)
                                    FirebaseManager.shared.updateFieldValue(data,
                                                                            at: ref) {
                                        self.fetchProfile()
                                        ProgressHUD.dismiss()
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

// MARK: Gen Token
extension ProfileViewController {
    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        let charset: [Character] =
        Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remainingLength = length
        while remainingLength > 0 {
            let randoms: [UInt8] = (0 ..< 16).map { _ in
                var random: UInt8 = 0
                let errorCode = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
                if errorCode != errSecSuccess {
                    fatalError(
                        "Unable to generate nonce." +
                        "SecRandomCopyBytes failed with OSStatus \(errorCode)"
                    )
                }
                return random
            }
            
            randoms.forEach { random in
                if remainingLength == 0 {
                    return
                }
                
                if random < charset.count {
                    result.append(charset[Int(random)])
                    remainingLength -= 1
                }
            }
        }
        return result
    }
    
    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        let hashString = hashedData.compactMap {
            String(format: "%02x", $0)
        }.joined()
        
        return hashString
    }
    
    private func genRefreshToken(authCode: Data) {
        // gen JWT
        let myHeader = Header(kid: Secret.keyID.rawValue)
        let myClaims = MyClaims(iss: Secret.teamID.rawValue,
                                iat: Date(), sub: Secret.clientID.rawValue,
                                exp: Date(timeIntervalSinceNow: 3600),
                                aud: "https://appleid.apple.com",
                                admin: true)
        var appleJWT = JWT(header: myHeader, claims: myClaims)
        var signedJWT: String = ""
        // sign JWT tokeni
        let path = Bundle.main.path(forResource: Secret.filePath.rawValue, ofType: "p8")
        do {
            if let path = path {
                let contents = try String(contentsOfFile: path)
                if let privateKey = contents.data(using: .utf8) {
                    let jwtSigner = JWTSigner.es256(privateKey: privateKey)
                    signedJWT = try appleJWT.sign(using: jwtSigner)
                }
            }
        } catch {
            return print(error)
        }
        // gen refresh token
        guard let url = URL(string: "https://appleid.apple.com/auth/token") else {
            return print("error of creating refresh url")
        }
        guard let authCodeToString = String(data: authCode, encoding: .utf8) else {
            fatalError("Error of turning authCode data to string")
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded",
                         forHTTPHeaderField: "content-type")
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        components?.queryItems = [
            URLQueryItem(name: "client_id",
                         value: Secret.clientID.rawValue),
            URLQueryItem(name: "client_secret",
                         value: signedJWT),
            URLQueryItem(name: "code",
                         value: authCodeToString),
            URLQueryItem(name: "grant_type",
                         value: "authorization_code")
        ]
        if let query = components?.url?.query {
            request.httpBody = Data(query.utf8)
        }
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                return print(error, "error in tasking")
            }
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200,
                  let data = data else {
                return print("response problem or data is empty")
            }
            let decoder = JSONDecoder()
            do {
                let refreshData = try decoder.decode(RefreshResponse.self, from: data)
                // take it to post revoke
                self.revoke(refreshToken: refreshData.refreshToken, jwt: signedJWT)
            } catch {
                return print(error, "error of decoding refresh token data")
            }
        }
        task.resume()
    }
    
    private func revoke(refreshToken: String, jwt: String) {
        guard let url = URL(string: "https://appleid.apple.com/auth/revoke") else {
            return print("error of creating revoke url")
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded"
                         , forHTTPHeaderField: "content-type")
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        components?.queryItems = [
            URLQueryItem(name: "client_id",
                         value: Secret.clientID.rawValue),
            URLQueryItem(name: "client_secret",
                         value: jwt),
            URLQueryItem(name: "token",
                         value: refreshToken),
            URLQueryItem(name: "token_type",
                         value: "refresh_token")
        ]
        if let query = components?.url?.query {
            request.httpBody = Data(query.utf8)
        }
        
        let task = URLSession.shared.dataTask(with: request) { _, response, error in
            if let error = error {
                return print(error, "error in tasking")
            }
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                return print("response problem or data is empty")
            }
        }
        task.resume()
    }
    
    // MARK: Deal with reauthentication
    func deleteFirebaseAppleAccount() {
        self.reAppleLogin()
    }
    
    func reAppleLogin() {
        let nonce = randomNonceString()
        currentNonce = nonce
        // generate request by crypto string
        let authorizationAppleIDRequest: ASAuthorizationAppleIDRequest
        = ASAuthorizationAppleIDProvider().createRequest()
        authorizationAppleIDRequest.requestedScopes = [.fullName, .email]
        authorizationAppleIDRequest.nonce = sha256(nonce)
        
        let controller: ASAuthorizationController
        = ASAuthorizationController(authorizationRequests: [authorizationAppleIDRequest])
        
        controller.delegate = self
        controller.presentationContextProvider = self
        controller.performRequests()
    }
}


// MARK: ASAuthorizationControllerDelegate
extension ProfileViewController: ASAuthorizationControllerDelegate {
    func authorizationController(controller: ASAuthorizationController,
                                 didCompleteWithAuthorization authorization: ASAuthorization) {
        if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
           let authorizationCode = appleIDCredential.authorizationCode {
            guard let nonce = currentNonce else {
                fatalError("Invalid state: A login callback was received," +
                           "but no login request was sent.")
            }
            guard let appleIDToken = appleIDCredential.identityToken else {
                print("Unable to fetch identity token")
                return
            }
            guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
                print("Unable to serialize token string from data:" +
                      "\(appleIDToken.debugDescription)")
                return
            }
            // get refresh token and save to keychain manager
            genRefreshToken(authCode: authorizationCode)
            // Initialize a Firebase credential
            let credential = OAuthProvider.credential(withProviderID: "apple.com",
                                                      idToken: idTokenString,
                                                      rawNonce: nonce)
            FirebaseManager.auth.currentUser?.reauthenticate(with: credential) {
                auth, error  in
                if let error = error {
                    return print(error, "error of reauthenticating with firebase")
                } else {
                    FirebaseManager.shared.setUserToNone() { result in
                        switch result {
                        case .success( _):
                            break
                        case .failure(let error):
                            return print(error, "error of updating user info to none")
                        }
                        FirebaseManager.auth.currentUser?.delete() { error in
                            if let _ = error {
                                fatalError("problem with delete account after reauthenticate")
                            } else {
                                UserDefaults.standard.set(nil, forKey: UserInfo.userNameKey)
                                UserDefaults.standard.set(nil, forKey: UserInfo.userIDKey)
                            }
                        }
                    }
                }
            }
        }
    }
    
    func authorizationController(controller: ASAuthorizationController,
                                 didCompleteWithError error: Error) {
        switch (error) {
        case ASAuthorizationError.canceled:
            break
        case ASAuthorizationError.failed:
            break
        case ASAuthorizationError.invalidResponse:
            break
        case ASAuthorizationError.notHandled:
            break
        case ASAuthorizationError.unknown:
            break
        default:
            break
        }
        print("didCompleteWithError: \(error.localizedDescription)")
    }
}

// MARK: ASAuthorizationControllerPresentationContextProviding
extension ProfileViewController: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        guard let window = self.view.window else {
            fatalError("view.window is not existing")
        }
        return window
    }
}

