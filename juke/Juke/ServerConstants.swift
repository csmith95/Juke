//
//  ServerConstants.swift
//  Juke
//
//  Created by Conner Smith on 3/9/17.
//  Copyright © 2017 csmith. All rights reserved.
//

import Foundation

public class ServerConstants {
    
    // server base URLs
    static let kJukeServerURL = "http://myjukebx.herokuapp.com/"
    static let kSpotifySearchURL = "https://api.spotify.com/v1/search"
    static let kSpotifyTrackDataURL = "https://api.spotify.com/v1/tracks/"
    
    // paths
    static let kAddSongPath = "addSong"
    static let kFetchNearbyPath = "findNearbyGroups"
    static let kCreateGroupPath = "createGroup"
    static let kUpdateLocationPath = "updateGroupLocation"
    static let kFetchSongsPath = "fetchSongs"
    static let kPopSong = "popSong"
}
