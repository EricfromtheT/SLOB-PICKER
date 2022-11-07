//
//  PublicPickerViewController.swift
//  SlobPicker
//
//  Created by 孔令傑 on 2022/11/7.
//

import UIKit

class PublicViewController: UIViewController {
    @IBOutlet weak var hotTableView: UITableView! {
        didSet {
            hotTableView.dataSource = self
        }
    }
    override func viewDidLoad() {
        super.viewDidLoad()
    }
}

extension PublicViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        <#code#>
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        <#code#>
    }
}
