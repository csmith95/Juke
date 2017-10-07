//
//  TokenManager.swift
//  Juke
//
//  Created by Conner Smith on 9/19/17.
//  Copyright © 2017 csmith. All rights reserved.
//

import Foundation
import Alamofire

final class SessionManager {
    
    private static let userDefaults = UserDefaults.standard
    public static var session: SPTSession! {
        didSet {
            SPTAuth.defaultInstance().session = session
            let sessionData = NSKeyedArchiver.archivedData(withRootObject: session)
            self.userDefaults.set(sessionData, forKey: Constants.kSpotifySessionKey)
            self.userDefaults.synchronize()
        }
    }
    
    public static var accessToken: String? {
        get {
            if session == nil || !session.isValid() { return nil }
            return session.accessToken
        }
    }
    
    public static func storeSession(session: SPTSession) {
        let sessionData = NSKeyedArchiver.archivedData(withRootObject: session)
        userDefaults.set(sessionData, forKey: Constants.kSpotifySessionKey)
        self.session = session
        // notify spotify login controller to dismiss webview and initiate loginSegue
        NotificationCenter.default.post(name: Notification.Name("loginSuccessful"), object: nil)
    }
    
    public static func fetchSession() -> SPTSession? {
        if let sessionData = userDefaults.object(forKey: Constants.kSpotifySessionKey) as? Data {
            self.session = NSKeyedUnarchiver.unarchiveObject(with: sessionData) as? SPTSession
            return session
        }
        return nil
    }
    
    public static func refreshSession(completionHandler: @escaping (Bool)->Void) {
        print("refreshing spotify access token...")
        SPTAuth.defaultInstance().renewSession(self.session, callback: { (error, renewedSession) in
            if let err = error { print("Error renewing session: \(err)"); completionHandler(false); return; }
            if let session = renewedSession {
                self.session = session
                print("refreshed succeeded!")
                completionHandler(true)
            } else {
                print("refresh failed :(")
                completionHandler(false)
            }
        })
    }
    
    public static func executeWithToken(callback: @escaping (String?)->Void) {
        objc_sync_enter(self)
        
        if session != nil && session.isValid() && accessToken != nil {
            // good to go
            callback(accessToken)
            objc_sync_exit(self)
        } else {
            refreshSession() { success in
                callback(self.accessToken)
                objc_sync_exit(self)
            }
        }
    }
}
