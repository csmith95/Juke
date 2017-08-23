//
//  StreamMemberTableViewCell.swift
//  Juke
//
//  Created by Kojo Worai Osei on 8/23/17.
//  Copyright © 2017 csmith. All rights reserved.
//

import UIKit
import AlamofireImage

class StreamMemberTableViewCell: UITableViewCell {

    @IBOutlet weak var memberImage: UIImageView!
    @IBOutlet weak var memberName: UILabel!
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
        
    }
    
    private func loadUserIcon(url: String?, imageView: UIImageView) {
        if let unwrappedUrl = url {
            imageView.af_setImage(withURL: URL(string: unwrappedUrl)!, placeholderImage: defaultIcon)
        } else {
            imageView.image = defaultIcon
        }
    }

}
