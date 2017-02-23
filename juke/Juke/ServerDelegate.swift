//
//  ServerDelegate.swift
//  Juke
//
//  Created by Conner Smith on 2/20/17.
//  Copyright © 2017 csmith. All rights reserved.
//

import Foundation

class ServerDelegate {
    
    let kBaseURL = "http://myjukebx.herokuapp.com/"
    let kRequestMethod = "POST"
    
    // issues postRequest using fields specified as key-val pairs in NSDictionary, then executes callback with received data
    func postRequest(query: String, fields : NSDictionary, callback : @escaping (Data?, URLResponse?, Error?) -> Void) {
        var request = URLRequest(url: URL(string: kBaseURL + query)!)
        request.httpMethod = kRequestMethod
        let bodyString = createBodyString(fields: fields)
        request.httpBody = bodyString.data(using: .utf8)
        print("REQUEST: ", request)
        print("BODY STRING: ", bodyString)
        let task = URLSession.shared.dataTask(with: request, completionHandler: callback)
        task.resume()
    }
    
    private func createBodyString(fields: NSDictionary) -> String {
        var postString = ""
        var i = 1
        for (key, value) in fields {
            postString += String(describing: key) + "=" + String(describing: value)
            if i < fields.count {
                postString += "&"
            }
            i += 1
        }
        return postString
    }
    
}
