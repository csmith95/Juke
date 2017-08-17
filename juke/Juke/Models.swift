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
    
    struct FirebaseSong {
        var spotifyID: String
        var songName: String
        var artistName: String
        var duration: Double
        var votes: Int
        var coverArtURL: String
        
        // TODO
//        var json: [String: Any] {}
        
        // TODO
//        init(snapshot: DataSnapshot) {}
        
        init(dict: [String: Any]) {
            self.spotifyID = dict["spotifyID"] as! String
            self.songName = dict["songName"] as! String
            self.artistName = dict["artistName"] as! String
            self.coverArtURL = dict["coverArtURL"] as! String
            self.votes = dict["votes"] as! Int
            self.duration = dict["duration"] as! Double
        }
        
    }
    
    struct FirebaseMember {
        var username: String
        var imageURL: String?
        
        // TODO
//        var json: [String: Any] {}
        
        // TODO
//        init(snapshot: DataSnapshot) {}
        
        init(username: String, imageURL: String?) {
            self.username = username; self.imageURL = imageURL
        }
    }
    
    struct FirebaseStream {
        var streamID: String
        var host: FirebaseMember
        var members: [FirebaseMember] = []
        var isPlaying: Bool
        var song: FirebaseSong?
        
        // TODO: for easily converting to json
//        var json: [String: Any] {
//            return [
//                "streamID" : self.streamID,
//                "host": self.host.json,
//                "members": self.members.json,
//                "playStatus": self.playStatus,
//                "song": self.song.json
//            ]
//        }
        
        init(snapshot: DataSnapshot) {
            let dict = snapshot.value as! [String: Any]
            self.streamID = snapshot.key
            let v = dict["host"] as! [String: String]
            self.host = FirebaseMember(username: v.keys.first!, imageURL: v.values.first)
            for keyValPair in dict["members"] as! [String: String] {
                self.members.append(FirebaseMember(username: keyValPair.key, imageURL: keyValPair.value))
            }
            self.isPlaying = dict["isPlaying"] as! Bool
            if let dict = dict["song"] as? [String: Any] {
                self.song = FirebaseSong(dict: dict)
            }
        }
    }
    
    
    // ******** above here are the firebase structs *********
    
    
    struct Song {
        let songName: String
        let artistName: String
        let spotifyID: String
        var progress: Double    // progress in song, synced with owner's device
        let duration: Double
        let coverArtURL: String
        let id: String
        let memberImageURL: String?
    }
    
    struct SpotifySong {
        let songName: String
        let artistName: String
        let spotifyID: String
        let duration: Double
        let coverArtURL: String
    }
    
    struct User {
        let spotifyID: String
        let username: String?
        let imageURL: String?
        let id: String
        var tunedInto: String?   // streamID
        var image: UIImage?
    }
    
    struct SpotifyUser {
        let spotifyID: String
        let username: String?
        let imageURL: String?
    }
    
    struct Stream {
        let owner: User
        let members: [User]
        let streamID: String
        var songs: [Song]
        let isLive: Bool
        var isPlaying: Bool
    }
}

//extension Models.FirebaseSong: Unboxable {
//    init(unboxer: Unboxer) throws {
//        self.songName = try unboxer.unbox(key: "songName")
//        self.artistName = try unboxer.unbox(key: "artistName")
//        self.spotifyID = try unboxer.unbox(key: "spotifyID")
//        self.duration = try unboxer.unbox(key: "duration")
//        self.coverArtURL = try unboxer.unbox(key: "coverArtURL")
//        self.votes = try unboxer.unbox(key: "votes")
//    }
//}
//
//extension Models.FirebaseStream: Unboxable {
//    init(unboxer: Unboxer) throws {
//        self.host = try unboxer.unbox(key: "host")
//        self.members = try unboxer.unbox(key: "members")
//        self.streamID = try unboxer.unbox(keyPath: "keys.0")
//        self.song = try unboxer.unbox(key: "song")
//        self.playStatus = try unboxer.unbox(key: "playStatus")
//    }
//}
//
//extension Models.FirebaseMember: Unboxable {
//    init(unboxer: Unboxer) throws {
//        self.username = try unboxer.unbox(keyPath: "members.key")
//        self.imageURL = try unboxer.unbox(keyPath: "members.username.imageURL")
//    }
//}

extension Models.Song: Unboxable {
    init(unboxer: Unboxer) throws {
        self.songName = try unboxer.unbox(key: "songName")
        self.artistName = try unboxer.unbox(key: "artistName")
        self.spotifyID = try unboxer.unbox(key: "spotifyID")
        self.progress = try unboxer.unbox(key: "progress")
        self.duration = try unboxer.unbox(key: "duration")
        self.coverArtURL = try unboxer.unbox(key: "coverArtURL")
        self.id = try unboxer.unbox(key: "_id")
        self.memberImageURL = unboxer.unbox(key: "memberImageURL")
    }
}

extension Models.User: Unboxable {
    init(unboxer: Unboxer) throws {
        self.spotifyID = try unboxer.unbox(key: "spotifyID")
        self.username = unboxer.unbox(key: "username")
        self.imageURL = unboxer.unbox(key: "imageURL")
        self.tunedInto = unboxer.unbox(key: "tunedInto")
        self.id = try unboxer.unbox(key: "_id")
//        self.socketID = unboxer.unbox(key: "socketID")
    }
}

extension Models.SpotifyUser: Unboxable {
    init(unboxer: Unboxer) throws {
        self.spotifyID = try unboxer.unbox(key: "id")
        self.username = unboxer.unbox(key: "display_name")
        self.imageURL = unboxer.unbox(keyPath: "images.0.url")
    }
}

extension Models.Stream: Unboxable {
    init(unboxer: Unboxer) throws {
        self.owner = try unboxer.unbox(key: "owner")
        self.members = try unboxer.unbox(key: "members")
        self.streamID = try unboxer.unbox(key: "_id")
        self.songs = try unboxer.unbox(key: "songs")
        self.isLive = try unboxer.unbox(key: "isLive")
        self.isPlaying = try unboxer.unbox(key: "isPlaying")
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

