//
//  HotCell.swift
//  SlobPicker
//
//  Created by 孔令傑 on 2022/11/7.
//

import UIKit

class HotCell: UITableViewCell {
    @IBOutlet weak var hotPickerCollectionView: UICollectionView! {
        didSet {
            hotPickerCollectionView.dataSource = self
            hotPickerCollectionView.delegate = self
            hotPickerCollectionView.heightAnchor.constraint(equalToConstant: 180).isActive = true
        }
    }
    
    var firstLoad = true
    let group = DispatchGroup()
    let semaphore = DispatchSemaphore(value: 1)
    let uuid = FirebaseManager.auth.currentUser?.uid
    
    var hottestPickers: [Picker] = [] {
        didSet {
            if !hottestPickers.isEmpty {
                data = hottestPickers
            }
            let usersUUID = hottestPickers.map {
                $0.authorUUID
            }
            fetchUser(userUUID: usersUUID)
        }
    }
    
    var newestPickers: [Picker] = [] {
        didSet {
            if !newestPickers.isEmpty {
                data = newestPickers
            }
            let usersUUID = newestPickers.map {
                $0.authorUUID
            }
            fetchUser(userUUID: usersUUID)
        }
    }
    
    var lovestPickers: [Picker] = [] {
        didSet {
            if !lovestPickers.isEmpty {
                data = lovestPickers
            }
            let usersUUID = lovestPickers.map {
                $0.authorUUID
            }
            fetchUser(userUUID: usersUUID)
        }
    }
    
    var data: [Picker] = []
    var mode: PublicMode = .hottest
    var usersInfo: [User] = []
    var superVC: PublicViewController?
    
    func fetchUser(userUUID: [String]) {
        let userUUIDs = Set(userUUID)
        userUUIDs.forEach {
            group.enter()
            FirebaseManager.shared.getUserInfo(userUUID: $0, completion: { result in
                switch result {
                case .success(let user):
                    self.usersInfo.append(user)
                case .failure(let error):
                    print(error, "error of getting user info")
                }
                self.group.leave()
            })
        }
        group.notify(queue: DispatchQueue.main) {
            self.hotPickerCollectionView.reloadData()
            self.hotPickerCollectionView.setContentOffset(.zero, animated: false)
        }
    }
    
    func showPickPage(indexPath: IndexPath, cell: HotPickerCell) {
        guard let uuid = uuid else { fatalError("uuid in keychain is nil") }
        let storyboard = UIStoryboard.interaction
        guard let pickVC = storyboard.instantiateViewController(withIdentifier: "\(PickViewController.self)")
                as? PickViewController else {
            print("PickViewController rendering error")
            return
        }
        var data: [Picker] = []
        switch mode {
        case .hottest:
            data = hottestPickers
        case .newest:
             data = newestPickers
        case .lovest:
            data = lovestPickers
        }
        pickVC.publicCompletion = {
            cell.picked()
            self.data[indexPath.row].pickedIDs?.append(uuid)
            self.data[indexPath.row].pickedCount? += 1
            cell.pickImageView.isUserInteractionEnabled = false
        }
        pickVC.pickInfo = data[indexPath.row]
        pickVC.mode = .forPublic
        superVC?.show(pickVC, sender: self)
    }
}

extension HotCell: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "\(HotPickerCell.self)", for: indexPath)
                as? HotPickerCell else {
            fatalError("ERROR of instantiating HotPickerCell")
        }
        var picker: Picker?
        picker = data[indexPath.row]
        if let picker = picker, let likedIDs = picker.likedIDs, let pickedIDs = picker.pickedIDs {
            let user = usersInfo.filter { user in
                user.userUUID == picker.authorUUID
            }
            guard let uuid = uuid else { fatalError("uuid in keychain is nil") }
            cell.configure(data: picker, imageURL: user[0].profileURL, hasLiked: likedIDs.contains(uuid), hasPicked: pickedIDs.contains(uuid), index: indexPath.row)
            
            cell.likedCompletion = {
                self.data[indexPath.row].likedIDs?.append(uuid)
                self.data[indexPath.row].likedCount? += 1
            }
            cell.dislikedCompletion = {
                self.data[indexPath.row].likedIDs?.removeAll(where: { $0 == uuid })
                self.data[indexPath.row].likedCount? -= 1
            }
        }
        cell.goPickCompletion = {
            self.showPickPage(indexPath: indexPath, cell: cell)
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        data.count
    }
}

extension HotCell: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        CGSize(width: SPConstant.screenWidth * 0.65, height: 180)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        UIEdgeInsets(top: 0, left: SPConstant.screenWidth * 0.03, bottom: 0, right: SPConstant.screenWidth * 0.03)
    }
}

extension HotCell: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        // show result page
        let storyboard = UIStoryboard.pickerSelection
        guard let resultVC = storyboard.instantiateViewController(withIdentifier: "\(PickResultViewController.self)")
                as? PickResultViewController else {
            print("PickResultViewController rendering error")
            return
        }
        var data: [Picker] = []
        switch mode {
        case .hottest:
            data = hottestPickers
        case .newest:
             data = newestPickers
        case .lovest:
            data = lovestPickers
        }
        resultVC.mode = .forPublic
        resultVC.pickInfo = data[indexPath.row]
        superVC?.show(resultVC, sender: self)
    }
}
