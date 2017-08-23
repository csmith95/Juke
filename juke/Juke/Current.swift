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
    public static var stream: Models.FirebaseStream! = Models.FirebaseStream()  // empty at first
    public static func isHost() -> Bool {
        print(Current.stream)
        print(Current.user)
        return Current.stream.host.spotifyID == Current.user.spotifyID
    }
    public static var accessToken = ""
}
