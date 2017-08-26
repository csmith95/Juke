//
//  FriendCell.swift
//  Juke
//
//  Created by Conner Smith on 8/26/17.
//  Copyright © 2017 csmith. All rights reserved.
//

import UIKit
import AlamofireImage

class FriendCell: UITableViewCell {

    @IBOutlet var joinStreamButton: UIButton!
    @IBOutlet var memberNameLabel: UILabel!
    @IBOutlet var friendImageView: UIImageView!
    @IBOutlet var presenceDot: UIImageView!
    @IBOutlet var streamNameLabel: UILabel!
    private let defaultIcon = CircleFilter().filter(UIImage(named: "juke_icon")!)
    private var member: Models.FirebaseUser!
    private var stream: Models.FirebaseStream?

    override func awakeFromNib() {
        super.awakeFromNib()
        
    }
    
    @IBAction func inviteToStreamPressed(_ sender: Any) {
        // need to send invite to this user when pressed
        print("invite to stream")
        let button = sender as! UIButton
        button.isSelected = !button.isSelected
        
    }
    
    
    @IBAction func joinStreamPressed(_ sender: Any) {
        // join this stream
        print("join stream")
        let button = sender as! UIButton
        button.isSelected = !button.isSelected
    }
    
    public func populateCell(member: Models.FirebaseUser) {
        self.member = member
        self.memberNameLabel.text = member.username
        loadUserIcon(url: member.imageURL)
        if member.online {
            presenceDot.image = #imageLiteral(resourceName: "green dot")
        } else {
            presenceDot.image = #imageLiteral(resourceName: "red dot")
        }
        
        guard let streamID = member.tunedInto else {
            streamNameLabel.text = "No stream"
            joinStreamButton.isHidden = true
            return
        }
        
        fetchStream(streamID: streamID)
    }
    
    private func loadUserIcon(url: String?) {
        if let unwrappedUrl = url {
            friendImageView.af_setImage(withURL: URL(string: unwrappedUrl)!, placeholderImage: defaultIcon)
        } else {
            friendImageView.image = defaultIcon
        }
    }
    
    private func fetchStream(streamID: String) {
        FirebaseAPI.fetchStream(streamID: streamID) { (optionalStream)  in
            guard let stream = optionalStream else {
                self.streamNameLabel.text = "No stream"
                self.joinStreamButton.isHidden = true
                return
            }
            
            self.stream = stream
            var streamName = "Your stream"
            
            DispatchQueue.main.async {
                self.joinStreamButton.isHidden = false   // to reset in case this element was previously set to hidden
                if (Current.user.spotifyID == stream.host.spotifyID) {
                    streamName = "Your stream"
                    self.joinStreamButton.isHidden = true
                } else if (self.member.spotifyID == stream.host
                    .spotifyID) {
                    streamName = "Hosting a stream"
                } else if (Current.stream.streamID == stream.streamID) {
                    self.streamNameLabel.text = "Streaming with you"
                    self.joinStreamButton.isHidden = true
                } else {
                    streamName = stream.host.username + "'s Stream"
                }
                self.streamNameLabel.text = streamName
            }
        }
        
    }
    
}
