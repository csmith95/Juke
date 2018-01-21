
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
import MediaPlayer

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
        var coverArtURL: String
        var memberImageURL: String?
        var memberSpotifyID: String?
        var upvoters: [String: Bool] = [:]
        var image: MPMediaItemArtwork?
        var timestamp: Double?
        
        // formatted to be written directly to /streams/{streamID}/song/ or /songs/{streamID}/{key}/
        var firebaseDict: [String: Any] {
            var dict: [String: Any] = ["spotifyID": self.spotifyID, "songName":self.songName,
                    "artistName": self.artistName, "coverArtURL": self.coverArtURL,
                    "duration": self.duration,
                    "upvoters": upvoters,
                    ]
            if let memberImageURL = self.memberImageURL {
                dict["memberImageURL"] = memberImageURL
            }
            if let memberSpotifyID = self.memberSpotifyID {
                dict["memberSpotifyID"] = memberSpotifyID
            }
            if let timestamp = self.timestamp {
                dict["timestamp"] = timestamp
            }
            return dict
        }
        
        init?(dict: [String: Any?]) {
            guard let spotifyID = dict["spotifyID"] as? String else { return nil }
            guard let songName = dict["songName"] as? String else { return nil }
            guard let artistName = dict["artistName"] as? String else { return nil }
            guard let coverArtURL = dict["coverArtURL"] as? String else { return nil }
            guard let duration = dict["duration"] as? Double else { return nil }
            guard let key = dict["key"] as? String else { return nil }
            
            self.spotifyID = spotifyID
            self.songName = songName
            self.artistName = artistName
            self.coverArtURL = coverArtURL
            self.duration = duration
            self.memberImageURL = dict["memberImageURL"] as? String
            self.memberSpotifyID = dict["memberSpotifyID"] as? String
            self.key = key
            self.upvoters = dict["upvoters"] as? [String: Bool] ?? [:]
            if let timestamp = dict["timestamp"] as? Double {
                self.timestamp = timestamp
            }
        }
        
        init?(snapshot: DataSnapshot) {
            if snapshot.exists(), var dict = snapshot.value as? [String: Any?] {
                dict["key"] = snapshot.key
                self.init(dict: dict)
            } else {
                return nil
            }
        }
        
        init?(song: Models.SpotifySong) {
            guard let stream = Current.stream else { return nil }
            self.key = ref.child("/songs/\(stream.streamID)/").childByAutoId().key
            self.spotifyID = song.spotifyID
            self.artistName = song.artistName
            self.duration = song.duration
            self.songName = song.songName
            self.coverArtURL = song.coverArtURL
            self.memberImageURL = Current.user?.imageURL
            self.memberSpotifyID = Current.user?.spotifyID
            self.upvoters = [:]
            self.timestamp = NSDate().timeIntervalSince1970
        }
    }
    
    struct FirebaseStream {
        var streamID: String            // key in /streams table and /songs table
        var isPlaying: Bool = false
        var song: FirebaseSong? = nil
        var host: FirebaseUser! = Current.user
        var members: [FirebaseUser] = []
        var title = ""
        var timestamp: Double?
        var isFeatured: Bool?
        
        // formatted to be written directly to the /streams/{streamID}/ path
        var firebaseDict: [String: Any] {
            var dict: [String: Any] = ["isPlaying": self.isPlaying,
                                       "song": NSNull(),
                                       "title": self.title,
                                       "isFeatured": false
                                       ]
            dict["host"] = [host.spotifyID: host.firebaseDict]
            var result: [String: Any] = [:]
            for member in members {
                result[member.spotifyID] = member.firebaseDict
            }
            dict["members"] = result
            if let song = self.song {
                dict["song"] = song.firebaseDict
            }
            if let timestamp = self.timestamp {
                dict["timestamp"] = timestamp
            }
            return dict
        }
        
        init?(dict: [String: Any?]) {
            guard let streamID = dict["streamID"] as? String else { return nil }
            guard let isPlaying = dict["isPlaying"] as? Bool else { return nil }
            self.timestamp = dict["timestamp"] as? Double
            self.isFeatured = dict["isFeatured"] as? Bool
            self.title = dict["title"] as? String ?? "Stream Title"

            self.streamID = streamID
            self.isPlaying = isPlaying
            // jesus this is tedious
            guard let otherDict = dict["host"] as? [String: Any?] else { return nil }
            guard let spotifyID = otherDict.first?.key else { return nil }
            guard var userDict = otherDict.first?.value as? [String: Any?] else { return nil }
            userDict["spotifyID"] = spotifyID
            guard let host = FirebaseUser(dict: userDict) else { return nil }
            self.host = host
            
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
            self.title = "\(Current.user!.username)'s Stream"
            self.timestamp = NSDate().timeIntervalSince1970
            self.isFeatured = false
        }
    }
    
    struct FirebaseUser: Hashable {
        var spotifyID: String   // key in the /users table
        var tunedInto: String?
        var username: String
        var imageURL: String?
        var online: Bool
        var fcmToken: String?
        var onboard: Bool?
        var hashValue: Int {
            return self.spotifyID.hashValue
        }
        
        // formatted to be written to /hosts/{streamID}/{spotifyID}/
        // or /users/{spotifyID}/
        var firebaseDict: [String: Any] {
            var dict: [String: Any] = ["username": username,
                                        "online": online]
            if let tunedInto = tunedInto { dict["tunedInto"] = tunedInto }
            if let imageURL = imageURL { dict["imageURL"] = imageURL }
            if let fcmToken = fcmToken {dict["fcmToken"] = fcmToken }
            if let onboard = onboard {dict["onboard"] = onboard }
            return dict
        }
        
        static func ==(lhs: Models.FirebaseUser, rhs: Models.FirebaseUser) -> Bool {
            return lhs.hashValue == rhs.hashValue
        }
        
        init?(dict: [String: Any?]) {
            guard let spotifyID = dict["spotifyID"] as? String else { return nil }
            guard let username = dict["username"] as? String else { return nil }
            guard let online = dict["online"] as? Bool else { return nil }
            //guard let onboard = dict["onboard"] as? Bool else { return nil }
            
            self.spotifyID = spotifyID
            self.tunedInto = dict["tunedInto"] as? String
            self.username = username
            self.imageURL = dict["imageURL"] as? String
            self.online = online
            self.fcmToken = dict["fcmToken"] as? String
            self.onboard = dict["onboard"] as? Bool
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
    
    struct SpotifyPlaylist {
        let spotifyID: String
        let ownerUsername: String?
        let imageURL: String
        let tracksURL: String
        let name: String
    }
}

extension Models.SpotifyPlaylist: Unboxable {
    init(unboxer: Unboxer) throws {
        self.spotifyID = try unboxer.unbox(key: "id")
        self.ownerUsername = unboxer.unbox(keyPath: "owner.display_name")
        self.imageURL = try unboxer.unbox(keyPath: "images.0.url")
        self.tracksURL = try unboxer.unbox(keyPath: "tracks.href")
        self.name = try unboxer.unbox(key: "name")
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

