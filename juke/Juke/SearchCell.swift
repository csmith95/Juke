//
//  SearchCell.swift
//  Juke
//
//  Created by Conner Smith on 3/7/17.
//  Copyright © 2017 csmith. All rights reserved.
//

import UIKit

class SearchCell: UITableViewCell {

    @IBOutlet var songLabel: UILabel!
    @IBOutlet var artistLabel: UILabel!
    @IBOutlet var addButton: UIButton!
    var tapAction: ((SearchCell) -> Void)?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    @IBAction func queueSongButtonTapped(_ sender: AnyObject) {
        tapAction?(self)
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
