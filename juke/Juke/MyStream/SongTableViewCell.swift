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

    @IBOutlet var userStarIcon: UIImageView!
    @IBOutlet var upvoteButton: UIButton!
    @IBOutlet var songName: UILabel!
    @IBOutlet var artist: UILabel!
    @IBOutlet weak var memberImgView: UIImageView!
    @IBOutlet weak var starImgView: UIImageView!
    
    let normalUpvote = UIImage(named: "upvote-carat-white")
    let selectedUpvote = UIImage(named: "upvote-carat-green")
    let featuredNormalUpvote = UIImage(named: "empty_heart")
    let featuredSelectedUpvote = UIImage(named: "filled_heart")
    
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
        
        FirebaseAPI.checkVerified(spotifyID: song.memberSpotifyID, callback: { (result) in
            if result {
                self.userStarIcon.image = UIImage(named: "verified")
                self.userStarIcon.isHidden = false
            } else {
                self.userStarIcon.image = UIImage(named: "star")
                self.userStarIcon.isHidden = !Current.isStarred(spotifyID: song.memberSpotifyID)
            }
        })
        
        upvoteButton.setImage(normalUpvote, for: .normal)
        upvoteButton.setImage(selectedUpvote, for: .selected)
        if let stream = Current.stream {
            if stream.isFeatured ?? false {
                upvoteButton.setImage(featuredNormalUpvote, for: .normal)
                upvoteButton.setImage(featuredSelectedUpvote, for: .selected)
            }
        }
    }
    
    private func loadUserIcon(url: String?, imageView: UIImageView) {
        imageView.isHidden = false
        ImageCache.downloadUserImage(url: url, callback: { (image) in
            imageView.isHidden = false
            imageView.image = image
        })
    }

}
