//
//  MembersTableViewController.swift
//  Juke
//
//  Created by Conner Smith on 9/16/17.
//  Copyright © 2017 csmith. All rights reserved.
//

import UIKit

class MembersTableViewController: UITableViewController {
    
    @IBOutlet var unwindButton: UIButton!
    
    // this should be set from MyStreamController before segue
    var stream: Models.FirebaseStream!

    // MARK: - Table view data source
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        unwindButton.setTitle(stream.title, for: .normal)
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return stream.members.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "UserCell", for: indexPath) as! UserCell
        cell.populateCell(member: stream.members[indexPath.row])
        return cell
    }
    
}
