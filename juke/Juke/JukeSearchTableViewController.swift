//
//  SearchTableViewController.swift
//  Juke
//
//  Created by Kojo Worai Osei on 4/14/17.
//  Copyright © 2017 csmith. All rights reserved.
//

import UIKit
import Alamofire
import AlamofireImage
import Unbox
import Firebase

class JukeSearchTableViewController: UITableViewController, UISearchBarDelegate {
    
    @IBOutlet var searchBar: UISearchBar!
    var allResults:[Models.SpotifySong] = []           // all results
    var displayedResults:[Models.SpotifySong] = []  // filtered results
    typealias JSONStandard = [String: AnyObject]
    
    // this method will be called with lowercased search text. subclass should 
    // handle how to translate searchText to a filtered set of results.
    func execSearch(keywords: String) {
        fatalError("This method must be overridden by subclass")
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        execSearch(keywords: searchText.lowercased())
    }
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        searchBar.setShowsCancelButton(true, animated: true)
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        if let searchText = searchBar.text {
            execSearch(keywords: searchText.lowercased())
        } else {
            execSearch(keywords: "")
        }
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        execSearch(keywords: "")
        hideKeyboard()
    }
    
    func threadSafeReloadView() {
        objc_sync_enter(tableView)
        tableView.reloadData()
        objc_sync_exit(tableView)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(hideKeyboard))
        self.tableView.addGestureRecognizer(tapRecognizer)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        // reset UI
        self.searchBar.text = ""
        execSearch(keywords: "")
        hideKeyboard()
    }
    
    func hideKeyboard() {
        self.view.endEditing(true)
        searchBar.setShowsCancelButton(false, animated: true)
    }
    
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        hideKeyboard()
    }

    // MARK: - Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return displayedResults.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "SearchCell") as! SearchCell
        cell.populateCell(song: self.displayedResults[indexPath.row])
        
//        cell.tapAction = { (cell) in
//            FirebaseAPI.queueSong(spotifySong: self.displayedResults[indexPath.row])
//            cell.addToStreamButton.isSelected = true
//        }
        
//        let mainLabel = cell.viewWithTag(1) as! UILabel
//        let artistLabel = cell.viewWithTag(2) as! UILabel
        
//        mainLabel.text = displayedResults[indexPath.row].songName
//        artistLabel.text = displayedResults[indexPath.row].artistName
        
        return cell
    }
    
    // set status bar text to white
    override var preferredStatusBarStyle: UIStatusBarStyle { return .lightContent }
}
