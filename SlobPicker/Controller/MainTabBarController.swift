//
//  MainTabBarController.swift
//  SlobPicker
//
//  Created by 孔令傑 on 2022/11/15.
//

import UIKit

class MainTabBarController: UITabBarController {
    let customButton = UIButton()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        settingButton()
        self.delegate = self
        tabBar.tintColor = UIColor.asset(.navigationbar2)
    }
    
    func settingButton() {
        let image = UIImage(named: "picking")
        customButton.setImage(image, for: .normal)
        customButton.frame.size = CGSize(width: 50, height: 50)
        customButton.center = CGPoint(x: tabBar.bounds.midX, y: tabBar.bounds.midY - customButton.frame.height / 3)
        customButton.backgroundColor = UIColor.asset(.livePick)?.withAlphaComponent(1)
        customButton.layer.cornerRadius = 15
        customButton.layer.borderColor = UIColor.black.cgColor
        customButton.layer.borderWidth = 2
        customButton.clipsToBounds = true
        customButton.adjustsImageWhenHighlighted = false
        tabBar.addSubview(customButton)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        touches.forEach { (touch) in
            let position = touch.location(in: tabBar)
            let offset = customButton.frame.height / 3
            if customButton.frame.minX <= position.x && position.x <= customButton.frame.maxX {
                if customButton.frame.minY - offset <= position.y && position.y <= customButton.frame.maxY - offset{
                }
            }
        }
    }
}

extension MainTabBarController: UITabBarControllerDelegate {
    func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController)
    -> Bool {
        if viewController == viewControllers?[1] {
            let storyboard = UIStoryboard.interaction
            let entranceVC = storyboard.instantiateViewController(withIdentifier: "\(EntranceViewController.self)")
            self.present(entranceVC, animated: true)
            return false
        }
        return true
    }
}
