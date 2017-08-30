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

class StreamsTableViewController: UIViewController, UISearchBarDelegate {
    
    @IBOutlet var tableView: UITableView!
    @IBOutlet var backgroundImage: UIImageView!
    @IBOutlet var searchBar: UISearchBar!
    let defaultImage = CircleFilter().filter(UIImage(named: "juke_icon")!)
    var streamsDataSource = StreamsDataSource()
    var friendsDataSource = FriendsDataSource()
    
    enum Scope: Int {
        case Streams = 0, Friends   // struct to keep track of which scope is selected
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Discover"
        backgroundImage.image = #imageLiteral(resourceName: "jukedef")
        searchBar.delegate = self
        tableView.dataSource = streamsDataSource
        tableView.delegate = streamsDataSource
        NotificationCenter.default.addObserver(self, selector: #selector(self.reloadCollection), name: Notification.Name("reloadCollection"), object: nil)
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
        reloadCollection()
    }
    
    func searchBar(_ searchBar: UISearchBar, selectedScopeButtonIndexDidChange selectedScope: Int) {
        
        if selectedScope == Scope.Streams.rawValue {
            tableView.dataSource = streamsDataSource
            tableView.delegate = streamsDataSource
        } else {
          tableView.dataSource = friendsDataSource
          tableView.delegate = friendsDataSource
        }
        
       reloadCollection()
    }
    
    // triggered from data source clas
    func reloadCollection() {
        DispatchQueue.main.async {
            objc_sync_enter(self.tableView.dataSource)
            self.tableView.reloadData()
            objc_sync_exit(self.tableView.dataSource)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // idea: write a separate data source class that takes in 
    // an equals function and a sort function and maintains 
    // a list of a new data type that includes both Models.User and Models.Stream
    // all methods threadsafe
    // maintains filtered list and total list
    // only allows access to filtered list
    // this class simply changes pointer to data list
    // use the enum/class stored value property to convey whether Friend or Stream


}
