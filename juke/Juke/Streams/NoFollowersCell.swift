//
//  NoFollowersCell.swift
//  Juke
//
//  Created by Kojo Worai Osei on 4/8/18.
//  Copyright © 2018 csmith. All rights reserved.
//

import UIKit

class NoFollowersCell: UITableViewCell {
    
    var parentVC: UIViewController? = nil
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        let cellTapped = UITapGestureRecognizer(target: self, action: #selector(self.showUsers))
        self.addGestureRecognizer(cellTapped)
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func showUsers() {
        print("cell tapped, waiting for show users")
        let allUsersVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "AllUsers") as! UsersTableViewController
        parentVC?.present(allUsersVC, animated: true, completion: nil)
    }
    
}
