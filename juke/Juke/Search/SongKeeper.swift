//
//  SongKeeper.swift
//  Juke
//
//  Created by Conner Smith on 9/25/17.
//  Copyright © 2017 csmith. All rights reserved.
//

import Foundation

// this class is to keep a set of all the songs a user has added during
// any given "session" (visit) to the MyLibrary tab or Search tab so we
// the add song indicator doesn't sometimes flash between states -- better 
// alternative to always setting add button to enabled when cell is loaded.
// set is cleared whenever either of those tabs disappears
class SongKeeper {
    
    // set for efficient look-up
    public static var addedSongs = Set<String>()
    
}
