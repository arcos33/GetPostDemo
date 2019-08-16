//
//  HTTP_Client.swift
//  PolarityTE
//
//  Created by Joel Arcos on 12/4/18.
//  Copyright © 2018 Joel Arcos. All rights reserved.
//

import UIKit

typealias JSONObject = [String: Any]
typealias HTTPStatusCode = Int
typealias JSON = [String: Any]
typealias Dict = [String: Any]
typealias StatusCode = Int

struct FieldNames {
    static let name = "name"
    static let fName = "first_name"
    static let lName = "last_name"
    static let phone = "phone_number"
    static let email = "email"
    static let zip = "zipcode"
    static let photo = "profile_photo"
    static let tenant = "tenant"
    static let guid = "guid"
}

struct HTTPCommonNames {
    static let contentTypeValue = "application/json"
    static let contentTypeKey = "Content-Type"
    static let get = "GET"
    static let patch = "PATCH"
    static let post = "POST"
}

enum MyError: Error {
    case runtimeError(String)
}

//  =================================================================================================
//  iVars Methods
//  =================================================================================================
class HTTP_Client {
    
    static let sharedHTTPClient = HTTP_Client()
    struct Authentication {
        static let name = "X-api-key"
        static let key = "TqzKu0n0kW7uI5GkghsK76jMxLa4Km0EadtnmSM7"
    }
    let session = URLSession(configuration: URLSessionConfiguration.default)
}

//  =================================================================================================
//  API Methods
//  =================================================================================================
extension HTTP_Client {
    func getAllUsers(completion: @escaping ([UserObject]?, String?) -> ()) {
        let urlString = "\(urls.getUsers)"
        guard let url = URL(string: urlString) else { return }
        var request = URLRequest(url: url, cachePolicy: .reloadIgnoringCacheData, timeoutInterval: 5)
        request.httpMethod = HTTPCommonNames.get
        request.addValue(Authentication.key, forHTTPHeaderField: Authentication.name)
        request.addValue(HTTPCommonNames.contentTypeValue, forHTTPHeaderField: HTTPCommonNames.contentTypeKey)
        
        let task = session.dataTask(with: request) { (data, response, error) in
            
            guard let data = data else { return }
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [JSON] {
                    var userIds = [String]()
                    for dict in json {
                        if let guid = dict["guid"] as? String {
                            userIds.append(guid)
                        }
                    }
                    
                    var users = [UserObject]()
                    let _group = DispatchGroup()
                    for id in userIds {
                        _group.enter()
                        self.performGETRequestForUserWithGUID(group: _group, guid: id, completion: { (jsonArray, message) in

                            guard let _jsonArray = jsonArray else { return }
                            
                            for dict in _jsonArray {
                                if let name = dict[FieldNames.name] as? String,
                                    let fName = dict[FieldNames.fName] as? String,
                                    let lName = dict[FieldNames.lName] as? String,
                                    let email = dict[FieldNames.email] as? String,
                                    let phone = dict[FieldNames.phone] as? String,
                                    let zip = dict[FieldNames.zip] as? String,
                                    let tenant = dict[FieldNames.tenant] as? String,
                                    let photo = dict[FieldNames.photo] as? String,
                                    let guid = dict[FieldNames.guid] as? String {
                                    
                                    let user = UserObject.init(name: name, first_name: fName, last_name: lName, email: email, phone: phone, zip: zip, tenant: tenant, photo: photo, guid: guid)
                                    users.append(user)
                                }
                            }
                        })
                    }
                    _group.notify(queue: .main, execute: {
                        completion(users, nil)
                    })
                } else if let json =  try JSONSerialization.jsonObject(with: data, options: []) as? JSON {
                    if let message = json["message"] as? String {
                        completion(nil, message)
                    }
                } else {
                    throw MyError.runtimeError("Unexpected response from server")
                }
            } catch {
                print(error.localizedDescription)
            }
        }
        task.resume()
    }
    
    func performPOSTRequest(user: UserObject, completion: @escaping (StatusCode, String) -> ()) {
        let urlString = "\(urls.getUsers)"
        guard let url = URL(string: urlString) else { return }
        var request = URLRequest(url: url, cachePolicy: .reloadIgnoringCacheData, timeoutInterval: 5)
        request.httpMethod = HTTPCommonNames.post
        request.addValue(Authentication.key, forHTTPHeaderField: Authentication.name)
        request.addValue(HTTPCommonNames.contentTypeValue, forHTTPHeaderField: HTTPCommonNames.contentTypeKey)
        populateBody(user: user, request: &request)
        
        let task = session.dataTask(with: request as URLRequest) { (data, response, error) in
            guard let data = data else { return }

            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? JSON {
                    if let guid = json[FieldNames.guid] as? String {
                        if let statusCode = (response as? HTTPURLResponse)?.statusCode {
                            completion(statusCode, guid)
                        }
                    }
                }
            } catch let error {
                print(error.localizedDescription)
            }
        }
        task.resume()
    }
    
    func updateUser(user: UserObject, completion: @escaping (StatusCode) -> ()) {
        let urlString = "\(urls.getUsers)/\(user.guid!)"
        guard let url = URL(string: urlString) else { return }
        var request = URLRequest(url: url, cachePolicy: .reloadIgnoringCacheData, timeoutInterval: 5)
        request.httpMethod = HTTPCommonNames.patch
        request.addValue(Authentication.key, forHTTPHeaderField: Authentication.name)
        
        populateBody(user: user, request: &request)
        
        let task = session.dataTask(with: request as URLRequest) { (data, response, error) in
            if let statusCode = (response as? HTTPURLResponse)?.statusCode {
                completion(statusCode)
            }
        }
        task.resume()
    }
}

//  =================================================================================================
//  Internal Methods
//  =================================================================================================
extension HTTP_Client {
    
    internal func performGETRequestForUserWithGUID(group: DispatchGroup, guid: String, completion: @escaping ([JSON]?, String?) -> ()) {
        
        let urlString = "\(urls.getUsers)/\(guid)"
        guard let url = URL(string: urlString) else { return }
        var request = URLRequest(url: url, cachePolicy: .reloadIgnoringCacheData, timeoutInterval: 5)
        request.httpMethod = HTTPCommonNames.get
        request.addValue(Authentication.key, forHTTPHeaderField: Authentication.name)
        request.addValue(HTTPCommonNames.contentTypeValue, forHTTPHeaderField: HTTPCommonNames.contentTypeKey)
        
        
        let task = session.dataTask(with: request) { (data, response, error) in
            group.leave()
            guard let data = data else { return }
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [JSON] {
                    completion(json, nil)
                } else {
                    throw MyError.runtimeError("Unexpected response from server")
                }
            } catch {
                print(error.localizedDescription)
            }
        }
        task.resume()
    }
    
    internal func populateBody(user: UserObject, request: inout URLRequest) {
        guard let photo = user.photo,
            let name = user.name,
            let fName = user.first_name,
            let lName = user.last_name,
            let phone = user.phone,
            let email = user.email,
            let zip = user.zip,
            let tenant = user.tenant else { return }
        
        let params = [ FieldNames.phone:phone,
                       FieldNames.name:name,
                       FieldNames.zip:zip,
                       FieldNames.email:email,
                       FieldNames.tenant:tenant,
                       FieldNames.fName:fName,
                       FieldNames.lName:lName,
                       FieldNames.photo:photo]
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: params, options: [])
        } catch {
            print(error.localizedDescription)
        }
    }
}
