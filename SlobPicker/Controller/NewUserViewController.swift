//
//  NewUserViewController.swift
//  SlobPicker
//
//  Created by 孔令傑 on 2022/11/22.
//

import UIKit
import Lottie
import PhotosUI
import ProgressHUD

class NewUserViewController: UIViewController {
    @IBOutlet weak var welcomeView: UIView!
    @IBOutlet weak var nextButton: UIButton!
    @IBOutlet weak var formView: FormView!
    var animationView: LottieAnimationView?
    var pickImageCompletion: ((UIImage) -> Void)?
    var searchID: String = ""
    var searchCompletion: ((String) -> Void)?
    // to be uploaded info
    var willBeUploadedImage: UIImage?
    var willBeUploadedURLString: String?
    var willBeUploadedId: String?
    var willBeUploadedName: String?
    let uuid = FirebaseManager.auth.currentUser?.uid
    
    override func viewDidLoad() {
        super.viewDidLoad()
        addBGAnimation()
        setUpWelcomeView()
        setUpFormView()
        ProgressHUD.animationType = .lineScaling
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        animationView?.play()
        showWelcomeView()
    }
    
    deinit {
        ProgressHUD.dismiss()
    }
    
    func addBGAnimation() {
        animationView = .init(name: "congrats")
        animationView?.loopMode = .loop
        animationView?.frame = CGRect(x: 0, y: 0, width: SPConstant.screenWidth, height: SPConstant.screenHeight)
        animationView?.contentMode = .scaleAspectFill
        animationView?.animationSpeed = 1
        view.addSubview(animationView!)
        view.sendSubviewToBack(animationView!)
    }
    
    func setUpWelcomeView() {
        welcomeView.alpha = 0
    }
    
    func setUpFormView() {
        formView.alpha = 0
        formView.configure(superVC: self)
        formView.idCompletion = { id in
            self.searchID = id
            NSObject.cancelPreviousPerformRequests(withTarget: self)
            self.perform(#selector(self.searchIdResult), with: nil, afterDelay: 0.3)
        }
        formView.nickNameCompletion = { content in
            self.willBeUploadedName = content
        }
    }
    
    func showWelcomeView() {
        UIView.animate(withDuration: 1.2, delay: 0.6, usingSpringWithDamping: 0.5, initialSpringVelocity: 0.2) {
            self.welcomeView.transform = CGAffineTransform(translationX: SPConstant.screenWidth, y: 0)
            self.welcomeView.alpha = 1
        }
    }
    
    @objc func searchIdResult() {
        if searchID.isEmpty {
            searchCompletion?("empty")
            return
        } else if !searchID.isValid {
            searchCompletion?("format")
            return
        }
        FirebaseManager.shared.searchUser(userID: searchID) { result in
            switch result {
            case .success( _):
                // ID is not available
                self.searchCompletion?("cannot")
                self.willBeUploadedId = ""
            case .failure(let error):
                if error as? UserError == .nodata {
                    // ID is available
                    self.searchCompletion?("can")
                    self.willBeUploadedId = self.searchID
                } else {
                    print(error, "error of getting certain user info")
                }
            }
        }
    }
    
    @IBAction func goToProfileSetting() {
        UIView.animate(withDuration: 1.4) {
            self.welcomeView.transform = CGAffineTransform(translationX: -SPConstant.screenWidth, y: 0)
            self.welcomeView.alpha = 0
            self.animationView?.alpha = 0
            self.formView.transform = CGAffineTransform(translationX: -SPConstant.screenWidth, y: 0)
            self.formView.alpha = 1
        } completion: { _ in
            self.animationView?.stop()
        }
    }
    
    func formatter() {
        willBeUploadedId = willBeUploadedId?.trimmingCharacters(in: .whitespacesAndNewlines)
        willBeUploadedName = willBeUploadedName?.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    @IBAction func finishSetting() {
        ProgressHUD.show()
        // 先判斷illegal format
        formatter()
        guard let willBeUploadedId = willBeUploadedId, let willBeUploadedName = willBeUploadedName, !willBeUploadedId.isEmpty, !willBeUploadedName.isEmpty else {
            let alert = UIAlertController(title: "ID重複或暱稱尚未填入", message: "請將資訊填寫正確及完整唷", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .cancel))
            present(alert, animated: true)
            return
        }
        // 處理照片上傳, url回傳
        if let uploadData = willBeUploadedImage?.jpegData(compressionQuality: 0) {
            let uniqueString = UUID().uuidString
            let dataRef = FirebaseManager.shared.profileImageRef.child("\(uniqueString).jpeg")
            dataRef.putData(uploadData) { data, error in
                if let error = error {
                    print(error, "error of uploading profile image")
                } else {
                    dataRef.downloadURL { url, error in
                        if let error = error {
                            print(error, "error of retrieving url")
                        } else {
                            if let url = url {
                                self.willBeUploadedURLString = url.absoluteString
                                // 文字, url打包
                                guard let willBeUploadedURLString = self.willBeUploadedURLString
                                else { return print("profile image url is nil") }
                                guard let uuid = self.uuid else { fatalError("uuid in keychain is nil") }
                                var user = User(userName: willBeUploadedName, userID: willBeUploadedId, userUUID: uuid, profileURL: willBeUploadedURLString)
                                // firebase新增user資料
                                FirebaseManager.shared.createNewUser(user: &user) { result in
                                    switch result {
                                    case .success( _):
                                        ProgressHUD.dismiss()
                                        let rootVC = UIApplication.shared.windows.first?.rootViewController
                                        rootVC?.dismiss(animated: true)
                                    case .failure(let error):
                                        print(error, "error of add new document for user")
                                    }
                                }
                            }
                        }
                    }
                }
                // UserDefault setting
                UserDefaults.standard.set(willBeUploadedId, forKey: UserInfo.userIDKey)
                UserDefaults.standard.set(willBeUploadedName, forKey: UserInfo.userNameKey)
            }
        }
    }
}

extension NewUserViewController: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        let result = results.first
        let itemProvider = result?.itemProvider
        if let itemProvider = itemProvider, itemProvider.canLoadObject(ofClass: UIImage.self) {
            itemProvider.loadObject(ofClass: UIImage.self) { [weak self] (image, error) in
                DispatchQueue.main.async {
                    guard let self = self, let image = image as? UIImage else { fatalError("NewUserViewController has died") }
                    self.willBeUploadedImage = image
                    self.pickImageCompletion?(image)
                }
            }
        }
    }
}
