//
//  MyLibraryCell.swift
//  Juke
//
//  Created by Conner Smith on 9/12/17.
//  Copyright © 2017 csmith. All rights reserved.
//

import UIKit
import PKHUD

class MyLibraryCell: SearchCell {

    override func handleAddButtonPressed() {
        print("\n*** song getting queued: ", self.song)
        FirebaseAPI.queueSong(spotifySong: self.song)
        HUD.flash(.labeledSuccess(title: nil, subtitle: "Added \(self.song.songName) to your stream"), delay: 1.0)
    }

}
