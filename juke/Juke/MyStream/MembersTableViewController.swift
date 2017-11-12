//
//  MembersTableViewController.swift
//  Juke
//
//  Created by Conner Smith on 9/16/17.
//  Copyright © 2017 csmith. All rights reserved.
//

import UIKit
import Crashlytics

class MembersTableViewController: UIViewController {
    
    
    @IBOutlet var tableView: UITableView!
    @IBOutlet var unwindButton: UIButton!
    
    // this should be set from MyStreamController before segue
    var stream: Models.FirebaseStream!

    // MARK: - Table view data source
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        unwindButton.setTitle(stream.title, for: .normal)
    }
    
    override func viewDidLoad() {
        // track views of this page
        Answers.logContentView(withName: "Stream Members Page", contentType: "Stream Members List", contentId: "\(String(describing: Current.user?.spotifyID))memberspage")
    }
    
    // set status bar text to white
    override var preferredStatusBarStyle: UIStatusBarStyle { return .lightContent }
    
}

extension MembersTableViewController: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return stream.members.count+1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "UserCell", for: indexPath) as! UserCell
        if indexPath.row == 0 {
            cell.populateCell(member: stream.host)
        } else {
            cell.populateCell(member: stream.members[indexPath.row-1])
        }
        return cell
    }
}
