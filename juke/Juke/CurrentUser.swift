//
//  CurrentUser.swift
//  Juke
//
//  Created by Conner Smith on 4/2/17.
//  Copyright © 2017 csmith. All rights reserved.
//

import Foundation
import Unbox

class CurrentUser {
    public static var user: Models.FirebaseUser!
    public static var stream: Models.FirebaseStream!
    public static func isHost() -> Bool {
        return CurrentUser.user.username == CurrentUser.stream.host.username
    }
    public static var accessToken = ""
}
