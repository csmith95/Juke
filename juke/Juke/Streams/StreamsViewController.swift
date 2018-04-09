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
    var followersSnap: DataSnapshot!
    
    @IBOutlet weak var streamsTableView: UITableView!

    override func viewDidLoad() {
        super.viewDidLoad()
        let followingUsers = StarredUsersDataSource()
        followingUsers.listen()
        
        streamsTableView.dataSource = viewModel
        streamsTableView.delegate = viewModel
        viewModel.delegate = self
        viewModel.streamsVC = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        // Track views of this page
        Answers.logContentView(withName: "Starred Streams Page", contentType: "Starred Streams List", contentId: "\(Current.user?.spotifyID ?? "noname"))|StarredStreams")
        viewModel.loadData()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        FirebaseAPI.ref.child("streams").removeAllObservers()
    }
    
    @IBAction func unwindToViewControllerNameHere(segue: UIStoryboardSegue) {
        //nothing goes here
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
