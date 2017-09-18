//
//  StarUserTableViewController.swift
//  Juke
//
//  Created by Kojo Worai Osei on 9/17/17.
//  Copyright © 2017 csmith. All rights reserved.
//

import UIKit

class StarredTableViewController: UITableViewController {

    @IBOutlet var starredTableView: UITableView!
    @IBOutlet weak var searchBar: UISearchBar!
    var starredDataSource = StarredUsersDataSource()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        starredTableView.dataSource = starredDataSource
        starredTableView.delegate = starredDataSource
        
        // setup notifications received from usersDataSource
        NotificationCenter.default.addObserver(self, selector: #selector(self.reloadStarredUsers), name: Notification.Name("reloadStarredUsers"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.hideKeyboard), name: Notification.Name("hideKeyboard"), object: nil)


        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
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
    
    func hideKeyboard() {
        self.view.endEditing(true)
        searchBar.setShowsCancelButton(false, animated: true)
    }
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        print("began editing in users table view controller")
        searchBar.setShowsCancelButton(true, animated: true)
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.text = ""
        execSearchQuery()
        hideKeyboard()
    }
    
    private func execSearchQuery() {
        if let source = starredTableView.dataSource as? CustomDataSource, let query = searchBar.text {
            source.searchBy(query: query)
        }
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        execSearchQuery()
    }
    
    // triggered from data source class
    func reloadStarredUsers() {
        DispatchQueue.main.async {
            objc_sync_enter(self.starredTableView.dataSource)
            self.starredTableView.reloadData()
            objc_sync_exit(self.starredTableView.dataSource)
        }
    }
    
    // set status bar text to white
    override var preferredStatusBarStyle: UIStatusBarStyle { return .lightContent }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }


}
