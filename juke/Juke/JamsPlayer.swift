//
//  JamsPlayer.swift
//  Juke
//
//  Created by Conner Smith on 3/8/17.
//  Copyright © 2017 csmith. All rights reserved.
//

import Foundation

class JamsPlayer: NSObject, SPTAudioStreamingDelegate {
    
    static let shared = JamsPlayer()
    let userDefaults = UserDefaults.standard
    let sharedInstance = SPTAudioStreamingController.sharedInstance()
    var session: SPTSession? = nil
    let kClientID = "77d4489425fe464483f0934f99847c8b"
    
    override private init() {
        super.init()
        do {
            try sharedInstance?.start(withClientId: kClientID)
            sharedInstance?.delegate = self
            refreshSession()
        } catch let err {
            print(err)
        }
    }
    
    func audioStreamingDidLogin(_ audioStreaming: SPTAudioStreamingController!) {
        print("AudioStreamer logged in!")
    }
    
    func audioStreaming(_ audioStreaming: SPTAudioStreamingController!, didReceiveError error: Error!) {
        print(error)
    }
    
    func audioStreaming(_ audioStreaming: SPTAudioStreamingController!, didReceiveMessage message: String!) {
        print("Received message: ", message)
    }
    
    private func refreshSession() {
        if (session != nil && sharedInstance!.loggedIn && session!.isValid()) {
            return
        }
        
        if let sessionObj = userDefaults.object(forKey: "SpotifySession") {
            let sessionDataObj = sessionObj as! Data
            self.session = NSKeyedUnarchiver.unarchiveObject(with: sessionDataObj) as? SPTSession
            let token:String = session?.accessToken as String!
            self.sharedInstance?.login(withAccessToken: token)
        }
    }
    
    public func playSong(trackID: String) {
        refreshSession()
        if let session = self.session {
            if !session.isValid() {
                print("session no longer valid")
                return
            }
            let uri = "spotify:track:" + trackID
            sharedInstance?.playSpotifyURI(uri, startingWith: 0, startingWithPosition: 0, callback: { (error) in
                if let error = error {
                    print(error)
                }
            })
        }
    
    }
}


