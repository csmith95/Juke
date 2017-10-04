//
//  StarredUserCell.swift
//  Juke
//
//  Created by Conner Smith on 9/18/17.
//  Copyright © 2017 csmith. All rights reserved.
//

import UIKit
import AlamofireImage
import PKHUD

class StarredUserCell: UITableViewCell {

    @IBOutlet var inviteToStreamButton: UIButton!
    @IBOutlet var usernameLabel: UILabel!
    @IBOutlet var userImageView: UIImageView!
    
    private var member: Models.FirebaseUser!

    @IBAction func inviteToStreamPressed(_ sender: Any) {
        //inviteToStreamButton.isSelected = true
        FirebaseAPI.sendNotification(receiver: self.member)
        HUD.flash(.labeledSuccess(title: nil, subtitle: "Invited \(self.member.username) to your stream"), delay: 1.00)
        //self.inviteToStreamButton.isUserInteractionEnabled = false
    }
    
    @IBAction func starButtonPressed(_ sender: Any) {
        FirebaseAPI.removeFromStarredTable(user: self.member)
        HUD.flash(.labeledSuccess(title: nil, subtitle: "Removed \(self.member.username)"), delay: 1.0)
        Current.removeStarredUser(user: self.member)
    }
    
    public func populateCell(member: Models.FirebaseUser) {
        
        // reset elements
        if (inviteToStreamButton != nil) {
            self.inviteToStreamButton.isSelected = false
            self.inviteToStreamButton.isHidden = false
            self.inviteToStreamButton.isUserInteractionEnabled = true
        }
        
        // set elements
        self.member = member
        self.usernameLabel.text = member.username
        loadUserIcon(url: member.imageURL)
        
    }
    
    private func loadUserIcon(url: String?) {
        ImageCache.downloadUserImage(url: url, callback: { (image) in
            self.userImageView.image = image
        })
    }
    

}
