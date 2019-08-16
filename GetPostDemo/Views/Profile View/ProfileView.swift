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

private var myContext = 0
//  =================================================================================================
//  iVars
//  =================================================================================================
class ProfileView: UIViewController {
    var userGuid: String!
    var profileViewDelegate: ProfileViewDelegate!
    var didInteractWithUser = false
    var viewAdjustment: CGFloat = 0
    var isShowingLowerHalfOfScreen = false
    @objc var statemachine = StateMachine()

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
//  Lifecycle
//  =================================================================================================
extension ProfileView {
    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
        addObserver(self, forKeyPath: #keyPath(statemachine.currentState), options: [.old, .new], context: &myContext)
        self.statemachine.setNewState(self.statemachine.initialState!)
        self.hideKeyboardWhenTappedAround()
        findSelectedUser {
            if self.isRequiredDataInputed() == true {
                self.statemachine.validate(completed: true)
            }
        }
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if context == &myContext {
            if let newState = change?[.newKey] as? ProfileState {
                switch newState {
                case is InitialState:
                    submitBTN.isEnabled = false
                    print("no input")
                case is SomeInputReceived:
                    submitBTN.isEnabled = false
                    print("some input")
                case is FinalState:
                    submitBTN.isEnabled = true
                    print("final state")
                default:
                    print("undefined state")
                }
            }
        }
    }
}

//  =================================================================================================
//  UITextField delegate methods
//  =================================================================================================
extension ProfileView: UITextFieldDelegate {
    
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        if textField == phoneNumberTF || textField == zipCodeTF || textField == tenantTF {
            if !isShowingLowerHalfOfScreen {
                UIView.animate(withDuration: 1.0) {
                    self.view.frame.origin.y -= self.viewAdjustment
                }
                isShowingLowerHalfOfScreen = true
            }
        }
        return true
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if isRequiredDataInputed() == true {
            self.statemachine.validate(completed: true)
        } else {
            self.statemachine.validate(completed: false)
        }
        return true
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
        if (isRequiredDataInputed() == true) {
            didInteractWithUser = true
            
            if self.submitBTN.titleLabel?.text == "Update User" {
                updateUser()
            } else {
                createNewUser()
            }
        } else {
            self.showAlert(message: "All fields must be entered and an image must be seleted to update", closeTitle: "Close", callback: nil)
        }
    }
}

//  =================================================================================================
//  Core Data methods
//  =================================================================================================
extension ProfileView {
    internal func insertUserRecord(withGUID guid: String, _ user: UserObject, completion: @escaping ()->Void) {
        DispatchQueue.main.async {
            let context = self.getContext()
            let entity = NSEntityDescription.entity(forEntityName: "User", in: context)
            let newUser = NSManagedObject(entity: entity!, insertInto: context)
            newUser.setValue(guid, forKey: FieldNames.guid)
            newUser.setValue(user.name, forKey: FieldNames.name)
            newUser.setValue(user.first_name, forKey: FieldNames.fName)
            newUser.setValue(user.last_name, forKey: FieldNames.lName)
            newUser.setValue(user.email, forKey: FieldNames.email)
            newUser.setValue(user.phone, forKey: FieldNames.phone)
            newUser.setValue(user.tenant, forKey: FieldNames.tenant)
            newUser.setValue(user.photo, forKey: FieldNames.photo)
            newUser.setValue(user.zip, forKey: FieldNames.zip)
            do {
                try context.save()
                completion()
            } catch {
                print("Failed saving")
            }
        }
    }
    
    internal func updateCoreDataRecord(withGUID guid: String, _ completion: @escaping Closure) {
        DispatchQueue.main.async {
            let fetchRequest = NSFetchRequest<User>(entityName: "User")
            fetchRequest.returnsObjectsAsFaults = false
            
            fetchRequest.predicate = NSPredicate(format: "guid = %@",
                                                 argumentArray: [guid])
            
            do {
                let results = try self.getContext().fetch(fetchRequest)
                
                if results.count != 0 {
                    results[0].setValue(self.nameTF.text!, forKey: FieldNames.name)
                    results[0].setValue(self.firstNameTF.text!, forKey: FieldNames.fName)
                    results[0].setValue(self.lastNameTF.text!, forKey: FieldNames.lName)
                    results[0].setValue(self.zipCodeTF.text!, forKey: FieldNames.zip)
                    results[0].setValue(self.phoneNumberTF.text!, forKey: FieldNames.phone)
                    results[0].setValue(self.tenantTF.text!, forKey: FieldNames.tenant)
                    results[0].setValue(self.avatarImage.image?.convertImageToBase64(), forKey: FieldNames.photo)
                    results[0].setValue(self.emailTF.text!, forKey: FieldNames.email)
                }
            } catch {
                print("Fetch Failed: \(error)")
            }
            
            do {
                try self.getContext().save()
                completion()
            }
            catch {
                print("Saving Core Data Failed: \(error)")
            }
        }
    }
    
