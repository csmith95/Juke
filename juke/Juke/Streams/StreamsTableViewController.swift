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
import XLPagerTabStrip

class StreamsTableViewController: UITableViewController, UISearchBarDelegate, IndicatorInfoProvider {
    
    //@IBOutlet var searchBar: UISearchBar!
    @IBOutlet var streamsTableView: UITableView!
    let defaultImage = CircleFilter().filter(UIImage(named: "juke_icon")!)
    public var streamsDataSource = StreamsDataSource()

    override func viewDidLoad() {
        super.viewDidLoad()

        streamsTableView.dataSource = streamsDataSource
        streamsTableView.delegate = streamsDataSource
        

        
        NotificationCenter.default.addObserver(self, selector: #selector(self.reloadStreams), name: Notification.Name("reloadStreams"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.reloadStreams), name: Notification.Name("reloadStarredStreams"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.newStreamJoined), name: Notification.Name("newStreamJoined"), object: nil)
        NotificationCenter.default.addObserver(forName: Notification.Name("allStreamsSearchNotification"), object: nil, queue: nil, using: execSearchQuery)

    }
    
    func indicatorInfo(for pagerTabStripController: PagerTabStripViewController) -> IndicatorInfo {
        return IndicatorInfo(title: "All")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        //execSearchQuery()
    }
    
//    func hideKeyboard() {
//        self.view.endEditing(true)
//        searchBar.setShowsCancelButton(false, animated: true)
//    }
//    
    private func execSearchQuery(notification: Notification) {
        guard let userInfo = notification.userInfo else { return }
        if let source = tableView.dataSource as? CustomDataSource {
            source.searchBy(query: userInfo["query"] as! String)
        }
    }
//
//    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
//        execSearchQuery()
//    }
    
//    func searchBar(_ searchBar: UISearchBar, selectedScopeButtonIndexDidChange selectedScope: Int) {
//        // print what selectedScope
//        print("**SCOPE CHANGED; selectedScope**", selectedScope)
//        if(searchBar.selectedScopeButtonIndex == 0) {
//            streamsTableView.dataSource = starredStreamsDataSource
//            streamsTableView.delegate = starredStreamsDataSource
//            reloadStreams()
//        } else {
//            streamsTableView.dataSource = streamsDataSource
//            streamsTableView.delegate = streamsDataSource
//            reloadStreams()
//        }
//    }
    
//    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
//        searchBar.setShowsCancelButton(true, animated: true)
//    }
//    
//    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
//        searchBar.text = ""
//        execSearchQuery()
//        hideKeyboard()
//    }
    
    // triggered from data source class
    func reloadStreams() {
        print("called reload streams for streams table vc")
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
    
    // triggered by CustomDataSource posting a notification. The view controller
    // should take user to the new stream screen
    func newStreamJoined() {
        self.tabBarController?.selectedIndex = 2
    }
    
    // set status bar content to white text
    override var preferredStatusBarStyle: UIStatusBarStyle { return .lightContent }
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

}


