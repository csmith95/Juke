//
//  UserCell.swift
//  Juke
//
//  Created by Conner Smith on 8/26/17.
//  Copyright © 2017 csmith. All rights reserved.
//

import UIKit
import AlamofireImage
import PKHUD
import Firebase

class UserCell: UITableViewCell {

    @IBOutlet var inviteToStreamButton: UIButton!
    @IBOutlet var userNameLabel: UILabel!
    @IBOutlet var userImageView: UIImageView!
    @IBOutlet var presenceDot: UIImageView!
    @IBOutlet weak var starButton: UIButton!
    @IBOutlet var starIcon: UIImageView!
    @IBOutlet var hostLabel: UILabel!
    
    private let defaultIcon = CircleFilter().filter(UIImage(named: "juke_icon")!)
    private var member: Models.FirebaseUser!

    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    @IBAction func starButtonPressed(_ sender: Any) {
        var message = ""
        if self.starIcon.isHidden {
            FirebaseAPI.addToStarredTable(user: self.member)
            self.starIcon.isHidden = false
            self.starButton.isSelected = true
            message = "Starred \(self.member.username)"
        } else {
            FirebaseAPI.removeFromStarredTable(user: self.member)
            self.starIcon.isHidden = true
            self.starButton.isSelected = false
            message = "Removed \(self.member.username)"
        }
        HUD.flash(.labeledSuccess(title: nil, subtitle: message), delay: 1.0)
    }
    
    
    public func populateCell(member: Models.FirebaseUser) {
        
        if hostLabel != nil {
            if Current.stream!.host.spotifyID == member.spotifyID {
                hostLabel.isHidden = false
            } else {
                hostLabel.isHidden = true
            }
        }
        
        if Current.user!.spotifyID == member.spotifyID {
            // necessary because this cell is used in the stream members table view controller
            starButton.isHidden = true
            starIcon.isHidden = true
        } else {
            starButton.isHidden = false
        }
        
        if Current.isStarred(user: member) {
            starButton.isSelected = true
            starIcon.isHidden = false
        } else {
            starButton.isSelected = false
            starIcon.isHidden = true
        }
        
        // set elements
        self.member = member
        self.userNameLabel.text = member.username
        loadUserIcon(url: member.imageURL)
        if member.online {
            presenceDot.image = #imageLiteral(resourceName: "green dot")
            presenceDot.isHidden = false
        } else {
            presenceDot.isHidden = true
        }
        
    }
    
    private func loadUserIcon(url: String?) {
        if let unwrappedUrl = url {
            userImageView.af_setImage(withURL: URL(string: unwrappedUrl)!, placeholderImage: defaultIcon)
        } else {
            userImageView.image = defaultIcon
        }
    }
}
