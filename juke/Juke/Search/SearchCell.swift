//
//  SearchCell.swift
//  Juke
//
//  Created by Kojo Worai Osei on 4/14/17.
//  Copyright © 2017 csmith. All rights reserved.
//

import UIKit
import PKHUD
import Presentr

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
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: false)
        if selected {
            handlePressed()
        }
        super.setSelected(false, animated: false)
    }
    
    @IBAction func addButtonPressed(_ sender: Any) {
        handlePressed()
    }
    
    private func handlePressed() {
        if (Current.stream?.isFeatured)! && !Current.isHost() {
            print("isfeatured", Current.stream?.isFeatured as Any)
            HUD.flash(.labeledError(title: nil, subtitle: "Adding songs is disabled for JukeLIVE sessions"), delay: 2.0)
            return
        }
        if SongKeeper.addedSongs.contains(self.song.spotifyID) { return }
        FirebaseAPI.queueSong(spotifySong: self.song)
        HUD.flash(.labeledSuccess(title: nil, subtitle: "Added \(self.song.songName) to your stream"), delay: 1.0)
        SongKeeper.addedSongs.insert(self.song.spotifyID)
        addButton.isSelected = true
        addButton.isUserInteractionEnabled = false
    }
}
