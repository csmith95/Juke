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
    @IBOutlet var endStreamButton: UIButton!
    
    override func viewWillAppear(_ animated: Bool) {
        print("viewWillAppear. stream nil: ", Current.stream == nil)
        setUI()
        super.viewWillAppear(animated)
    }
    
    private func setUI() {
        print("setting UI")
        guard let stream = Current.stream else {
            //  if user not in stream
            streamTitleLabel.isHidden = true
            numMembersButton.isHidden = true
            endStreamButton.isHidden = true
            return
        }
        
        // if user in a stream
        endStreamButton.isHidden = false
        if Current.isHost() {
            endStreamButton.setTitle("End stream", for: .normal)
        } else {
            endStreamButton.setTitle("Leave stream", for: .normal)
        }
        streamTitleLabel.isHidden = false
        streamTitleLabel.text = stream.title
        numMembersButton.isHidden = false
        let count = stream.members.count+1
        let message = "\(count) member" + ((count > 1) ? "s" : "")
        numMembersButton.setTitle(message, for: .normal)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ShowMembers" {
            guard let stream = Current.stream else { return }
            let dest = segue.destination as! MembersTableViewController
            dest.stream = stream
        }
    }

    @IBAction func endStreamPressed(_ sender: Any) {
        Current.stream = nil
        setUI()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func unwindToViewControllerNameHere(segue: UIStoryboardSegue) {
        //nothing goes here
    }
    

    // set status bar text to white
    override var preferredStatusBarStyle: UIStatusBarStyle { return .lightContent }

}
