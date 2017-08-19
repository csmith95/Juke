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
    public static var stream: Models.FirebaseStream!
    public static func isHost() -> Bool {
        return Current.user.username == Current.stream.host.username
    }
    public static var accessToken = ""

    // idea: make stream a computed property -- refer to firebase everytime it's accessed throughout code
//    public static var stream {
//        ref.child("/users/\(Current.user.spotifyID)/tunedInto").observeSingleEvent(of: .value, with: (snapshot) in
//            if snapshot.exists() {
//                
//            } else {
//            
//            }
//    }) { error in print(error.localizedDescription)}
//    }
}
