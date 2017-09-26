//
//  EmptyStreamViewController.swift
//  Juke
//
//  Created by Conner Smith on 9/16/17.
//  Copyright © 2017 csmith. All rights reserved.
//

import UIKit

class EmptyStreamViewController: UIViewController {

    @IBOutlet weak var streamTitleLabel: UILabel!
    @IBOutlet weak var numMembersButton: UIButton!
    @IBOutlet weak var twoDownArrows: UIImageView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        guard let stream = Current.stream else {
            //  if user not in stream
            streamTitleLabel.isHidden = true
            numMembersButton.isHidden = true
            return
        }
        
        // if user in a stream
        streamTitleLabel.isHidden = false
        streamTitleLabel.text = stream.title
        numMembersButton.isHidden = false
        let count = stream.members.count+1
        let message = "\(count) member" + ((count > 1) ? "s" : "")
        numMembersButton.setTitle(message, for: .normal)
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    // set status bar text to white
    override var preferredStatusBarStyle: UIStatusBarStyle { return .lightContent }

}
