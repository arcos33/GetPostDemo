//
//  HTTP_Client.swift
//  PolarityTE
//
//  Created by Joel Arcos on 12/4/18.
//  Copyright © 2018 Joel Arcos. All rights reserved.
//

import Foundation

typealias JSONObject = [String: Any]
typealias HTTPStatusCode = Int

class HTTP_Client {
    
    static let shared = HTTP_Client()
    
    func createUser() {
        let configuration = URLSessionConfiguration.default
        let session = URLSession(configuration: configuration)
        
        let urlString = "\(urls.getUsers)"
        guard let url = URL(string: urlString) else { return }
        var request = URLRequest(url: url, cachePolicy: .reloadIgnoringCacheData, timeoutInterval: 5)
        request.httpMethod = "POST"
        request.addValue("TqzKu0n0kW7uI5GkghsK76jMxLa4Km0EadtnmSM7", forHTTPHeaderField: "X-api-key")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        let params = createBody()
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: params, options: [])
        } catch {
            print(error.localizedDescription)
        }
        
        let task = session.dataTask(with: request) { (data, response, error) in
            guard let data = data else { return }
            
            do {
                let user = JSONDecoder().decode(<#T##type: Decodable.Protocol##Decodable.Protocol#>, from: data)
            }
            
            let jsonString = String.init(data: data, encoding: String.Encoding.utf8)
            print(jsonString!)
            print("")
            
            }.resume()
    }
    
    fileprivate func createBody() -> [String: String] {
        return [    "phone_number":"801-123-5555",
                          "name":"Mike Tyson",
                          "zipcode":"84065",
                          "email":"mt@gmail.com",
                          "tenant":"Punching time!",
                          "first_name":"Mike",
                          "last_name":"Tyson",
                          "profile_photo":"test-image"]
        
        
    }
}
