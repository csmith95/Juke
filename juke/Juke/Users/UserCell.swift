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

class UserCell: UITableViewCell {

    @IBOutlet var inviteToStreamButton: UIButton!
    @IBOutlet var userNameLabel: UILabel!
    @IBOutlet var userImageView: UIImageView!
    @IBOutlet var presenceDot: UIImageView!
    private let defaultIcon = CircleFilter().filter(UIImage(named: "juke_icon")!)
    private var member: Models.FirebaseUser!

    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    @IBAction func inviteToStreamPressed(_ sender: Any) {
        // need to send invite to this user when pressed
        let button = sender as! UIButton
        button.isSelected = !button.isSelected
        FirebaseAPI.sendNotification(receiver: self.member)
        HUD.flash(.labeledSuccess(title: nil, subtitle: "Invited \(self.member.username) to your stream"), delay: 1.00)
        self.inviteToStreamButton.isUserInteractionEnabled = false
    }
    
    public func populateCell(member: Models.FirebaseUser) {
        
        // reset elements
        self.inviteToStreamButton.isSelected = false
        self.inviteToStreamButton.isHidden = false
        self.inviteToStreamButton.isUserInteractionEnabled = true
        
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
