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
    var usersDataSource = UsersDataSource()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        usersTableView.dataSource = usersDataSource
        usersTableView.delegate = usersDataSource
        searchBar.delegate = self
        
        // setup notifications received from usersDataSource
        NotificationCenter.default.addObserver(self, selector: #selector(self.reloadCollection), name: Notification.Name("reloadCollection"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.hideKeyboard), name: Notification.Name("hideKeyboard"), object: nil)
    }
    
    func hideKeyboard() {
        self.view.endEditing(true)
        searchBar.setShowsCancelButton(false, animated: true)
    }
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        print("began")
        searchBar.setShowsCancelButton(true, animated: true)
    }
    
    private func execSearchQuery() {
        if let source = tableView.dataSource as? CustomDataSource, let query = searchBar.text {
            source.searchBy(query: query)
        }
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        execSearchQuery()
    }
    
    // triggered from data source class
    func reloadCollection() {
        DispatchQueue.main.async {
            objc_sync_enter(self.tableView.dataSource)
            self.tableView.reloadData()
            objc_sync_exit(self.tableView.dataSource)
        }
    }
    
    // set status bar text to white
    override var preferredStatusBarStyle: UIStatusBarStyle { return .lightContent }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