    internal func getContext() -> NSManagedObjectContext {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        return appDelegate.persistentContainer.viewContext
    }
    
    func fetchUserWithId(guid: String, completion: @escaping (User) -> ()) {
        DispatchQueue.main.async {
            let context = self.getContext()
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
    }
}

//  =================================================================================================
//  Keyboard Notification methods
//  =================================================================================================
extension ProfileView {
    @objc func keyboardWillShow(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            if self.view.frame.origin.y == 0 {
                self.viewAdjustment = keyboardSize.height
            }
        }
    }
    
    @objc func keyboardWillHide(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            if self.view.frame.origin.y != 0 {
                self.view.frame.origin.y += keyboardSize.height
            }
        }
        isShowingLowerHalfOfScreen = false
    }
}

//  =================================================================================================
//  Internal methods
//  =================================================================================================
extension ProfileView {
    internal func isRequiredDataInputed() -> Bool {
        if (self.nameTF.text?.isEmpty)! ||
            (self.firstNameTF.text?.isEmpty)! ||
            (self.lastNameTF.text?.isEmpty)! ||
            (self.emailTF.text?.isEmpty)! ||
            (self.phoneNumberTF.text?.isEmpty)! ||
            (self.zipCodeTF.text?.isEmpty)! ||
            (self.tenantTF.text?.isEmpty)! ||
            (self.avatarImage.image == #imageLiteral(resourceName: "man-user") ){
            return false
        } else {
            return true
        }
    }

    internal func findSelectedUser(completion: @escaping Closure) {
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
                self.avatarImage.image = user.profile_photo?.convertBase64ToImage() != nil ? user.profile_photo?.convertBase64ToImage() : #imageLiteral(resourceName: "man-user")
                completion()
            }
        } else {
            self.submitBTN.setTitle("Create User", for: .normal)
        }
    }
    
    internal func createNewUser() {
        DispatchQueue.main.async { self.showActivityIndicatorOverlay() }
        
        performPOSTRequestAndSaveToCoreData()
    }
    
    internal func performPOSTRequestAndSaveToCoreData() {
        let user = populateUserObject()

        HTTP_Client.sharedHTTPClient.performPOSTRequest(user: user) { (statusCode, guid)  in
            DispatchQueue.main.sync(execute: {
                self.hideActivityIndicatorOverlay()
            })
            if statusCode == 201 {
                self.insertUserRecord(withGUID:guid, user, completion: {
                    self.showAlert(message: "Record was created successfully", closeTitle: "Close", callback: { (action) in
                        self.profileViewDelegate.didTapBackButton()
                        self.navigationController?.popViewController(animated: true)
                    })
                })
            } else {
                self.showAlert(message: "Problem creating user, status:\(statusCode)", closeTitle: "OK", callback: nil)
            }
        }
    }
    
    internal func updateUser() {
        DispatchQueue.main.async { self.showActivityIndicatorOverlay() }
        
        performPATCHRequestAndUpdateCoreData()
    }
    
    internal func performPATCHRequestAndUpdateCoreData() {
        let user = populateUserObject()
        
        HTTP_Client.sharedHTTPClient.updateUser(user: user) { (statusCode) in
            DispatchQueue.main.async(execute: {
                self.hideActivityIndicatorOverlay()
            })
            if statusCode == 204 {
                self.updateCoreDataRecord(withGUID: user.guid!, {
                    self.didInteractWithUser = true
                    self.showAlert(message: "Record updated Successfully", closeTitle: "OK", callback: { (action) in
                        self.navigationController?.popViewController(animated: true)
                        self.profileViewDelegate.didTapBackButton()
                    })
                })
            } else {
                self.showAlert(message: "Problem updating, status:\(statusCode)", closeTitle: "OK", callback: nil)
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
        user.photo = self.avatarImage.image?.convertImageToBase64() ?? ""
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
            myPickerController.delegate = self
            myPickerController.sourceType = .photoLibrary
            self.present(myPickerController, animated: true, completion: nil)
        }
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            let scaledImage = scaleImage(with: image, scaledTo: CGSize.init(width: 400, height: 400))
            self.avatarImage.image = scaledImage
            if isRequiredDataInputed() == true {
                self.statemachine.validate(completed: true)
            }
            
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
