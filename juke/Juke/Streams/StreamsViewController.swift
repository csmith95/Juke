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
    
    fileprivate let viewModel = StreamsViewModel()
    
    @IBOutlet weak var streamsTableView: UITableView!
//    var streamsDataSource = StarredStreamsDataSource().listen()
//    var starredUsersDataSource = StarredUsersDataSource().listen()
    
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        streamsTableView.dataSource = viewModel
        streamsTableView.delegate = viewModel
        //streamsTableView.sectionFooterHeight = 1
        viewModel.delegate = self
        let followingUsers = StarredUsersDataSource()
        followingUsers.listen()
        // Track views of this page
        Answers.logContentView(withName: "Starred Streams Page", contentType: "Starred Streams List", contentId: "\(Current.user?.spotifyID ?? "noname"))|StarredStreams")
        
        viewModel.loadData()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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

extension StreamsViewController: StreamsViewModelDelegate {
    func didFinishUpdates() {
        streamsTableView?.reloadData()
    }
}
