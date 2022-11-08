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
    var hottestPickers: [PublicPicker] = [] {
        didSet {
            let users = hottestPickers.map {
                $0.authorID
            }
            fetchUser(userID: users)
        }
    }
    var newestPickers: [PublicPicker] = [] {
        didSet {
            let users = newestPickers.map {
                $0.authorID
            }
            fetchUser(userID: users)
        }
    }
    var mode: PublicMode = .hottest
    var usersInfo: [User] = []
    
    func fetchUser(userID: [String]) {
        userID.forEach {
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
        }
    }
}

extension HotCell: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "\(HotPickerCell.self)", for: indexPath)
                as? HotPickerCell else {
            fatalError("ERROR of instantiating HotPickerCell")
        }
        var data: PublicPicker?
        switch mode {
        case .hottest:
            data = hottestPickers[indexPath.row]
        case .newest:
            data = newestPickers[indexPath.row]
        }
        if let data = data {
            cell.configure(data: data, imageURL: usersInfo[indexPath.row].profileURL, hasLiked: data.likedIDs.contains(FakeUserInfo.shared.userID))
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        mode == .hottest ? hottestPickers.count : newestPickers.count
    }
}

extension HotCell: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        CGSize(width: SPConstant.screenWidth * 0.5, height: SPConstant.screenHeight * 0.2)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        UIEdgeInsets(top: 0, left: SPConstant.screenWidth * 0.03, bottom: 0, right: SPConstant.screenWidth * 0.03)
    }
}

extension HotCell: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
    }
}
