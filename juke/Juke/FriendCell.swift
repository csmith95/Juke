//
//  FriendCell.swift
//  Juke
//
//  Created by Conner Smith on 8/26/17.
//  Copyright © 2017 csmith. All rights reserved.
//

import UIKit
import AlamofireImage
import PKHUD

class FriendCell: UITableViewCell {

    //@IBOutlet var inviteToStreamButton: UIButton!
    //@IBOutlet var joinStreamButton: UIButton!
    @IBOutlet var userNameLabel: UILabel!
    @IBOutlet var userImageView: UIImageView!
    @IBOutlet var presenceDot: UIImageView! 
    //@IBOutlet var streamNameLabel: UILabel!
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
        
        guard let stream = self.stream else {
            HUD.show(.progress)
            HUD.flash(.error, delay: 1.0)
            return
        }
        
        // join this stream
        let button = sender as! UIButton
        button.isSelected = !button.isSelected
        
        HUD.show(.progress)
        FirebaseAPI.joinStream(stream: stream) { success in
            if success {
                NotificationCenter.default.post(name: Notification.Name("newStreamJoined"), object: nil)
                HUD.flash(.success, delay: 1.0)
            } else {
                HUD.flash(.error, delay: 1.0)
            }
        }
    }
    
    public func populateCell(member: Models.FirebaseUser) {
        // to reset elements
//        self.joinStreamButton.isSelected = false
//        self.joinStreamButton.isHidden = false
//        self.inviteToStreamButton.isSelected = false
//        self.inviteToStreamButton.isHidden = false
        
        // set elements
        self.member = member
        self.userNameLabel.text = member.username
        loadUserIcon(url: member.imageURL)
        if member.online {
            presenceDot.image = #imageLiteral(resourceName: "green dot")
        } else {
            presenceDot.image = #imageLiteral(resourceName: "red dot")
        }
        
//        guard let streamID = member.tunedInto else {
//            streamNameLabel.text = "No stream"
//            joinStreamButton.isHidden = true
//            return
//        }
        
        //fetchStream(streamID: streamID)
    }
    
    private func loadUserIcon(url: String?) {
        if let unwrappedUrl = url {
            userImageView.af_setImage(withURL: URL(string: unwrappedUrl)!, placeholderImage: defaultIcon)
        } else {
            userImageView.image = defaultIcon
        }
    }
    
//    private func fetchStream(streamID: String) {
//        FirebaseAPI.fetchStream(streamID: streamID) { (optionalStream)  in
//            guard let stream = optionalStream else {
//                self.streamNameLabel.text = "No stream"
//                self.joinStreamButton.isHidden = true
//                return
//            }
//            
//            self.stream = stream
//            
//            // determine whether join stream/ invite to stream should show
//            if (Current.stream.streamID == stream.streamID) {
//                self.joinStreamButton.isHidden = true
//                self.inviteToStreamButton.isHidden = true
//            }
//            
//            // set stream title
//            if (Current.stream.streamID == stream.streamID) {
//                self.streamNameLabel.text = "Streaming with you"
//            } else if (self.member.spotifyID == stream.host
//                .spotifyID){
//                self.streamNameLabel.text = "Hosting a stream"
//            } else {
//                self.streamNameLabel.text = stream.host.username + "'s Stream"
//            }
//        }
//        
//    }
    
}
