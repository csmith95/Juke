//
//  queueTableViewCell.swift
//  Juke
//
//  Created by Thomas Jensen on 2/18/17.
//  Copyright © 2017 csmith. All rights reserved.
//

import UIKit

class queueTableViewCell: UITableViewCell {

    
    @IBOutlet weak var itemLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
