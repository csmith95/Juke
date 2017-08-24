//
//  StreamMemberTableViewCell.swift
//  Juke
//
//  Created by Kojo Worai Osei on 8/23/17.
//  Copyright © 2017 csmith. All rights reserved.
//

import UIKit
import AlamofireImage

class StreamMemberCell: UITableViewCell {

    @IBOutlet weak var memberImage: UIImageView!
    @IBOutlet weak var memberName: UILabel!
    @IBOutlet weak var presenceDot: UIImageView!
    
    
    private let defaultIcon = CircleFilter().filter(UIImage(named: "juke_icon")!)
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    public func populateMemberCell(member: Models.FirebaseUser) {
        self.memberName.text = member.username
        loadUserIcon(url: member.imageURL, imageView: memberImage)
        if member.online {
            print("member is online, setting presence to green dot", member)
            // set presence dot to be green
            presenceDot.image = #imageLiteral(resourceName: "green dot")
        } else {
            // set presence dot to be red
            print("member is offline, setting presence to red dot", member)
            presenceDot.image = #imageLiteral(resourceName: "red dot")
        }
        
    }
    
    private func loadUserIcon(url: String?, imageView: UIImageView) {
        if let unwrappedUrl = url {
            imageView.af_setImage(withURL: URL(string: unwrappedUrl)!, placeholderImage: defaultIcon)
        } else {
            imageView.image = defaultIcon
        }
    }

}
