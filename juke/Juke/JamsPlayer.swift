//
//  JamsPlayer.swift
//  Juke
//
//  Created by Conner Smith on 3/8/17.
//  Copyright © 2017 csmith. All rights reserved.
//

import Foundation

class JamsPlayer  {
    
    let userDefaults = UserDefaults.standard
    static let sharedInstance = SPTAudioStreamingController.sharedInstance()
    var session: SPTSession? = nil
    
    //This prevents others from using the default '()' initializer for this class.
    private init() {
        print("JAMS!")
        refreshSession()
    }
    
    private func refreshSession() {
        if let sessionObj = userDefaults.object(forKey: "SpotifySession") {
            let sessionDataObj = sessionObj as! Data
            self.session = NSKeyedUnarchiver.unarchiveObject(with: sessionDataObj) as? SPTSession
        }
    }
    
    public func playTrack(trackUri: String) {
        if self.session != nil {
            
//            try {
//                let req = SPTTrack.createRequest(forTrack: URL(string: trackUri), withAccessToken: session!.accessToken, market: nil)
//                task = URLSession.shared.dataTask(with: req, completionHandler: callback)
//                task.resume()
//            catch {
//                    
//            }
//            
//            SPTRequest.requestItemAtURI(NSURL(string: trackUri), withSession: session, callback: { (error:NSError!, trackObj:AnyObject!) -> Void in
//             if error != nil {
//                println("Album lookup got error \(error)")
//                return
//             }
//             
//             let track = trackObj as SPTTrack
//             
//             self.player?.playTrackProvider(track, callback: nil)
//            })
        }
    
    }
    
    public func pause() {
    
    
    }

}
