//
//  StreamCell.swift
//  Juke
//
//  Created by Conner Smith on 3/28/17.
//  Copyright © 2017 csmith. All rights reserved.
//

import UIKit
import ESTMusicIndicator

class StreamCell: UITableViewCell {

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
    //@IBOutlet var backgroundCardView: UIView!
    private var imageViewDict:[Int:UIImageView] = [:]
    var indicator:ESTMusicIndicatorView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        imageViewDict[0] = ownerIcon
        imageViewDict[1] = member1ImageView
        imageViewDict[2] = member2ImageView
        imageViewDict[3] = member3ImageView
        imageViewDict[4] = member4ImageView
        indicator = ESTMusicIndicatorView.init(frame: musicIndicatorView.bounds)
        indicator.tintColor = .red
        indicator.sizeToFit()
        musicIndicatorView.addSubview(indicator)
    }
    
    public func getImageViewForMember(index: Int) -> UIImageView {
        return imageViewDict[index]!
    }
    
    public func setMusicIndicator(play: Bool) {
        indicator.state = (play) ? ESTMusicIndicatorViewState.playing : ESTMusicIndicatorViewState.paused
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        // Configure the view for the selected state
    }

}
