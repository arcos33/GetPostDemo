//
//  ProfileView.swift
//  PolarityTE
//
//  Created by Joel Arcos on 12/4/18.
//  Copyright © 2018 Joel Arcos. All rights reserved.
//

import UIKit
import CoreData

protocol ProfileViewDelegate {
    func didTapBackButton()
}

struct UserObject {
    var name: String? = nil
    var first_name: String? = nil
    var last_name: String? = nil
    var email: String? = nil
    var phone: String? = nil
    var zip: String? = nil
    var tenant: String? = nil
    var photo: String? = nil
    var guid: String? = nil
}


//  =================================================================================================
//  iVars
//  =================================================================================================
class ProfileView: UIViewController {
    var userGuid: String!
    var profileViewDelegate: ProfileViewDelegate!
    var didInteractWithUser = false
    
    @IBOutlet weak var avatarImage: UIImageView!
    @IBOutlet weak var nameTF: UITextField!
    @IBOutlet weak var lastNameTF: UITextField!
    @IBOutlet weak var firstNameTF: UITextField!
    @IBOutlet weak var emailTF: UITextField!
    @IBOutlet weak var phoneNumberTF: UITextField!
    @IBOutlet weak var zipCodeTF: UITextField!
    @IBOutlet weak var tenantTF: UITextField!
    @IBOutlet weak var submitBTN: UIButton!
}

//  =================================================================================================
//  UITextField delegate methods
//  =================================================================================================
extension ProfileView: UITextFieldDelegate {
    @objc func textFieldDidChange(_ textField: UITextField) {
    }
}

//  =================================================================================================
//  Lifecycle
//  =================================================================================================
extension ProfileView {
    override func viewDidLoad() {
        super.viewDidLoad()
        if let id = self.userGuid {
            self.submitBTN.setTitle("Update User", for: .normal)
            fetchUserWithId(guid: id) { (user) in
                self.nameTF.text = user.name
                self.firstNameTF.text = user.first_name
                self.lastNameTF.text = user.last_name
                self.emailTF.text = user.email
                self.phoneNumberTF.text = user.phone_number
                self.zipCodeTF.text = user.zipcode
                self.tenantTF.text = user.tenant
                self.avatarImage.image = user.profile_photo?.convertBase64ToImage()
            }
        } else {
            self.submitBTN.setTitle("Create User", for: .normal)
        }
    }
}

//  =================================================================================================
//  IBActions
//  =================================================================================================
extension ProfileView {
    @IBAction func accessPictures(_ sender: UIButton) {
        photoLibrary()
    }
    
    @IBAction func createUser(_ sender: UIButton) {
        if (self.nameTF.text?.isEmpty)! ||
            (self.firstNameTF.text?.isEmpty)! ||
            (self.lastNameTF.text?.isEmpty)! ||
            (self.emailTF.text?.isEmpty)! ||
            (self.phoneNumberTF.text?.isEmpty)! ||
            (self.zipCodeTF.text?.isEmpty)! ||
            (self.tenantTF.text?.isEmpty)! ||
            (self.avatarImage.image == nil){
            self.showAlert(message: "All fields must be entered and an image must be seleted to update", closeTitle: "Close", callback: nil)
            return
        }
        didInteractWithUser = true
        
        if self.submitBTN.titleLabel?.text == "Update User" {
            updateUser()
        } else {
            createNewUser()
        }
        
    }
}

//  =================================================================================================
//  Internal methods
//  =================================================================================================
extension ProfileView {
    fileprivate func getContext() -> NSManagedObjectContext {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        return appDelegate.persistentContainer.viewContext
    }
    
    func fetchUserWithId(guid: String, completion: (User) -> ()) {
        let context = getContext()
        let fetchRequest:NSFetchRequest<User> = User.fetchRequest()
        let predicate = NSPredicate(format: "guid = %d", argumentArray: [guid])
        fetchRequest.predicate = predicate
        let nameSort = NSSortDescriptor(key:"name", ascending:true)
        
        fetchRequest.sortDescriptors = [nameSort]
        do {
            let users = try context.fetch(fetchRequest)
            if let user = users.first {
                completion(user)
            }
        } catch {
            print(error.localizedDescription)
        }
    }
    
    internal func createNewUser() {
        let user = populateUserObject()
        
        HTTP_Client.sharedHTTPClient.performPOSTRequest(user: user) { (statusCode) in
            if statusCode == 201 {
                print("Record created Successfully")
                DispatchQueue.main.sync(execute: {
                    self.profileViewDelegate.didTapBackButton()
                    self.navigationController?.popViewController(animated: true)
                })
            }
        }
    }
    
    internal func updateUser() {
        let user = populateUserObject()
        
        HTTP_Client.sharedHTTPClient.updateUser(user: user) { (statusCode) in
            if statusCode == 204 {
                self.didInteractWithUser = true
                print("Record updated Successfully")
                DispatchQueue.main.sync(execute: {
                    self.profileViewDelegate.didTapBackButton()
                    self.navigationController?.popViewController(animated: true)
                })
            }
        }
    }
    
    internal func populateUserObject() -> UserObject {
        var user = UserObject()
        user.name = nameTF.text!
        user.first_name = firstNameTF.text!
        user.last_name = lastNameTF.text!
        user.phone = phoneNumberTF.text!
        user.email = emailTF.text!
        user.tenant = tenantTF.text!
        user.zip = zipCodeTF.text!
        user.photo = self.avatarImage.image?.convertImageToBase64()
        if self.submitBTN.titleLabel?.text == "Update User" {
            user.guid = userGuid
        } else {
            user.guid = nil
        }
        return user
    }
}

//  =================================================================================================
//  Photo Management Code
//  =================================================================================================

extension ProfileView: UIImagePickerControllerDelegate, UINavigationControllerDelegate  {
    func photoLibrary(){
        if UIImagePickerController.isSourceTypeAvailable(.photoLibrary){
            let myPickerController = UIImagePickerController()
            myPickerController.delegate = self as? UIImagePickerControllerDelegate & UINavigationControllerDelegate
            myPickerController.sourceType = .photoLibrary
            self.present(myPickerController, animated: true, completion: nil)
        }
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            let scaledImage = scaleImage(with: image, scaledTo: CGSize.init(width: 400, height: 400))
            self.avatarImage.image = scaledImage
            self.dismiss(animated: true, completion: nil)
        } else{
            print("Something went wrong with image")
        }
    }
    
    func scaleImage(with image: UIImage, scaledTo newSize: CGSize) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage ?? UIImage()
    }
}
