//
//  Current.swift
//  Juke
//
//  Created by Conner Smith on 4/2/17.
//  Copyright © 2017 csmith. All rights reserved.
//

import Foundation
import Firebase

class Current {
    private static let jamsPlayer = JamsPlayer.shared
    private static let ref = Database.database().reference()
    public static var user: Models.FirebaseUser?
    public static var stream: Models.FirebaseStream? {
    
        willSet(newValue) {
            if let currentStream = stream, let newStream = newValue {
                if currentStream.streamID == newStream.streamID {
                    return
                }
            }
            
            let current = stream
            FirebaseAPI.leaveStream(current: current) {
                // once user has left current stream, join new stream
                FirebaseAPI.joinStream(newStream: newValue)   // sets user tunedInto field in db
                FirebaseAPI.addListeners()
                // this event is listened for in MyStreamRootViewController to handle transitioning between container views
                if stream == nil {
                    jamsPlayer.position_ms = 0.0
                }
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: Notification.Name("userStreamChanged"), object: nil)
                }
            }
        }
    }
    public static func isHost() -> Bool {
        guard let stream = Current.stream else { return false }
        guard let user = Current.user else { return false }
        return stream.host.spotifyID == user.spotifyID
    }
    public static var listenSelected: Bool = false // if user has listen button selected -- used in jamsPlayer.resync
    public static var accessToken = ""
}
