//
//  HTTP_Client.swift
//  PolarityTE
//
//  Created by Joel Arcos on 12/4/18.
//  Copyright © 2018 Joel Arcos. All rights reserved.
//

import UIKit
import CoreData

typealias JSONObject = [String: Any]
typealias HTTPStatusCode = Int


class HTTP_Client {

    static let sharedHTTPClient = HTTP_Client()
    struct Authentication {
        static let name = "X-api-key"
        static let key = "TqzKu0n0kW7uI5GkghsK76jMxLa4Km0EadtnmSM7"
    }
    
    func performRequestOfType(requestType: String, completion: @escaping ([User]) -> ()) {
        let configuration = URLSessionConfiguration.default
        let session = URLSession(configuration: configuration)
        
        let urlString = "\(urls.getUsers)"
        guard let url = URL(string: urlString) else { return }
        var request = NSMutableURLRequest(url: url, cachePolicy: .reloadIgnoringCacheData, timeoutInterval: 5)
        request.httpMethod = requestType
        request.addValue(Authentication.key, forHTTPHeaderField: Authentication.name)
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        switch requestType {
        case "POST" :
            populateBody(request: &request)
        case "GET":
            break
        default:
            print("Other type of request: \(requestType)")
        }
        
        let task = session.dataTask(with: request as URLRequest) { (data, response, error) in
            guard let data = data else { return }
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [[String: Any]] {
                        var users = [User]()
                    for dict in json {
                        
                        DispatchQueue.main.async(execute: {
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
                            
                            do {
                                try context.save()
                                users.append(user)
                                completion(users)
                            } catch let error as NSError {
                                completion([User]())
                                print("Could not save. \(error), \(error.userInfo)")
                            }
                        })

                        
                        
                    }
                }
            } catch {
                print(error.localizedDescription)
            }
        }
        task.resume()
    }
    
    fileprivate func populateBody(request: inout NSMutableURLRequest) {
        
        let params = [    "phone_number":"801-123-5555",
                          "name":"Mike Tyson",
                          "zipcode":"84065",
                          "email":"mt@gmail.com",
                          "tenant":"Punching time!",
                          "first_name":"Mike",
                          "last_name":"Tyson",
                          "profile_photo":"test-image"]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: params, options: [])
        } catch {
            print(error.localizedDescription)
        }
    }
    
}
