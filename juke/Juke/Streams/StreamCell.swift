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

    @IBOutlet var blurredBgImage: UIImageView!
    @IBOutlet var musicIndicatorView: UIView!
    @IBOutlet var moreMembersLabel: UILabel!
    @IBOutlet var member4ImageView: UIImageView!
    @IBOutlet var member3ImageView: UIImageView!
    @IBOutlet var member2ImageView: UIImageView!
    @IBOutlet var member1ImageView: UIImageView!
    @IBOutlet var ownerIcon: UIImageView!
    @IBOutlet var coverArt: UIImageView!
    @IBOutlet var artist: UILabel!
    @IBOutlet var song: UILabel!
    @IBOutlet var username: UILabel!
    private var imageViewDict:[Int:UIImageView] = [:]
    private var indicator:ESTMusicIndicatorView!
    private let defaultIcon = CircleFilter().filter(UIImage(named: "juke_icon")!)
    private var coverArtFilter: ImageFilter!
    private var defaultCoverArtImage: UIImage!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        coverArtFilter = AspectScaledToFillSizeWithRoundedCornersFilter(
            size: coverArt.frame.size,
            radius: 20.0
        )
        defaultCoverArtImage = coverArtFilter.filter(#imageLiteral(resourceName: "jukedef"))
        imageViewDict[0] = member1ImageView
        imageViewDict[1] = member2ImageView
        imageViewDict[2] = member3ImageView
        imageViewDict[3] = member4ImageView
        indicator = ESTMusicIndicatorView.init(frame: musicIndicatorView.bounds)
        indicator.tintColor = .red
        indicator.sizeToFit()
        musicIndicatorView.addSubview(indicator)
    }
    
    public func populateCell(stream: Models.FirebaseStream) {
        loadCellImages(stream: stream)
        let titleString = stream.host.username.components(separatedBy: " ").first! + "'s stream"
        self.username.text = titleString
        if let song = stream.song {
            self.artist.text = song.artistName
            self.song.text = song.songName
            self.blurredBgImage.af_setImage(withURL: URL(string: song.coverArtURL)!)
        } else {
            self.artist.text = ""
            self.song.text = ""
            self.blurredBgImage.image = #imageLiteral(resourceName: "jukedef")
        }
        indicator.state = (stream.isPlaying) ? .playing : .stopped
    }
    
    // set user icons
    private func loadUserIcon(url: String?, imageView: UIImageView) {
        if let unwrappedUrl = url {
            imageView.af_setImage(withURL: URL(string: unwrappedUrl)!, placeholderImage: defaultIcon)
        } else {
            imageView.image = defaultIcon
        }
    }
    
    private func loadCoverArt(stream: Models.FirebaseStream) {
        if let song = stream.song {
            self.coverArt.af_setImage(withURL: URL(string: song.coverArtURL)!, placeholderImage: defaultCoverArtImage, filter: coverArtFilter)
        } else {
            self.coverArt.image = defaultCoverArtImage
        }
    }
    
    private func loadCellImages(stream: Models.FirebaseStream) {
        clearMemberIcons()  // start fresh
        loadCoverArt(stream: stream)
        // load owner icon
        loadUserIcon(url: stream.host.imageURL, imageView: self.ownerIcon)
        let numMemberIcons = stream.members.count
        if numMemberIcons > 0 {
            let numMemberIconsToDisplay = min(numMemberIcons, self.imageViewDict.count)
            for i in 0..<numMemberIconsToDisplay {
                loadUserIcon(url: stream.members[i].imageURL, imageView: self.imageViewDict[i]!)
            }
        } else {
            self.clearMemberIcons()
        }
        // if there are more members than we're displaying, show a label
        let remainder = stream.members.count - 5;
        if remainder > 0 {
            self.moreMembersLabel.text = "+ \(remainder) more member" + ((remainder > 1) ? "s" : "")
            self.moreMembersLabel.isHidden = false
        } else {
            self.moreMembersLabel.isHidden = true
        }
    }
    
    public func clearMemberIcons() {
        for (_, imageView) in imageViewDict {
            imageView.image = nil
        }
        moreMembersLabel.text = ""
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        // Configure the view for the selected state
    }

}
