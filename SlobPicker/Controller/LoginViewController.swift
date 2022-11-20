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

class LoginViewController: UIViewController {
    @IBOutlet weak var idField: UITextField!
    @IBOutlet weak var nameField: UITextField!
    @IBOutlet weak var appleLogInView: UIView!
    var superVC: PublicViewController!
    fileprivate var currentNonce: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpAppleButton()
    }
    
    func setUpAppleButton() {
        let authorizationAppleIDButton: ASAuthorizationAppleIDButton
        = ASAuthorizationAppleIDButton()
        authorizationAppleIDButton
            .addTarget(self, action: #selector(pressSignInWithAppleButton),
                       for: UIControl.Event.touchUpInside)
        
        authorizationAppleIDButton.frame = self.appleLogInView.bounds
        self.appleLogInView.addSubview(authorizationAppleIDButton)
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
    
    @IBAction func done() {
        if let id = idField.text, let name = nameField.text {
            UserDefaults.standard.set(id, forKey: "userID")
            UserDefaults.standard.set(name, forKey: "userName")
            FakeUserInfo.shared.userID = id
            FakeUserInfo.shared.userName = name
            superVC.dismiss(animated: true)
        }
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
}

extension LoginViewController: ASAuthorizationControllerDelegate {
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        if let appleIDCredential = authorization.credential
            as? ASAuthorizationAppleIDCredential {
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
                    FirebaseManager.shared.searchUserID(userID: auth.user.uid) {
                        result in
                        switch result {
                        case .success( _):
                            // old user login in
                            KeychainService.keychainManager.saveUserUID(uid: auth.user.uid)
                            
                        case .failure(let error):
                            if error as? UserError == .nodata {
                                // new user register and log in
                                KeychainService.keychainManager.saveUserUID(uid: auth.user.uid)
                            } else {
                                print(error, "error of getting user info")
                            }
                            
                        }
                    }
                }
            }
        }
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
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
