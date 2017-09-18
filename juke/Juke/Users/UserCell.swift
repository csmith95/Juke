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
    
    @IBAction func starButtonPressed(_ sender: Any) {
        print("star button pressed")
        // TODO: implement star button pressed
        FirebaseAPI.addToStarredTable(user: self.member)
        starButton.isEnabled = false
    }
    
    public func isStarred(user: Models.FirebaseUser) {
        
    }
    
    public func populateCell(member: Models.FirebaseUser) {
        
        // is this efficient? i really don't want to have a store for this
        guard let currUser = Current.user else { return }
        Database.database().reference().child("starredTable/\(currUser.spotifyID)").observeSingleEvent(of: .value, with: { (snapshot) in
            //print("SNAP", snapshot)
            let starredUsersDict = (snapshot.value as? NSDictionary)!
            let keyExists = starredUsersDict[member.spotifyID] != nil
            print(starredUsersDict)
            if self.starButton != nil {
                if keyExists {
                    self.starButton.isEnabled = false
                } else {
                    self.starButton.isEnabled = true
                }
            }
            //return (starredUsersDict![user.spotifyID] != nil)
        }) { error in print(error.localizedDescription) }
        
        // reset elements
        if (inviteToStreamButton != nil) {
            self.inviteToStreamButton.isSelected = false
            self.inviteToStreamButton.isHidden = false
            self.inviteToStreamButton.isUserInteractionEnabled = true
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
