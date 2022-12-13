//
//  AccountManager.swift
//  SlobPicker
//
//  Created by 孔令傑 on 2022/12/11.
//

import UIKit
import AuthenticationServices
import CryptoKit
import SwiftJWT
import FirebaseAuth

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

class AccountManager {
    static let shared = AccountManager()
    private var currentNonce: String?
    
    func loginController() -> ASAuthorizationController {
        let nonce = randomNonceString()
        currentNonce = nonce
        // generate request by crypto string
        let authorizationAppleIDRequest: ASAuthorizationAppleIDRequest
        = ASAuthorizationAppleIDProvider().createRequest()
        authorizationAppleIDRequest.requestedScopes = [.fullName, .email]
        authorizationAppleIDRequest.nonce = sha256(nonce)
        
        let controller: ASAuthorizationController
        = ASAuthorizationController(authorizationRequests: [authorizationAppleIDRequest])
        
        return controller
    }
    
    // MARK: Gen Token
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
    
    func genRefreshToken(authCode: Data) {
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
    
    func initializeFirebaseCredential(idTokenString: String) {
        guard let nonce = currentNonce else {
            return print("nonce nonce is not saved correctly")
        }
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
