//
//  Constants.swift
//  Juke
//
//  Created by Conner Smith on 3/9/17.
//  Copyright © 2017 csmith. All rights reserved.
//

import Foundation

public class Constants {
    
    static let kSpotifyBaseURL = "https://api.spotify.com/v1/"
    static let kSpotifySearchURL = Constants.kSpotifyBaseURL + "search/"
    static let kSpotifyTrackDataURL = Constants.kSpotifyBaseURL + "tracks/"
    static let kCurrentUserPath = "me"
    static let kAddSongByIDPath = "me/tracks?ids="
    static let kDeleteSongByIDPath = "me/tracks?ids="
    static let kContainsSongPath = "me/tracks/contains?ids="
    static let kSendNotificationsURL = "https://us-central1-juke-9fbd6.cloudfunctions.net/sendNotification"
    static let kSpotifySessionKey = "SpotifySession"    // key session is stored as in user defaults
    
}
