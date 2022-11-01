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
        // Do any additional setup after loading the view.
    }
    
    @IBAction func toTest() {
        let storyboard = UIStoryboard(name: "Functions", bundle: nil)
        let viewc = storyboard.instantiateViewController(withIdentifier: "\(PickViewController.self)")
        as! PickViewController
        show(viewc, sender: self)
    }
}
