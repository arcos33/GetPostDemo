//
//  ViewController.swift
//  PolarityTE
//
//  Created by Joel Arcos on 12/4/18.
//  Copyright © 2018 Joel Arcos. All rights reserved.
//

import UIKit
import CoreData
//  =================================================================================================
//  iVars
//  =================================================================================================
class ProfileSummaryView: UIViewController {
    static let cellIdentifier = "cellId"
    var users = [User]()
    var appDelegate: AppDelegate!
    var coreDataContext: NSManagedObjectContext!
    var rotationAngle: CGFloat = 0
    private let refreshControl = UIRefreshControl()

    @IBOutlet weak var refreshImage: UIImageView!
    @IBOutlet weak var mainTable: UITableView!
    @IBOutlet weak var titleLBL: UILabel!
    
}

//  =================================================================================================
//  Lifecycle Methods
//  =================================================================================================
extension ProfileSummaryView {
    override func viewDidLoad() {
        super.viewDidLoad()
        self.appDelegate = UIApplication.shared.delegate as? AppDelegate
        self.coreDataContext = appDelegate.persistentContainer.viewContext
        setupTable()
        updateCells()
    }
}

//  =================================================================================================
//  Private Methods
//  =================================================================================================
extension ProfileSummaryView {
    fileprivate func updateUsersArray(users: [User]) {
        self.users = users
        self.mainTable.reloadData()
        self.titleLBL.text = "\(users.count) Users"
    }
    
    fileprivate func setupTable() {
        self.mainTable.delegate = self
        
        // Add Refresh Control to Table View
        if #available(iOS 10.0, *) {
            self.mainTable.refreshControl = refreshControl
        } else {
            self.mainTable.addSubview(refreshControl)
        }
        refreshControl.attributedTitle = NSAttributedString(string: "Updating from server...")
        self.refreshControl.addTarget(self, action: #selector(updateCells), for: .valueChanged)
    }
    
    @objc fileprivate func updateCells() {
        deleteUserRecords {
            HTTP_Client.sharedHTTPClient.performRequestOfType(requestType: "GET") { (users) in
                self.mainTable.refreshControl?.endRefreshing()
                self.updateUsersArray(users: users)
            }
            
            rotateRefreshIcon()
        }
    }
    
    fileprivate func rotateRefreshIcon() {
        UIView.animate(withDuration: 0.5) {
            self.refreshImage.transform = CGAffineTransform(rotationAngle: 3 + self.rotationAngle)
            self.rotationAngle += 360
        }
    }
    
    fileprivate func deleteUserRecords(_ completion: () -> ()) {
        // Create Fetch Request
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "User")
        
        // Create Batch Delete Request
        let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        
        do {
            try coreDataContext.execute(batchDeleteRequest)
            completion()
        } catch {
            // Error Handling
        }
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
        let user = users[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: ProfileSummaryView.cellIdentifier, for: indexPath)
        cell.textLabel?.text = user.name
        return cell
    }
}

//  =================================================================================================
//  IBActions
//  =================================================================================================
extension ProfileSummaryView {

}
