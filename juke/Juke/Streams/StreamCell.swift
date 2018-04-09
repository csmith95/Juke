//
//  StreamCell.swift
//  Juke
//
//  Created by Conner Smith on 3/28/17.
//  Copyright © 2017 csmith. All rights reserved.
//

import UIKit
import AlamofireImage

class StreamCell: UITableViewCell {

    @IBOutlet weak var albumArt: UIImageView!
    @IBOutlet weak var streamName: UILabel!
    @IBOutlet weak var hostLabel: UILabel!
    @IBOutlet weak var numMembers: UILabel!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    public func populateCell(stream: Models.FirebaseStream) {
        
        let isftrd = stream.isFeatured ?? false
        if (isftrd) {
            self.streamName.text = "JukeLIVE: \(stream.title)"
        } else {
            self.streamName.text = stream.title
        }
        if (stream.host == Current.user) {
            self.hostLabel.text = "Hosted by you\u{25CF}"
        } else {
            self.hostLabel.text = "Hosted by \(stream.host.username)\u{25CF}"
        }
        
        
        if let song = stream.song {
            self.albumArt.af_setImage(withURL: URL(string: song.coverArtURL)!)
        } else {
            self.albumArt.image = #imageLiteral(resourceName: "jukedef")
        }
        
        if stream.isPlaying {
            self.albumArt.layer.borderWidth = 6
            self.albumArt.layer.masksToBounds = true
            self.albumArt.layer.cornerRadius = 4
            self.albumArt.layer.borderColor = UIColor(red: 108.0/255.0, green: 74.0/255.0, blue: 188.0/255.0, alpha: 1.0).cgColor
            
        } else {
            self.albumArt.layer.borderWidth = 0
            self.albumArt.layer.cornerRadius = 0
        }
        
        let count = stream.members.count+1  // +1 for host
        numMembers.text = "\(count) other" + ((count > 1) ? "s" : "") + " streaming"
        if let currentStream = Current.stream {
            if (stream.streamID == currentStream.streamID) {
                //currentlyLstnTag.isHidden = false
                self.isUserInteractionEnabled = false
                self.alpha = 0.5
            }
        }
    }
}
