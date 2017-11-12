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
    let usersDataSource = UsersDataSource()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        usersTableView.dataSource = usersDataSource
        usersTableView.delegate = usersDataSource
        
        // setup notifications received from usersDataSource
        NotificationCenter.default.addObserver(self, selector: #selector(self.reloadAllUsers), name: Notification.Name("reloadAllUsers"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.hideKeyboard), name: Notification.Name("hideKeyboard"), object: nil)
        
        // track views of this page
        Answers.logContentView(withName: "All Users Page", contentType: "All Users list", contentId: "\(Current.user?.spotifyID ?? "noname"))|allUserViews")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        usersDataSource.listen()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        usersDataSource.detach()
    }
    
    @IBAction func doneButtonPressed(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    
    func hideKeyboard() {
        self.view.endEditing(true)
        searchBar.setShowsCancelButton(false, animated: true)
    }
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        searchBar.setShowsCancelButton(true, animated: true)
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.text = ""
        execSearchQuery()
        hideKeyboard()
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
    func reloadAllUsers() {
        DispatchQueue.main.async {
            objc_sync_enter(self.usersTableView.dataSource)
            self.usersTableView.reloadData()
            objc_sync_exit(self.usersTableView.dataSource)
        }
    }
    
    // set status bar text to white
    override var preferredStatusBarStyle: UIStatusBarStyle { return .lightContent }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
