//
//  Models.swift
//  Juke
//
//  Created by Conner Smith on 3/28/17.
//  Copyright © 2017 csmith. All rights reserved.
//

import Foundation
import Unbox

// the database models should match these almost **exactly** (except for the coverArt optional)
// for any requests to our server, use these names to encode parameters.
// for Spotify requests, see Spotify docs online.
class Models {
    
    struct Song {
        let songName: String
        let artistName: String
        let spotifyID: String
        let progress: Double    // progress in song, synced with owner's device
        let duration: Double
        let coverArtURL: String
        var coverArt: UIImage?  // fetched lazily later -- not stored in DB
    }
    
    struct User {
        let spotifyID: String
        let username: String
        let imageURL: String
        let tunedInto: String?  // null if user doesn't have a stream
    }
    
    struct SpotifyUser {
        let spotifyID: String
        let username: String
        let imageURL: String
    }
    
    struct Stream {
        let owner: User
        let members: [User]
        let streamID: String
        var songs: [Song]
        let isLive: Bool
    }
    
}

extension Models.Song: Unboxable {
    init(unboxer: Unboxer) throws {
        self.songName = try unboxer.unbox(key: "songName")
        self.artistName = try unboxer.unbox(key: "artistName")
        self.spotifyID = try unboxer.unbox(key: "spotifyID")
        self.progress = try unboxer.unbox(key: "progress")
        self.duration = try unboxer.unbox(key: "duration")
        self.coverArtURL = try unboxer.unbox(key: "coverArtURL")
        self.coverArt = nil
    }
}

extension Models.User: Unboxable {
    init(unboxer: Unboxer) throws {
        self.spotifyID = try unboxer.unbox(key: "spotifyID")
        self.username = try unboxer.unbox(key: "username")
        self.imageURL = try unboxer.unbox(key: "imageURL")
        self.tunedInto = try unboxer.unbox(key: "tunedInto")
    }
}

extension Models.SpotifyUser: Unboxable {
    init(unboxer: Unboxer) throws {
        self.spotifyID = try unboxer.unbox(key: "id")
        self.username = try unboxer.unbox(key: "display_name")
        self.imageURL = try unboxer.unbox(keyPath: "images.0.url")
    }
}

extension Models.Stream: Unboxable {
    init(unboxer: Unboxer) throws {
        self.owner = try unboxer.unbox(key: "owner")
        self.members = try unboxer.unbox(key: "members")
        self.streamID = try unboxer.unbox(key: "_id")
        self.songs = try unboxer.unbox(key: "songs")
        self.isLive = try unboxer.unbox(key: "isLive")
    }
}

