//
//  ServerConstants.swift
//  Juke
//
//  Created by Conner Smith on 3/9/17.
//  Copyright © 2017 csmith. All rights reserved.
//

import Foundation

public class ServerConstants {
    
    // server base URLs -- remember to use local IP if running off localhost because dbs have different content
    //static let kJukeServerURL = "http://myjukebx.herokuapp.com/"
    static let kJukeServerURL = "http://localhost:8000/"
    
    static let kSpotifyBaseURL = "https://api.spotify.com/v1/"
    static let kSpotifySearchURL = ServerConstants.kSpotifyBaseURL + "search/"
    static let kSpotifyTrackDataURL = ServerConstants.kSpotifyBaseURL + "tracks/"
    
    // juke paths
    static let kAddSongPath = "addSong"
    static let kFetchStreamsPath = "fetchStreams"
    static let kFetchSongsPath = "fetchSongs"
    static let kPopSong = "popSong"
    static let kAddUser = "addUser"
    static let kFetchStream = "fetchStream"
    static let kChangeOnlineStatus = "changeOnlineStatus"
    static let kSplitFromStream = "splitFromStream"
    static let kReturnToPersonalStream = "returnToPersonalStream"
    
    //spotify paths
    static let kCurrentUserPath = "me"
}
