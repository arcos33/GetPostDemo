//
//  ViewController.swift
//  PolarityTE
//
//  Created by Joel Arcos on 12/4/18.
//  Copyright © 2018 Joel Arcos. All rights reserved.
//

import UIKit
//  =================================================================================================
//  iVars
//  =================================================================================================
class ProfileSummaryView: UIViewController {
    static let cellIdentifier = "cellId"
    var users = [String]()
    @IBOutlet weak var mainTable: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }


    
}


//  =================================================================================================
//  TableView Methods
//  =================================================================================================
extension ProfileSummaryView: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return users.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        //let user = users[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: ProfileSummaryView.cellIdentifier, for: indexPath)
        return cell
    }
    
    
}

//  =================================================================================================
//  IBActions
//  =================================================================================================
extension ProfileSummaryView {
    @IBAction func newUser(_ sender: UIButton) {
        HTTP_Client.shared.createUser()
    }
}

