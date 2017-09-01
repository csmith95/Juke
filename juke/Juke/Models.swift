
//
//  Models.swift
//  Juke
//
//  Created by Conner Smith on 3/28/17.
//  Copyright © 2017 csmith. All rights reserved.
//

import Foundation
import Unbox
import Firebase

// the database models should match these almost **exactly** (except for the coverArt optional)
// for any requests to our server, use these names to encode parameters.
// for Spotify requests, see Spotify docs online.
class Models {
    
    private static let ref = Database.database().reference()
    
    struct FirebaseSong {
        var key: String       // key in db -- helpful for access if queued (/streams/{streamID}/{key} list)
                                // but not needed for top song (/streams/{streamID}/song object) -- just set to "song"
        
        var spotifyID: String   // careful not to use this as key in DB
        var songName: String
        var artistName: String
        var duration: Double
        var votes: Int
        var coverArtURL: String
        var memberImageURL: String?
        var upvoters: [String: Bool] = [:]
        
        // formatted to be written directly to /streams/{streamID}/song/ or /songs/{streamID}/{key}/
        var firebaseDict: [String: Any] {
            var dict: [String: Any] = ["spotifyID": self.spotifyID, "songName":self.songName,
                    "artistName": self.artistName, "coverArtURL": self.coverArtURL,
                    "votes": self.votes,
                    "duration": self.duration,
                    "upvoters": upvoters
                    ]
            if let memberImageURL = self.memberImageURL {
                dict["memberImageURL"] = memberImageURL
            }
            return dict
        }
        
        init?(dict: [String: Any?]) {
            guard let spotifyID = dict["spotifyID"] as? String else { return nil }
            guard let songName = dict["songName"] as? String else { return nil }
            guard let artistName = dict["artistName"] as? String else { return nil }
            guard let coverArtURL = dict["coverArtURL"] as? String else { return nil }
            guard let votes = dict["votes"] as? Int else { return nil }
            guard let duration = dict["duration"] as? Double else { return nil }
            guard let key = dict["key"] as? String else { return nil }
            
            self.spotifyID = spotifyID
            self.songName = songName
            self.artistName = artistName
            self.coverArtURL = coverArtURL
            self.votes = votes
            self.duration = duration
            self.memberImageURL = dict["memberImageURL"] as? String
            self.key = key
            self.upvoters = dict["upvoters"] as? [String: Bool] ?? [:]
        }
        
        init?(snapshot: DataSnapshot) {
            if snapshot.exists(), var dict = snapshot.value as? [String: Any?] {
                dict["key"] = snapshot.key
                self.init(dict: dict)
            } else {
                return nil
            }
        }
        
        init(song: Models.SpotifySong) {
            self.key = ref.child("/songs/\(Current.stream.streamID)/").childByAutoId().key
            self.spotifyID = song.spotifyID
            self.artistName = song.artistName
            self.duration = song.duration
            self.songName = song.songName
            self.coverArtURL = song.coverArtURL
            self.memberImageURL = Current.user.imageURL
            self.votes = 0
        }
    }
    
    struct FirebaseStream {
        var streamID: String            // key in /streams table and /songs table
        var isPlaying: Bool = false
        var song: FirebaseSong? = nil
        var host: FirebaseUser! = Current.user
        var members: [FirebaseUser] = []
        
        // formatted to be written directly to the /streams/{streamID}/ path
        var firebaseDict: [String: Any] {
            var dict: [String: Any] = ["isPlaying": self.isPlaying,
                                       "song": NSNull()]
            dict["host"] = [host.spotifyID: host.firebaseDict]
            var result: [String: Any] = [:]
            for member in members {
                result[member.spotifyID] = member.firebaseDict
            }
            dict["members"] = result
            if let song = self.song {
                dict["song"] = song.firebaseDict
            }
            
            return dict
        }
        
        init?(dict: [String: Any?]) {
            guard let streamID = dict["streamID"] as? String else { return nil }
            guard let isPlaying = dict["isPlaying"] as? Bool else { return nil }
            self.streamID = streamID
            self.isPlaying = isPlaying
            // jesus this is tedious
            let otherDict = dict["host"] as! [String: Any?]
            var userDict = otherDict.first!.value as! [String: Any?]
            userDict["spotifyID"] = otherDict.first!.key
            self.host = FirebaseUser(dict: userDict)
            
            if let membersDict = dict["members"] as? [String: Any?] {
                for member in membersDict {
                    var memberDict = member.value as! [String: Any?]
                    memberDict["spotifyID"] = member.key
                    guard let parsedMember = FirebaseUser(dict: memberDict) else { return }
                    self.members.append(parsedMember)
                }
            }
            
            if var songDict = dict["song"] as? [String: Any?] {
                songDict["key"] = "song"    // placeholder key
                if let song = FirebaseSong(dict: songDict) {
                    self.song = song
                }
            }
        }
        
        init?(snapshot: DataSnapshot) {
            guard var dict = snapshot.value as? [String: Any?] else { return nil }
            dict["streamID"] = snapshot.key
            self.init(dict: dict)
        }
        
        // called to generate new stream with solely host
        init() {
            let streamID = ref.childByAutoId().key
            self.streamID = streamID
        }
    }
    
    struct FirebaseUser {
        var spotifyID: String   // key in the /users table
        var tunedInto: String?
        var username: String
        var imageURL: String?
        var online: Bool
        var fcmToken: String?
        
        // formatted to be written to /hosts/{streamID}/{spotifyID}/
        // or /users/{spotifyID}/
        var firebaseDict: [String: Any] {
            var dict: [String: Any] = ["username": username,
                                        "online": online]
            if let tunedInto = tunedInto { dict["tunedInto"] = tunedInto }
            if let imageURL = imageURL { dict["imageURL"] = imageURL }
            if let fcmToken = fcmToken {dict["fcmToken"] = fcmToken }
            return dict
        }
        
        init?(dict: [String: Any?]) {
            guard let spotifyID = dict["spotifyID"] as? String else { return nil }
            guard let username = dict["username"] as? String else { return nil }
            guard let online = dict["online"] as? Bool else { return nil }
            
            self.spotifyID = spotifyID
            self.tunedInto = dict["tunedInto"] as? String
            self.username = username
            self.imageURL = dict["imageURL"] as? String
            self.online = online
            self.fcmToken = dict["fcmToken"] as? String
        }
        
        init?(snapshot: DataSnapshot) {
            var dict = snapshot.value as! [String: Any?]
            dict["spotifyID"] = snapshot.key
            self.init(dict: dict)
        }
    }
    
    struct SpotifySong {
        let songName: String
        let artistName: String
        let spotifyID: String
        let duration: Double
        let coverArtURL: String
    }
    
    struct SpotifyUser {
        let spotifyID: String
        let username: String?
        let imageURL: String?
    }
}

extension Models.SpotifyUser: Unboxable {
    init(unboxer: Unboxer) throws {
        self.spotifyID = try unboxer.unbox(key: "id")
        self.username = unboxer.unbox(key: "display_name")
        self.imageURL = unboxer.unbox(keyPath: "images.0.url")
    }
}

extension Models.SpotifySong: Unboxable {
    init(unboxer: Unboxer) throws {
        self.songName = try unboxer.unbox(key: "name")
        self.artistName = try unboxer.unbox(keyPath: "artists.0.name")
        self.spotifyID = try unboxer.unbox(key: "id")
        self.duration = try unboxer.unbox(key: "duration_ms")
        self.coverArtURL = try unboxer.unbox(keyPath: "album.images.1.url")
    }
}

