//
//  CardTableViewCell.swift
//  CardTilt
//
//  Created by Ray Fix on 6/25/14.
//  Edited by Ray Fix on 4/12/15.
//  Copyright (c) 2014-2015 Razeware LLC. All rights reserved.
//

import UIKit
import QuartzCore

class CardTableViewCell: UITableViewCell {
    
    @IBOutlet var testLabel: UILabel!
    @IBOutlet var mainView: UIView!
    
    func useMember() {
        // Round those corners
        mainView.layer.cornerRadius = 10;
        mainView.layer.masksToBounds = true;
        
    }
}
