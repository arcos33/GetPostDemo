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
    var selectedUser: User?
    private let refreshControl = UIRefreshControl()

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
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "SummaryView->ProfileView" {
            if let vc = segue.destination as? ProfileView {
                vc.profileViewDelegate = self
                vc.userGuid = nil
            }
        }
    }
}

//  =================================================================================================
//  Internal Methods
//  =================================================================================================
extension ProfileSummaryView {
    fileprivate func updateUsersArray(users: [User]) {
        
        self.users = users
        self.users.sort(by: {$0.name!.localizedCaseInsensitiveCompare($1.name!) == ComparisonResult.orderedAscending})
        
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
        print("hello")
        deleteUserRecords {
            HTTP_Client.sharedHTTPClient.performGETRequest(completion: { (userDictionaries) in
                var userArray = [User]()
                let group = DispatchGroup()
                // Clear out users array
                self.users.removeAll()

                for dict in userDictionaries {
                    
                    DispatchQueue.main.async(execute: {
                        if (dict["name"] as? String == "Canelo") {
                            
                        }
                        group.enter()
                        let appDelegate = UIApplication.shared.delegate as! AppDelegate
                        let context = appDelegate.persistentContainer.viewContext
                        let userEntity = NSEntityDescription.entity(forEntityName: "User", in: context)!
                        let user = NSManagedObject(entity: userEntity, insertInto: context) as! User
                        user.setValue(dict["name"] as? String ?? "unkwown", forKey: "name")
                        user.setValue(dict["first_name"] as? String ?? "unkwown", forKey: "first_name")
                        user.setValue(dict["last_name"] as? String ?? "unkwown", forKey: "last_name")
                        user.setValue(dict["email"] as? String ?? "unkwown", forKey: "email")
                        user.setValue(dict["phone_number"] as? String ?? "unkwown", forKey: "phone_number")
                        user.setValue(dict["tenant"] as? String ?? "unkwown", forKey: "tenant")
                        user.setValue(dict["zipcode"] as? String ?? "unkwown", forKey: "zipcode")
                        user.setValue(dict["profile_photo"] as? String ?? "unkwown", forKey: "profile_photo")
                        user.setValue(dict["guid"] as? String ?? "unknown", forKey: "guid")
                        self.users.append(user)
                        group.leave()
                        
                        do {
                            try context.save()
                        } catch let error as NSError {
                            print("Could not save. \(error), \(error.userInfo)")
                        }
                    })
                }
                group.notify(queue: .main, execute: {
                    self.mainTable.refreshControl?.endRefreshing()
                    self.updateUsersArray(users: self.users)
                })
            })
            
//            HTTP_Client.sharedHTTPClient.performGETRequest(completion: { (users) in
//                self.mainTable.refreshControl?.endRefreshing()
//                self.updateUsersArray(users: users)
//            })
        
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
        let cell = tableView.dequeueReusableCell(withIdentifier: ProfileSummaryView.cellIdentifier, for: indexPath) as? ProfileSummaryCell
        cell?.title.text = user.name
        return cell!
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let storyboard = UIStoryboard(name: "ProfileView", bundle: nil)
        if let vc = storyboard.instantiateViewController(withIdentifier: "ProfileView") as? ProfileView {
            let user = users[indexPath.row]
            selectedUser = user
            vc.userGuid = selectedUser?.guid
            vc.profileViewDelegate = self
            self.navigationController!.pushViewController(vc, animated: true)
        }
    
        
    }
}

//  =================================================================================================
//  ProfileView Delegate Methods
//  =================================================================================================
extension ProfileSummaryView: ProfileViewDelegate {
    func didTapBackButton() {
        self.mainTable.beginRefreshing()
        //updateCells()
    }
    

}
