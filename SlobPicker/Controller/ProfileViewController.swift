//
//  ProfileViewController.swift
//  SlobPicker
//
//  Created by 孔令傑 on 2022/11/24.
//

import UIKit
import AuthenticationServices
import SafariServices
import PhotosUI
import ProgressHUD

class ProfileViewController: UIViewController, SFSafariViewControllerDelegate {
    @IBOutlet weak var menuTableView: UITableView! {
        didSet {
            menuTableView.delegate = self
            menuTableView.dataSource = self
        }
    }
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
    
    private func fetchProfile() {
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
    private func deleteAccount() {
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
    private func openPrivacy() {
        if let url =
            URL(string: "https://www.privacypolicies.com/" +
                "live/4062ac64-f047-4818-bc02-22aea3d81b03") {
            let safari = SFSafariViewController(url: url)
            safari.delegate = self
            present(safari, animated: true)
        }
    }
    
    private func deleteFirebaseAppleAccount() {
        let controller = AccountManager.shared.loginController()
        controller.delegate = self
        controller.presentationContextProvider = self
        controller.performRequests()
    }
}

// MARK: TableView DataSource
extension ProfileViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let actor = MyCell.allCases[indexPath.row]
        guard let cell = tableView.dequeueReusableCell(withIdentifier: actor.cellIdentifier, for: indexPath) as? ProfileCell,
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
            let storyboard = UIStoryboard.relationship
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
                                    FirebaseManager.shared.update(data, at: ref) {
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
// MARK: ASAuthorizationControllerDelegate
extension ProfileViewController: ASAuthorizationControllerDelegate {
    func authorizationController(controller: ASAuthorizationController,
                                 didCompleteWithAuthorization authorization: ASAuthorization) {
        if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
           let authorizationCode = appleIDCredential.authorizationCode {
            guard let appleIDToken = appleIDCredential.identityToken else {
                print("Unable to fetch identity token")
                return
            }
            guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
                print("Unable to serialize token string from data:" +
                      "\(appleIDToken.debugDescription)")
                return
            }
            AccountManager.shared.genRefreshToken(authCode: authorizationCode)
            AccountManager.shared.initializeFirebaseCredential(idTokenString: idTokenString)
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

