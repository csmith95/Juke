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
        var socketID: String?
    }
    
    struct SpotifyUser {
        let spotifyID: String
        let username: String?
        let imageURL: String?
    }
    
    struct Stream {
        let owner: User
        let owner_name: String?
        let members: [User]
        let streamID: String
        var songs: [Song]
        let isLive: Bool
        var isPlaying: Bool
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
        self.socketID = unboxer.unbox(keyPath: "socketID")
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
        self.owner_name = unboxer.unbox(key: "owner_name")
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

