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
    public static var user: Models.FirebaseUser?
    private static var didChangeStreams = true
    public static var stream: Models.FirebaseStream? {
    
        willSet(newValue) {
            if let currentStream = stream, let newStream = newValue {
                if currentStream.streamID == newStream.streamID {
                    didChangeStreams = false // to avoid adding listeners multiple times in didSet -- leads to vicious cycle
                    return  // do nothing if same stream
                }
            }
            didChangeStreams = true
            
            let current = stream    // make a copy and pass to leaveStream otherwise concurrency issues
            FirebaseAPI.leaveStream(current: current) {
                // once user has left current stream, join new stream
                FirebaseAPI.joinStream(newStream: newValue)   // sets user tunedInto field in db
                if stream == nil {
                    jamsPlayer.position_ms = 0.0
                }
            }
        }
        
        didSet(newValue) {
            if didChangeStreams {
                FirebaseAPI.addListeners()
            }
            NotificationCenter.default.post(name: Notification.Name("updateMyStreamView"), object: nil)
        }
    }
    public static func isHost() -> Bool {
        guard let stream = Current.stream else { return false }
        guard let user = Current.user else { return false }
        return stream.host.spotifyID == user.spotifyID
    }
    public static var listenSelected: Bool = false // if user has listen button selected -- used in jamsPlayer.resync
    
    // MARK: cached copy of starred user spotify IDs from StarredUsersDataSource.swift
    private static var starredUsers = Set<String>()
    
    public static func addStarredUser(user: Models.FirebaseUser) {
        starredUsers.insert(user.spotifyID)
    }
    
    public static func removeStarredUser(user: Models.FirebaseUser) {
        starredUsers.remove(user.spotifyID)
    }
    
    public static func isStarred(user: Models.FirebaseUser) -> Bool {
        return starredUsers.contains(where: { (spotifyID) -> Bool in
            return spotifyID == user.spotifyID
        })
    }
    
    public static func isStarred(spotifyID: String?) -> Bool {
        guard let spotifyID = spotifyID else { return false }
        return starredUsers.contains(where: { (otherSpotifyID) -> Bool in
            return spotifyID == otherSpotifyID
        })
    }
    
}
