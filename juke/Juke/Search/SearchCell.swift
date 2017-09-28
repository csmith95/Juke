//
//  SearchCell.swift
//  Juke
//
//  Created by Kojo Worai Osei on 4/14/17.
//  Copyright © 2017 csmith. All rights reserved.
//

import UIKit
import PKHUD

class SearchCell: UITableViewCell {
    
    @IBOutlet var artistLabel: UILabel!
    @IBOutlet var songLabel: UILabel!
    @IBOutlet var addButton: UIButton!
    var song: Models.SpotifySong!

    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    func populateCell(song: Models.SpotifySong) {
        self.song = song
        artistLabel.text = song.artistName
        songLabel.text = song.songName
        
        // reset button
        if SongKeeper.addedSongs.contains(song.spotifyID) {
            addButton.isSelected = true
            addButton.isUserInteractionEnabled = false
        } else {
            addButton.isSelected = false
            addButton.isUserInteractionEnabled = true
        }
    }
    
    @IBAction func addButtonPressed(_ sender: Any) {
        FirebaseAPI.queueSong(spotifySong: self.song)
        HUD.flash(.labeledSuccess(title: nil, subtitle: "Added \(self.song.songName) to your stream"), delay: 1.0)
        SongKeeper.addedSongs.insert(self.song.spotifyID)
        addButton.isSelected = true
        addButton.isUserInteractionEnabled = false
    }
}
