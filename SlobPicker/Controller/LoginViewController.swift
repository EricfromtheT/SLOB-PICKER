//
//  LoginViewController.swift
//  SlobPicker
//
//  Created by 孔令傑 on 2022/11/7.
//

import UIKit
import AuthenticationServices
import FirebaseAuth
import CryptoKit
import SwiftJWT

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

class LoginViewController: UIViewController {
    @IBOutlet weak var appleLogInView: UIView!
    var superVC: PublicViewController!
    fileprivate var currentNonce: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpAppleButton()
        // 如果是一直有在使用未刪app的用戶
        if FirebaseManager.auth.currentUser != nil && UserDefaults.standard.string(forKey: UserInfo.userIDKey) != nil {
            let viewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "\(MainTabBarController.self)")
            UIApplication.shared.windows.first?.rootViewController = viewController
            UIApplication.shared.windows.first?.makeKeyAndVisible()
        }
    }
    
    deinit {
        print("login view controller has died")
    }
    
    func setUpAppleButton() {
        let authorizationAppleIDButton: ASAuthorizationAppleIDButton
        = ASAuthorizationAppleIDButton()
        authorizationAppleIDButton
            .addTarget(self, action: #selector(pressSignInWithAppleButton),
                       for: UIControl.Event.touchUpInside)
        appleLogInView.addSubview(authorizationAppleIDButton)
        authorizationAppleIDButton.frame = appleLogInView.bounds
        
    }
    
    @objc func pressSignInWithAppleButton() {
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
                        "Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)"
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
        let myClaims = MyClaims(iss: Secret.teamID.rawValue, iat: Date(), sub: Secret.clientID.rawValue, exp: Date(timeIntervalSinceNow: 3600), aud: "https://appleid.apple.com", admin: true)
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
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "content-type")
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        components?.queryItems = [
            URLQueryItem(name: "client_id", value: Secret.clientID.rawValue),
            URLQueryItem(name: "client_secret", value: signedJWT),
            URLQueryItem(name: "code", value: authCodeToString),
            URLQueryItem(name: "grant_type", value: "authorization_code")
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
                print(refreshData.refreshToken, "refresh token")
                KeychainService.keychainManager.save(refreshData.refreshToken, for: KeychainService.refreshTokenAccount)
            } catch {
                return print(error, "error of decoding refresh token data")
            }
        }
        task.resume()
    }
}

extension LoginViewController: ASAuthorizationControllerDelegate {
    func authorizationController(controller: ASAuthorizationController,
                                 didCompleteWithAuthorization authorization: ASAuthorization) {
        if let appleIDCredential = authorization.credential
            as? ASAuthorizationAppleIDCredential, let authorizationCode = appleIDCredential.authorizationCode {
            guard let nonce = currentNonce else {
                fatalError("Invalid state: A login callback was received, but no login request was sent.")
            }
            guard let appleIDToken = appleIDCredential.identityToken else {
                print("Unable to fetch identity token")
                return
            }
            guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
                print("Unable to serialize token string from data: \(appleIDToken.debugDescription)")
                return
            }
            // get refresh token and save to keychain manager
            genRefreshToken(authCode: authorizationCode)
            // Initialize a Firebase credential
            let credential = OAuthProvider.credential(withProviderID: "apple.com",
                                                      idToken: idTokenString,
                                                      rawNonce: nonce)
            // Sign in with Firebase.
            Auth.auth().signIn(with: credential) { (authResult, error) in
                if let error = error {
                    // Error. If error.code == .MissingOrInvalidNonce, make sure
                    // you're sending the SHA256-hashed nonce as a hex string with
                    // your request to Apple.
                    print(error.localizedDescription)
                    return
                } else {
                    // User has signed in to Firebase with Apple
                    // See if this user is the new client
                    guard let auth = authResult else { fatalError("user is missed") }
                    FirebaseManager.shared.getUserInfo(userUUID: auth.user.uid) {
                        result in
                        switch result {
                        case .success(let user):
                            // old user login in
                            UserDefaults.standard.set(user.userID, forKey: UserInfo.userIDKey)
                            UserDefaults.standard.set(user.userName, forKey: UserInfo.userNameKey)
                            // rootViewController change to tabbarviewcontroller
                            let viewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "\(MainTabBarController.self)")
                            self.view.window?.rootViewController = viewController
                            self.view.window?.makeKeyAndVisible()
                        case .failure(let error):
                            if error as? UserError == .nodata {
                                // new user register and log in
                                let storyboard = UIStoryboard(name: "Main", bundle: nil)
                                guard let NewUserVC = storyboard.instantiateViewController(
                                    withIdentifier: "\(NewUserViewController.self)") as? NewUserViewController
                                else {
                                    fatalError("New UserViewController cannot be instantiating")
                                }
                                NewUserVC.modalPresentationStyle = .fullScreen
                                self.present(NewUserVC, animated: true)
                            } else {
                                print(error, "error of getting user info")
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


extension LoginViewController: ASAuthorizationControllerPresentationContextProviding {
    
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        guard let window = self.view.window else {
            fatalError("view.window is not existing")
        }
        return window
    }
}
