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
    public static var user: Models.User!
    public static var stream: Models.Stream!
    public static var fetched: Bool = false
    public static func isHost() -> Bool {
        return CurrentUser.user.id == CurrentUser.stream.owner.id
    }
}
