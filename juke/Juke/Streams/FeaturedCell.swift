//
//  FeaturedCell.swift
//  Juke
//
//  Created by Kojo Worai Osei on 3/21/18.
//  Copyright © 2018 csmith. All rights reserved.
//

import Foundation
import AlamofireImage

class FeaturedCell: UICollectionViewCell {
    
    @IBOutlet weak var albumPlayingImage: UIImageView!
    @IBOutlet weak var streamName: UILabel!
    @IBOutlet weak var hostLabel: UILabel!
    @IBOutlet weak var streamMembersCountLabel: UILabel!
    
    public func populateCell(stream: Models.FirebaseStream) {
        if let song = stream.song {
            self.albumPlayingImage.af_setImage(withURL: URL(string: song.coverArtURL)!)
        } else {
            self.albumPlayingImage.image = #imageLiteral(resourceName: "jukedef")
        }
        let count = stream.members.count+1  // +1 for host
        streamMembersCountLabel.text = "\(count) other" + ((count > 1) ? "s" : "") + " streaming"
        if (stream.host == Current.user) {
            self.hostLabel.text = "Hosted by you"
        } else {
            self.hostLabel.text = "Hosted by \(stream.host.username)"
        }
        self.streamName.text = stream.title
    }
}
