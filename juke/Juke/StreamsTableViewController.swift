//
//  ContactsTableViewController.swift
//  Juke
//
//  Created by Conner Smith on 3/28/17.
//  Copyright © 2017 csmith. All rights reserved.
//

import UIKit
import AlamofireImage
import Alamofire
import Unbox
import PKHUD
import SCLAlertView
import Firebase
import FirebaseDatabaseUI

class StreamsTableViewController: UIViewController, UITableViewDelegate, UISearchBarDelegate {
    
    @IBOutlet var tableView: UITableView!
    @IBOutlet var backgroundImage: UIImageView!
    @IBOutlet var searchBar: UISearchBar!
    let defaultImage = CircleFilter().filter(UIImage(named: "juke_icon")!)
    let firebaseRef = Database.database().reference()
    var dataSource: FUITableViewDataSource!
    var friendsDataSource: FUITableViewDataSource!
    
    enum Scope: Int {
        case Streams = 0, Friends   // struct to keep track of which scope is selected
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Discover"
        backgroundImage.image = #imageLiteral(resourceName: "jukedef")
        tableView.delegate = self
        searchBar.delegate = self
        if let dataSource = FirebaseAPI.addDiscoverStreamsTableViewListener(allStreamsTableView: self.tableView) {
            self.dataSource = dataSource
        }
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        hideKeyboard()
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        hideKeyboard()
    }
    
    func hideKeyboard() {
        self.view.endEditing(true)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        tableView.reloadData()  // fixes music indicator bug in build 3
    }
    
    func searchBar(_ searchBar: UISearchBar, selectedScopeButtonIndexDidChange selectedScope: Int) {
        switch (selectedScope) {
        case Scope.Streams.rawValue:
            if let dataSource = FirebaseAPI.addDiscoverStreamsTableViewListener(allStreamsTableView: self.tableView) {
                self.dataSource = dataSource
            }
            break
        case Scope.Friends.rawValue:
            if let dataSource = FirebaseAPI.addFriendsTableViewListener(friendsTableView: self.tableView) {
                self.dataSource = dataSource
            }
            break
        default:
            print("unrecognized scope...")
        }
        
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let stream = Models.FirebaseStream(snapshot: self.dataSource.items[indexPath.row]) else { return }
        if stream.streamID == Current.stream.streamID {
            tableView.cellForRow(at: indexPath)?.setSelected(false, animated: false)
            return  // do nothing if already tuned in
        }
        HUD.show(.progress)
        FirebaseAPI.joinStream(stream: stream) { success in
            if success {
                HUD.flash(.success, delay: 0.75) { success in
                    self.tabBarController?.selectedIndex = 1
                }
            } else {
                HUD.flash(.error, delay: 1.0)
            }
        }
    }

}
