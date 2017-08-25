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
    
    @IBOutlet var backgroundImage: UIImageView!
    @IBOutlet var tableView: UITableView!
    let defaultImage = CircleFilter().filter(UIImage(named: "juke_icon")!)
    let firebaseRef = Database.database().reference()
    var dataSource: FUITableViewDataSource!

    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Discover Streams"
        tableView.delegate = self
//        searchBar.scopeButtonTitles = ["Streams", "Friends"]
//        searchBar.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        backgroundImage.image = #imageLiteral(resourceName: "jukedef")
        self.navigationController?.title = "Discover"
        if let dataSource = FirebaseAPI.addDiscoverStreamsTableViewListener(allStreamsTableView: self.tableView) {
            self.dataSource = dataSource
        }
        tableView.reloadData()  // fixes music indicator bug in build 3
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
