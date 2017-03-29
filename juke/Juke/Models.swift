//
//  Models.swift
//  Juke
//
//  Created by Conner Smith on 3/28/17.
//  Copyright © 2017 csmith. All rights reserved.
//

import Foundation
import Unbox

class Models {
    
    struct Song {
        let songName: String
        let artistName: String
        let spotifyID: String
        let progress: Double    // progress in song, synced with owner's device
        let duration: Double
    }
    
    struct User {
        let spotifyID: String
        let username: String
        let tunedIntoStream: String
    }
    
    struct Stream {
        let owner: User
        let members: [User]
        let id: String
        let songs: [Song]
    }
    
}

extension Models.Song: Unboxable {
    init(unboxer: Unboxer) throws {
        self.songName = try unboxer.unbox(key: "songName")
        self.artistName = try unboxer.unbox(key: "artistName")
        self.spotifyID = try unboxer.unbox(key: "spotifyID")
        self.progress = try unboxer.unbox(key: "progress")
        self.duration = try unboxer.unbox(key: "duration")

    }
}

extension Models.User: Unboxable {
    init(unboxer: Unboxer) throws {
        self.spotifyID = try unboxer.unbox(key: "spotifyID")
        self.username = try unboxer.unbox(key: "username")
        self.tunedIntoStream = try unboxer.unbox(key: "tunedIntoStream")
    }
}

extension Models.Stream: Unboxable {
    init(unboxer: Unboxer) throws {
        self.owner = try unboxer.unbox(key: "owner")
        self.members = try unboxer.unbox(key: "members")
        self.id = try unboxer.unbox(key: "id")
        self.songs = try unboxer.unbox(key: "songs")
    }
}

