//
//  SearchCell.swift
//  Juke
//
//  Created by Kojo Worai Osei on 4/14/17.
//  Copyright © 2017 csmith. All rights reserved.
//

import UIKit

class SearchCell: UITableViewCell {
    @IBOutlet weak var addToStreamButton: UIButton!
    var tapAction: ((SearchCell) -> Void)?

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        addToStreamButton!.setTitle("+", for: .normal)
        addToStreamButton!.setTitle("Added!", for: .selected)
    }

    @IBAction func queueSongButtonTapped(_ sender: Any) {
        tapAction?(self)
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
