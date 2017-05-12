//
//  SongTableViewCell.swift
//  Juke
//
//  Created by Conner Smith on 3/10/17.
//  Copyright © 2017 csmith. All rights reserved.
//

import UIKit

class SongTableViewCell: UITableViewCell {

    
    @IBOutlet var memberImageView: UIImageView!
    @IBOutlet var songName: UILabel!
    @IBOutlet var artist: UILabel!
    @IBOutlet weak var playingSongIndicator: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
