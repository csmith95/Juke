//
//  SearchCell.swift
//  Juke
//
//  Created by Kojo Worai Osei on 4/14/17.
//  Copyright © 2017 csmith. All rights reserved.
//

import UIKit

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
        addButton.isSelected = false
        addButton.isUserInteractionEnabled = true
    }
    
    @IBAction func addButtonPressed(_ sender: Any) {
        handleAddButtonPressed()
        addButton.isSelected = true
        addButton.isUserInteractionEnabled = false
    }
    
    func handleAddButtonPressed() {
        fatalError("This method must be overridden by subclass")
    }
}
