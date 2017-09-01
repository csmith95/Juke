//
//  SongTableViewCell.swift
//  Juke
//
//  Created by Conner Smith on 3/10/17.
//  Copyright © 2017 csmith. All rights reserved.
//

import UIKit
import AlamofireImage

class SongTableViewCell: UITableViewCell {

    @IBOutlet var upvoteButton: UIButton!
    @IBOutlet var numVotesLabel: UILabel!
    @IBOutlet var memberImageView: UIImageView!
    @IBOutlet var songName: UILabel!
    @IBOutlet var artist: UILabel!
    let defaultImage = CircleFilter().filter(UIImage(named: "juke_icon")!)
    let imageFilter = CircleFilter()
    var song: Models.FirebaseSong!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    @IBAction func upvotePressed(_ sender: Any) {
        upvoteButton.isSelected = !upvoteButton.isSelected
        FirebaseAPI.updateVotes(song: self.song, upvoted: upvoteButton.isSelected)
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        // Configure the view for the selected state
    }
    
    public func populateCell(song: Models.FirebaseSong) {
        print("\n song: ", song)
        self.song = song
        songName.text = song.songName
        artist.text = song.artistName
        upvoteButton.isSelected = song.upvoters.keys.contains(where: { (userSpotifyID) -> Bool in
            return userSpotifyID == Current.user.spotifyID
        })
        numVotesLabel.text = String(song.votes)
        if let unwrappedUrl = song.memberImageURL {
            memberImageView.af_setImage(withURL: URL(string: unwrappedUrl)!, placeholderImage: defaultImage, filter: imageFilter)
        } else {
            memberImageView.image = imageFilter.filter(defaultImage)
        }
    }

}
