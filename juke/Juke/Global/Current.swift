//
//  Current.swift
//  Juke
//
//  Created by Conner Smith on 4/2/17.
//  Copyright © 2017 csmith. All rights reserved.
//

import Foundation
import Firebase

class Current {
    private static let ref = Database.database().reference()
    public static var user: Models.FirebaseUser!
    public static var stream: Models.FirebaseStream! = Models.FirebaseStream()
    public static func isHost() -> Bool {
        guard let stream = Current.stream else { return false }
        return stream.host.spotifyID == Current.user.spotifyID
    }
    public static var listenSelected: Bool = false // if user has listen button selected -- used in jamsPlayer.resync
    public static var accessToken = ""
}
