//
//  ServerConstants.swift
//  Juke
//
//  Created by Conner Smith on 3/9/17.
//  Copyright © 2017 csmith. All rights reserved.
//

import Foundation

public class ServerConstants {
    
    // juke & spotify server base URLs
    static let kJukeServerURL = "http://myjukebx.herokuapp.com/"
//    static let kJukeServerURL = "http://localhost:8000/"
    static let kSpotifyBaseURL = "https://api.spotify.com/v1/"
    
    // spotify full URLs
    static let kSpotifySearchURL = ServerConstants.kSpotifyBaseURL + "search/"
    static let kSpotifyTrackDataURL = ServerConstants.kSpotifyBaseURL + "tracks/"
    
    // juke server paths
    static let kAddSongPath = "addSong"
    static let kFetchStreamsPath = "fetchStreams"
    static let kFetchSongsPath = "fetchSongs"
    static let kAddUser = "addUser"
    static let kFetchStream = "fetchStream"
    static let kChangeOnlineStatus = "changeOnlineStatus"
    static let kSplitFromStream = "splitFromStream"
    static let kFetchFriends = "getFriends"
    
    // spotify paths
    static let kCurrentUserPath = "me"
    static let kAddSongByIDPath = "me/tracks?ids="
    static let kContainsSongPath = "me/tracks/contains?ids="
}
