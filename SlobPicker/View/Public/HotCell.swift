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
            hotPickerCollectionView.heightAnchor.constraint(equalToConstant: SPConstant.screenHeight * 0.2).isActive = true
        }
    }
    
    let group = DispatchGroup()
    let semaphore = DispatchSemaphore(value: 1)
    var hottestPickers: [Picker] = [] {
        didSet {
            let users = hottestPickers.map {
                $0.authorID
            }
            fetchUser(userID: users)
        }
    }
    
    var newestPickers: [Picker] = [] {
        didSet {
            let users = newestPickers.map {
                $0.authorID
            }
            fetchUser(userID: users)
        }
    }
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
        var data: Picker?
        switch mode {
        case .hottest:
            data = hottestPickers[indexPath.row]
        case .newest:
            data = newestPickers[indexPath.row]
        }
        if let data = data, let likedIDs = data.likedIDs, let pickedIDs = data.pickedIDs {
            let user = usersInfo.filter { user in
                user.userID == data.authorID
            }
            cell.configure(data: data, imageURL: user[0].profileURL, hasLiked: likedIDs.contains(FakeUserInfo.shared.userID), hasPicked: pickedIDs.contains(FakeUserInfo.shared.userID), index: indexPath.row)
        }
        cell.clickCompletion = {
            self.showPickPage(indexPath: indexPath, cell: cell)
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        mode == .hottest ? hottestPickers.count : newestPickers.count
    }
}

extension HotCell: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        CGSize(width: SPConstant.screenWidth * 0.55, height: SPConstant.screenHeight * 0.2)
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
