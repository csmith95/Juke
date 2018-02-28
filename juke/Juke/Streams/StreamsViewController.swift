//
//  StreamsViewController.swift
//  Juke
//
//  Created by Kojo Worai Osei on 2/27/18.
//  Copyright © 2018 csmith. All rights reserved.
//

import UIKit
import Firebase
//import FirebaseDatabaseUI

class StreamsViewController: UIViewController {
    
    @IBOutlet weak var streamsTableView: UITableView!
    var streamsDataSource = StarredStreamsDataSource()
    var starredUsersDataSource = StarredUsersDataSource()
    
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        starredUsersDataSource.listen()
        // Track views of this page
        Answers.logContentView(withName: "Starred Streams Page", contentType: "Starred Streams List", contentId: "\(Current.user?.spotifyID ?? "noname"))|StarredStreams")
        
        // Set up notifications
        NotificationCenter.default.addObserver(self, selector: #selector(self.reloadStreams), name: Notification.Name("reloadStarredStreams"), object: nil)
        
        // Set delegate and dataSource
        streamsTableView.dataSource = streamsDataSource
        streamsTableView.delegate = streamsDataSource

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        streamsDataSource.listen()
        StreamsDataSource().listen()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        streamsDataSource.detach()
        starredUsersDataSource.detach()
    }
    
    func reloadStreams() {
        DispatchQueue.main.async {
            objc_sync_enter(self.streamsTableView.dataSource)
            self.streamsTableView.reloadData()
            //self.checkEmptyState()
            objc_sync_exit(self.streamsTableView.dataSource)
        }
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
