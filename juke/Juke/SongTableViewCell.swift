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

    
    @IBOutlet var memberImageView: UIImageView!
    @IBOutlet var songName: UILabel!
    @IBOutlet var artist: UILabel!
    let defaultImage = CircleFilter().filter(UIImage(named: "juke_icon")!)
    let imageFilter = CircleFilter()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    public func populateCell(song: Models.FirebaseSong) {
        songName.text = song.songName
        artist.text = song.artistName
        if let unwrappedUrl = song.memberImageURL {
            memberImageView.af_setImage(withURL: URL(string: unwrappedUrl)!, placeholderImage: defaultImage, filter: imageFilter)
        } else {
            memberImageView.image = imageFilter.filter(defaultImage)
        }
    }

}
