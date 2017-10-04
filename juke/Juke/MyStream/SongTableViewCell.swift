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
    @IBOutlet var songName: UILabel!
    @IBOutlet var artist: UILabel!
    @IBOutlet weak var memberImgView: UIImageView!
    @IBOutlet weak var starImgView: UIImageView!
    
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
        self.song = song
        songName.text = song.songName
        artist.text = song.artistName
        upvoteButton.isSelected = song.upvoters.keys.contains(where: { (userSpotifyID) -> Bool in
            guard let user = Current.user else { return false }
            return userSpotifyID == user.spotifyID
        })
        upvoteButton.setTitle("\(song.upvoters.count)", for: .normal)
        loadUserIcon(url: song.memberImageURL, imageView: memberImgView)
        
    }
    
    private func loadUserIcon(url: String?, imageView: UIImageView) {
        imageView.isHidden = false
        ImageCache.downloadUserImage(url: url, callback: { (image) in
            imageView.isHidden = false
            imageView.image = image
        })
    }

}
