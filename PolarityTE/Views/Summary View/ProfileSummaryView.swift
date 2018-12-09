//
//  ViewController.swift
//  PolarityTE
//
//  Created by Joel Arcos on 12/4/18.
//  Copyright © 2018 Joel Arcos. All rights reserved.
//

import UIKit
import CoreData

typealias Closure = () -> ()

//  =================================================================================================
//  iVars
//  =================================================================================================
class ProfileSummaryView: UIViewController {
    static let cellIdentifier = "cellId"
    var users = [User]()
    var arrayOfUserStructs = [UserObject]()
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
        
        setupTable()
        fetchCoreDataForAllUserRecords { (users) in
            self.updateUsersArray(users: users)
        }
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
//  Core Data Methods
//  =================================================================================================
extension ProfileSummaryView {
    internal func saveUserObjectsToCoreData(users: [UserObject], _ completion: @escaping ([User])->() ) {
        var userArray = [User]()
        let context = self.getContext()
        let userEntity = NSEntityDescription.entity(forEntityName: "User", in: context)!
        let _group = DispatchGroup()
        for user in users {
            _group.enter()
            let cdUser = NSManagedObject(entity: userEntity, insertInto: context) as! User
            cdUser.setValue(user.name, forKey: FieldNames.name)
            cdUser.setValue(user.first_name, forKey: FieldNames.fName)
            cdUser.setValue(user.last_name, forKey: FieldNames.lName)
            cdUser.setValue(user.email, forKey: FieldNames.email)
            cdUser.setValue(user.phone, forKey: FieldNames.phone)
            cdUser.setValue(user.zip, forKey: FieldNames.zip)
            cdUser.setValue(user.tenant, forKey: FieldNames.tenant)
            cdUser.setValue(user.guid, forKey: FieldNames.guid)
            cdUser.setValue(user.photo, forKey: FieldNames.photo)
            do {
                try context.save()
                userArray.append(cdUser)
                _group.leave()
            } catch let error as NSError {
                print("Could not save. \(error), \(error.userInfo)")
            }
        }
        _group.notify(queue: .main) {
            completion(userArray)
        }
    }
    
    internal func fetchCoreDataForAllUserRecords(completion: @escaping ([User])->()) {
        let request = NSFetchRequest<User>(entityName: "User")
        request.returnsObjectsAsFaults = false
        var _users = [User]()
        let _group = DispatchGroup()
        do {
            let result = try getContext().fetch(request)
            for user in result {
                _group.enter()
                _users.append(user)
                _group.leave()
            }
            _group.notify(queue: .main) {
                completion(_users)
            }
        } catch let error as NSError {
            print(error.description)
        }
    }
    
    internal func deleteUserRecords(_ completion: () -> ()) {
        // Create Fetch Request
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "User")
        
        // Create Batch Delete Request
        let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        
        do {
            let context = getContext()
            try context.execute(batchDeleteRequest)
            completion()
        } catch {
            print(error.localizedDescription)
        }
    }
    
    internal func getContext() -> NSManagedObjectContext {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        return appDelegate.persistentContainer.viewContext
    }
}


//  =================================================================================================
//  Internal Methods
//  =================================================================================================
extension ProfileSummaryView {
    internal func getUsersFromServer(completion: @escaping ([User])->()) {
        HTTP_Client.sharedHTTPClient.getAllUsers { (userObjects, message) in
            if let userObjts = userObjects {
                self.deleteUserRecords {
                    self.saveUserObjectsToCoreData(users: userObjts, { (users) in
                        completion(users)
                    })
                }
            }
        }
    }
}

//  =================================================================================================
//  Internal Tableview Methods
//  =================================================================================================
extension ProfileSummaryView {
    fileprivate func updateUsersArray(users: [User]) {
        self.users = users
        self.users.sort(by: {$0.name!.localizedCaseInsensitiveCompare($1.name!) == ComparisonResult.orderedAscending})
        
        self.mainTable.reloadData()
        self.titleLBL.text = "\(users.count) Users"
        self.mainTable.refreshControl?.endRefreshing()
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
        self.mainTable.isUserInteractionEnabled = false;
        deleteUserRecords {
            self.getUsersFromServer(completion: { (_users) in
                self.updateUsersArray(users: _users)
                self.mainTable.isUserInteractionEnabled = true
            })
        }
    }
}

//  =================================================================================================
//  TableView Delegate & Datasource Methods
//  =================================================================================================
extension ProfileSummaryView: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return users.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let user = users[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: ProfileSummaryView.cellIdentifier, for: indexPath) as? ProfileSummaryCell
        cell?.title.text = user.name
        cell?.profilePhotoIV.image = user.profile_photo?.convertBase64ToImage()
        return cell!
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let storyboard = UIStoryboard(name: "ProfileView", bundle: nil)
        if let vc = storyboard.instantiateViewController(withIdentifier: "ProfileView") as? ProfileView {
            let user = users[indexPath.row]
            vc.userGuid = user.guid
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
        fetchCoreDataForAllUserRecords { (_users) in
            self.updateUsersArray(users: _users)
        }
    }
}
