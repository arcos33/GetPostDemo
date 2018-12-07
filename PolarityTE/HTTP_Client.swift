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
    func performGETRequest(completion: @escaping ([JSON]?, String?) -> ()) {
        let urlString = "\(urls.getUsers)"
        guard let url = URL(string: urlString) else { return }
        var request = URLRequest(url: url, cachePolicy: .reloadIgnoringCacheData, timeoutInterval: 5)
        request.httpMethod = "GET"
        request.addValue(Authentication.key, forHTTPHeaderField: Authentication.name)
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let task = session.dataTask(with: request) { (data, response, error) in
            
            guard let data = data else { return }
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [JSON] {
                    completion(json, nil)
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
    
    func performPOSTRequest(user: UserObject, completion: @escaping (StatusCode) -> ()) {
        let urlString = "\(urls.getUsers)"
        guard let url = URL(string: urlString) else { return }
        var request = URLRequest(url: url, cachePolicy: .reloadIgnoringCacheData, timeoutInterval: 5)
        request.httpMethod = "POST"
        request.addValue(Authentication.key, forHTTPHeaderField: Authentication.name)
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        populateBody(user: user, request: &request)
        
        let task = session.dataTask(with: request as URLRequest) { (data, response, error) in
            if let statusCode = (response as? HTTPURLResponse)?.statusCode {
                completion(statusCode)
            }
        }
        task.resume()
    }
    
    func updateUser(user: UserObject, completion: @escaping (StatusCode) -> ()) {
        let urlString = "\(urls.getUsers)/\(user.guid!)"
        guard let url = URL(string: urlString) else { return }
        var request = URLRequest(url: url, cachePolicy: .reloadIgnoringCacheData, timeoutInterval: 5)
        request.httpMethod = "PATCH"
        request.addValue(Authentication.key, forHTTPHeaderField: Authentication.name)
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
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
    
    internal func populateBody(user: UserObject, request: inout URLRequest) {
        let params = [ "phone_number":user.phone!,
                      "name":user.name!,
                      "zipcode":user.zip!,
                      "email":user.email!,
                      "tenant":user.tenant!,
                      "first_name":user.first_name!,
                      "last_name":user.last_name!,
                      "profile_photo":user.photo!]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: params, options: [])
        } catch {
            print(error.localizedDescription)
        }
    }
}
