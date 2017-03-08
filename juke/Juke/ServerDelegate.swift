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
    let kSpotifyBaseURL = "https://api.spotify.com/v1/search"
    
    // issues postRequest using fields specified as key-val pairs in NSDictionary, then executes callback with received data
    func postRequest(path: String, fields : NSDictionary, callback : @escaping (Data?, URLResponse?, Error?) -> Void) {
        var request = URLRequest(url: URL(string: kBaseURL + path)!)
        request.httpMethod = "POST"
        let bodyString = createBodyString(fields: fields)
        request.httpBody = bodyString.data(using: .utf8)
        let task = URLSession.shared.dataTask(with: request, completionHandler: callback)
        task.resume()
    }
    
    func getRequest(path: String, fields : NSDictionary, callback : @escaping (Data?, URLResponse?, Error?) -> Void) {
        let queryString = createBodyString(fields: fields)
        var request = URLRequest(url: URL(string: kBaseURL + path + "?" + queryString)!)
        request.httpMethod = "GET"
        print("REQUEST: ", request)
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
    
    func spotifyGetRequest(path: String, fields : NSDictionary, callback : @escaping (Data?, URLResponse?, Error?) -> Void) {
        let queryString = createBodyString(fields: fields)
        var request = URLRequest(url: URL(string: kSpotifyBaseURL + path + "?" + queryString)!)
        request.httpMethod = "GET"
        print("REQUEST: ", request)
        let task = URLSession.shared.dataTask(with: request, completionHandler: callback)
        task.resume()
    }
    
}
