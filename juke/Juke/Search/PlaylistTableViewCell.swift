//
//  PlaylistTableViewCell.swift
//  Juke
//
//  Created by Conner Smith on 9/26/17.
//  Copyright © 2017 csmith. All rights reserved.
//

import UIKit

class PlaylistTableViewCell: UITableViewCell {

    @IBOutlet var playlistOwnerLabel: UILabel!
    @IBOutlet var playlistNameLabel: UILabel!
    @IBOutlet var playlistImageView: UIImageView!
    
    var playlist: Models.SpotifyPlaylist!
    
    public func populateCell(playlist: Models.SpotifyPlaylist) {
        self.playlist = playlist

        if let ownerUsername = playlist.ownerUsername {
            if ownerUsername == Current.user?.username {
                playlistOwnerLabel.text = ""
            } else {
                playlistOwnerLabel.text = ownerUsername
            }
        } else {
            playlistOwnerLabel.text = ""
        }
        
        playlistNameLabel.text = playlist.name
        ImageCache.downloadPlaylistImage(url: playlist.imageURL) { (image) in
            self.playlistImageView.image = image
        }
    }
    
    

}
