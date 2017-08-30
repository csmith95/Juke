//
//  StreamMembersTableViewController.swift
//  Juke
//
//  Created by Kojo Worai Osei on 8/23/17.
//  Copyright © 2017 csmith. All rights reserved.
//

import UIKit
import Firebase
import FirebaseDatabaseUI
import AlamofireImage

class StreamMembersTableViewController: UITableViewController {

    @IBOutlet weak var hostImage: UIImageView!
    @IBOutlet var streamMembersTableView: UITableView!
    @IBOutlet weak var hostPresenceDot: UIImageView!
    @IBOutlet weak var hostName: UILabel!
    @IBOutlet var hostTapped: UITapGestureRecognizer!
    
    
    var dataSource: FUITableViewDataSource!
    private let defaultIcon = CircleFilter().filter(UIImage(named: "juke_icon")!)

    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        print("called view did load in stream membesr")
        if let newDataSource = FirebaseAPI.addStreamMembersTableViewListener(streamMembersTableView: streamMembersTableView) {
            self.dataSource = newDataSource
        }
        //streamMembersTableView.delegate = self

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }
    
    override func viewWillAppear(_ animated: Bool) {
//        if let newDataSource = FirebaseAPI.addStreamMembersTableViewListener(streamMembersTableView: streamMembersTableView) {
//            self.dataSource = newDataSource
//        }
        setHost()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 0
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return 0
    }
    
    func setHost() {
        loadUserIcon(url: Current.stream.host.imageURL, imageView: hostImage)
        hostName.text = Current.stream.host.username
        if Current.stream.host.online {
            // set presence dot to be green
            hostPresenceDot.image = #imageLiteral(resourceName: "green dot")
        } else {
            // set presence dot to be red
            hostPresenceDot.image = #imageLiteral(resourceName: "red dot")
        }
    }
    
    private func loadUserIcon(url: String?, imageView: UIImageView) {
        if let unwrappedUrl = url {
            imageView.af_setImage(withURL: URL(string: unwrappedUrl)!, placeholderImage: defaultIcon)
        } else {
            imageView.image = defaultIcon
        }
    }
    
    @IBAction func hostCellTapped(_ sender: Any) {
      
    }
    
    

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if  segue.identifier == "userProfileSegue",
            let destination = segue.destination as? UserProfileViewController,
            let userIndex = tableView.indexPathForSelectedRow?.row
        {
            destination.preloadedUser = Models.FirebaseUser(snapshot: self.dataSource.items[userIndex])
        }
        
        if  segue.identifier == "hostProfileSegue",
            let destination = segue.destination as? UserProfileViewController
        {
            destination.preloadedUser = Current.stream.host
        }
    }


    /*
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier", for: indexPath)

        // Configure the cell...

        return cell
    }
    */

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
