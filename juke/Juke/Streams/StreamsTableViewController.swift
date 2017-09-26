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
    
    @IBOutlet var streamsTableView: UITableView!
    let defaultImage = CircleFilter().filter(UIImage(named: "juke_icon")!)
    public var streamsDataSource = StreamsDataSource()

    override func viewDidLoad() {
        super.viewDidLoad()

        streamsTableView.dataSource = streamsDataSource
        streamsTableView.delegate = streamsDataSource
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.reloadStreams), name: Notification.Name("reloadStreams"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.newStreamJoined), name: Notification.Name("newStreamJoined"), object: nil)
        NotificationCenter.default.addObserver(forName: Notification.Name("allStreamsSearchNotification"), object: nil, queue: nil, using: execSearchQuery)
    }
    
    func indicatorInfo(for pagerTabStripController: PagerTabStripViewController) -> IndicatorInfo {
        return IndicatorInfo(title: "All")
    }
    
    private func execSearchQuery(notification: Notification) {
        guard let userInfo = notification.userInfo else { return }
        if let source = tableView.dataSource as? CustomDataSource {
            source.searchBy(query: userInfo["query"] as! String)
        }
    }
    
    // triggered from data source class
    func reloadStreams() {
        print("reload streams")
        DispatchQueue.main.async {
            objc_sync_enter(self.streamsTableView.dataSource)
            self.streamsTableView.reloadData()
            objc_sync_exit(self.streamsTableView.dataSource)
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
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

}


