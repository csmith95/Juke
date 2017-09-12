//
//  UsersTableViewController.swift
//  Juke
//
//  Created by Kojo Worai Osei on 9/9/17.
//  Copyright © 2017 csmith. All rights reserved.
//

import UIKit
import Firebase
import FirebaseDatabaseUI

class UsersTableViewController: UITableViewController, UISearchBarDelegate {

    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet var usersTableView: UITableView!
    var friendsDataSource = FriendsDataSource()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        usersTableView.dataSource = friendsDataSource
        usersTableView.delegate = friendsDataSource
        searchBar.delegate = self
        // setup notifications
        // MARK: do we need all of these with new swipe for more feature?
        NotificationCenter.default.addObserver(self, selector: #selector(self.reloadCollection), name: Notification.Name("reloadCollection"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.hideKeyboard), name: Notification.Name("hideKeyboard"), object: nil)
        

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }
    
    func hideKeyboard() {
        self.view.endEditing(true)
    }
    
    private func execSearchQuery() {
        if let source = tableView.dataSource as? CustomDataSource, let query = searchBar.text {
            source.searchBy(query: query)
        }
    }
    
//    func searchBar(_ searchBar: UISearchBar, selectedScopeButtonIndexDidChange selectedScope: Int) {
//        searchBar.text = ""
//        execSearchQuery()
//    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        execSearchQuery()
        if searchText.isEmpty {
            hideKeyboard()
        }
    }
    
    // triggered from data source class
    func reloadCollection() {
        DispatchQueue.main.async {
            objc_sync_enter(self.tableView.dataSource)
            self.tableView.reloadData()
            objc_sync_exit(self.tableView.dataSource)
        }
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle { return .lightContent }

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
