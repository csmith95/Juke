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
        var key: String?       // key in db -- helpful for access if queued (/streams/{streamID}/{key} list)
                                // but not needed for top song (/streams/{streamID}/song object) -- just set to "song"
        
        var spotifyID: String   // careful not to use this as key in DB
        var songName: String
        var artistName: String
        var duration: Double
        var votes: Int
        var coverArtURL: String
        var memberImageURL: String?
        
        // formatted to be written directly to /streams/{streamID}/song/ or /songs/{streamID}/{key}/
        var firebaseDict: [String: Any?] {
            return ["spotifyID": self.spotifyID, "songName":self.songName,
                    "artistName": self.artistName, "coverArtURL": self.coverArtURL,
                    "memberImageURL": self.memberImageURL, "votes": self.votes,
                    "duration": self.duration
                    ]
        }
        
        init?(dict: [String: Any?]) {
            guard let spotifyID = dict["spotifyID"] as? String else { return nil }
            guard let songName = dict["songName"] as? String else { return nil }
            guard let artistName = dict["artistName"] as? String else { return nil }
            guard let coverArtURL = dict["coverArtURL"] as? String else { return nil }
            guard let votes = dict["votes"] as? Int else { return nil }
            guard let duration = dict["duration"] as? Double else { return nil }
            
            self.spotifyID = spotifyID
            self.songName = songName
            self.artistName = artistName
            self.coverArtURL = coverArtURL
            self.votes = votes
            self.duration = duration
            self.memberImageURL = dict["memberImageURL"] as? String
            self.key = dict["key"] as? String
        }
        
        init?(snapshot: DataSnapshot) {
            var dict = snapshot.value as! [String: Any?]
            dict["key"] = snapshot.key
            self.init(dict: dict)
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
    
    struct FirebaseMember {
        var username: String
        var imageURL: String?
        
        var firebaseDict: [String: Any?] {
            return [self.username: self.imageURL]
        }
        
        init?(dict: [String: Any?]) {
            guard let username = dict["username"] as? String else { return nil }
            self.username = username
            self.imageURL = dict["username"] as? String
        }
        
        init(username: String, imageURL: String?) {
            self.username = username
            self.imageURL = imageURL
        }
    }
    
    struct FirebaseStream {
        var streamID: String            // key in /streams table and /songs table
        var host: FirebaseMember
        var members: [FirebaseMember] = []
        var isPlaying: Bool = false
        var song: FirebaseSong? = nil
        
        // formatted to be written directly to the /streams/{streamID} path
        var firebaseDict: [String: Any?] {
            var dict: [String: Any?] = [:]
            dict = ["host": host.firebaseDict,
                    "members": host.firebaseDict,
                    "isPlaying": self.isPlaying,
                    "song": self.song?.firebaseDict]
            return dict
        }
        
        init?(dict: [String: Any?]) {
            guard let streamID = dict["streamID"] as? String else { return nil }
            guard let isPlaying = dict["isPlaying"] as? Bool else { return nil }
            guard let hostDict = dict["host"] as? [String: String?] else { return nil }
            self.host = FirebaseMember(username: hostDict.first!.key, imageURL: hostDict.first?.value)
            
            if let memberDict = dict["members"] as? [String: String] {
                for mem in memberDict {
                    self.members.append(FirebaseMember(username: mem.key, imageURL: mem.value))
                }
            }
        
            self.streamID = streamID
            self.isPlaying = isPlaying
            // this song dict is not going to have a key
            if let songDict = dict["song"] as? [String: Any?], let song = FirebaseSong(dict: songDict) {
                self.song = song
            }
        }
        
        init?(snapshot: DataSnapshot) {
            var dict = snapshot.value as! [String: Any?]
            dict["streamID"] = snapshot.key
            print(dict)
            self.init(dict: dict)
        }
        
        // called to generate new stream with solely host
        init(host: FirebaseMember) {
            let streamID = ref.childByAutoId().key
            self.streamID = streamID
            self.host = host
            self.members = [host]
        }
        
    }
    
    struct FirebaseUser {
        var spotifyID: String   // key in the /users table
        var tunedInto: String?
        var username: String
        var imageURL: String?
        var online: Bool
        
        init(dict: [String: Any?]) {
            self.spotifyID = dict["spotifyID"] as! String
            self.tunedInto = dict["tunedInto"] as? String
            self.username = dict["username"] as! String
            self.imageURL = dict["imageURL"] as? String
            self.online = dict["online"] as! Bool
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

