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
            hotPickerCollectionView.heightAnchor.constraint(equalToConstant: 160).isActive = true
        }
    }
    
    var firstLoad = true
    let group = DispatchGroup()
    let semaphore = DispatchSemaphore(value: 1)
    
    var hottestPickers: [Picker] = [] {
        didSet {
            if !hottestPickers.isEmpty {
                data = hottestPickers
            }
            let users = hottestPickers.map {
                $0.authorID
            }
            fetchUser(userID: users)
        }
    }
    var newestPickers: [Picker] = [] {
        didSet {
            if !newestPickers.isEmpty {
                data = newestPickers
            }
            let users = newestPickers.map {
                $0.authorID
            }
            fetchUser(userID: users)
        }
    }
    

    var data: [Picker] = []
    var mode: PublicMode = .hottest
    var usersInfo: [User] = []
    var superVC: PublicViewController?
    
    func fetchUser(userID: [String]) {
        let userIDs = Set(userID)
        userIDs.forEach {
            group.enter()
            FirebaseManager.shared.searchUserID(userID: $0, completion: { result in
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
        let storyboard = UIStoryboard(name: "Interaction", bundle: nil)
        guard let pickVC = storyboard.instantiateViewController(withIdentifier: "\(PickViewController.self)")
                as? PickViewController else {
            print("PickViewController rendering error")
            return
        }
        let data = mode == .hottest ? hottestPickers : newestPickers
        pickVC.publicCompletion = {
            cell.picked()
            self.data[indexPath.row].pickedIDs?.append(FakeUserInfo.shared.userID)
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
                user.userID == picker.authorID
            }
            cell.configure(data: picker, imageURL: user[0].profileURL, hasLiked: likedIDs.contains(FakeUserInfo.shared.userID), hasPicked: pickedIDs.contains(FakeUserInfo.shared.userID), index: indexPath.row)
            
            cell.likedCompletion = {
                self.data[indexPath.row].likedIDs?.append(FakeUserInfo.shared.userID)
                self.data[indexPath.row].likedCount? += 1
            }
            cell.dislikedCompletion = {
                self.data[indexPath.row].likedIDs?.removeAll(where: { $0 == FakeUserInfo.shared.userID })
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
        CGSize(width: SPConstant.screenWidth * 0.55, height: 160)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        UIEdgeInsets(top: 0, left: SPConstant.screenWidth * 0.03, bottom: 0, right: SPConstant.screenWidth * 0.03)
    }
}

extension HotCell: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        // show result page
        let storyboard = UIStoryboard(name: "PickerSelection", bundle: nil)
        guard let resultVC = storyboard.instantiateViewController(withIdentifier: "\(PickResultViewController.self)")
                as? PickResultViewController else {
            print("PickResultViewController rendering error")
            return
        }
        let data = mode == .hottest ? hottestPickers : newestPickers
        resultVC.mode = .forPublic
        resultVC.pickInfo = data[indexPath.row]
        superVC?.show(resultVC, sender: self)
    }
}
