//
//  StreamCell.swift
//  Juke
//
//  Created by Conner Smith on 3/28/17.
//  Copyright © 2017 csmith. All rights reserved.
//

import UIKit
import ESTMusicIndicator
import AlamofireImage

class StreamCell: UITableViewCell {

    @IBOutlet weak var currentlyLstnTag: UILabel!
    @IBOutlet var hostStarIcon: UIImageView!
    @IBOutlet var blurredBgImage: UIImageView!
    @IBOutlet var musicIndicatorView: UIView!
    @IBOutlet weak var streamName: UILabel!
    @IBOutlet weak var hostLabel: UILabel!
    @IBOutlet weak var numMembers: UILabel!
    @IBOutlet weak var member1ImageView: UIImageView!
    @IBOutlet weak var member2ImageView: UIImageView!
    @IBOutlet weak var member3ImageView: UIImageView!
    @IBOutlet weak var member4ImageView: UIImageView!
    private var imageViewDict:[Int:UIImageView] = [:]
    private var indicator:ESTMusicIndicatorView!
    private var coverArtFilter: ImageFilter!
    private var defaultCoverArtImage: UIImage!
    @IBOutlet weak var featuredHost: UIImageView!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        imageViewDict[0] = member1ImageView
        imageViewDict[1] = member2ImageView
        imageViewDict[2] = member3ImageView
        imageViewDict[3] = member4ImageView
        indicator = ESTMusicIndicatorView.init(frame: musicIndicatorView.bounds)
        indicator.tintColor = .green
        indicator.sizeToFit()
        musicIndicatorView.addSubview(indicator)
    }
    
    public func populateCell(stream: Models.FirebaseStream) {
        
        let isftrd = stream.isFeatured ?? false
        self.featuredhost.isHidden = true
        if (isftrd) {
            loadFtrdCellImages(stream: stream)
            self.streamName.text = "JukeLIVE: \(stream.title)"
            self.hostStarIcon.image = #imageLiteral(resourceName: "verified")
        } else {
            loadCellImages(stream: stream)
            self.streamName.text = stream.title
            self.hostStarIcon.image = #imageLiteral(resourceName: "Star")
            self.hostStarIcon.isHidden = !Current.isStarred(user: stream.host)
        }
        self.hostLabel.text = "Hosted by \(stream.host.username)"
        
        if let song = stream.song {
            self.blurredBgImage.af_setImage(withURL: URL(string: song.coverArtURL)!)
        } else {
            self.blurredBgImage.image = #imageLiteral(resourceName: "jukedef")
        }
        indicator.state = (stream.isPlaying) ? .playing : .stopped
        let count = stream.members.count+1  // +1 for host
        numMembers.text = "\(count) member" + ((count > 1) ? "s" : "")
        if let currentStream = Current.stream {
            if (stream.streamID == currentStream.streamID) {
                currentlyLstnTag.isHidden = false
                self.isUserInteractionEnabled = false
                self.alpha = 0.5
            }
        }
    }
    
    // set user icons
    private func loadUserIcon(url: String?, imageView: UIImageView) {
        imageView.isHidden = false
        ImageCache.downloadUserImage(url: url, callback: { (image) in
            imageView.isHidden = false
            imageView.image = image
        })
    }
    
    private func loadCellImages(stream: Models.FirebaseStream) {
        clearMemberIcons()  // start fresh
        let starImg = #imageLiteral(resourceName: "Star")
        let starImageView = UIImageView(image: starImg)
        
        let numMemberIcons = stream.members.count
        if numMemberIcons > 0 {
            let numMemberIconsToDisplay = min(numMemberIcons, self.imageViewDict.count)
            for i in 0..<numMemberIconsToDisplay {
                if Current.isStarred(user: stream.members[i]) {
                    loadUserIcon(url: stream.members[i].imageURL, imageView: self.imageViewDict[i]!)
                    starImageView.frame = CGRect(x: 17, y: 17, width: 20, height: 20)
                    self.imageViewDict[i]?.addSubview(starImageView)
                }
            }
        } else {
            self.clearMemberIcons()
        }
    }
    
    private func loadFtrdCellImages(stream: Models.FirebaseStream) {
        // load featured artist image
        loadUserIcon(url: stream.host.imageURL, imageView: self.featuredHost)
        self.featuredHost.isHidden = false
        self.hostStarIcon.image = #imageLiteral(resourceName: "checkmark_white")
    }
    
    public func clearMemberIcons() {
        for (_, imageView) in imageViewDict {
            imageView.image = nil
            imageView.isHidden = true
            currentlyLstnTag.isHidden = true
            self.isUserInteractionEnabled = true
            
        }
    }

}
