//
//  ViewController.swift
//  SlobPicker
//
//  Created by 孔令傑 on 2022/10/28.
//

import UIKit

class ViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
//        var pick = Pick(title: "張育睿", description: "陳亭君", type: 0, contents: ["賴佩琪", "邱子瑜", "陳穎涵", "陳健倫"])
//        FirebaseManager.shared.publishPrivatePick(pick: &pick, completion: { result in
//            switch result {
//            case .success(let success):
//                print(success)
//            case .failure(let error):
//                print(error)
//            }
//        })
    }
    
    @IBAction func toTest() {
//        let storyboard = UIStoryboard(name: "Functions", bundle: nil)
//        let viewController = storyboard.instantiateViewController(withIdentifier: "\(PickViewController.self)")
//        as! PickViewController
//        viewController.pickerID = "880dTxKg8jfkIyOslBCs"
//        show(viewController, sender: self)
        let storyboard = UIStoryboard(name: "Functions", bundle: nil)
        guard let editorVC = storyboard.instantiateViewController(withIdentifier: "\(PickerEditorViewController.self)") as? PickerEditorViewController else { return }
        show(editorVC, sender: self)
    }
}
