//
//  StreamsHistory.swift
//  Juke
//
//  Created by Kojo Worai Osei on 3/27/18.
//  Copyright © 2018 csmith. All rights reserved.
//

import UIKit
import Firebase

class StreamsHistoryViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var numSongs: UILabel!
    @IBOutlet weak var numListens: UILabel!
    @IBOutlet weak var hostName: UILabel!
    @IBOutlet weak var hostImg: UIImageView!
    @IBOutlet weak var streamTitle: UILabel!
    public var streamID: String!
    public var allSongs: [Models.SpotifySong] = []
    @IBOutlet weak var headerView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.contentInset = UIEdgeInsetsMake(headerView.frame.height, 0, 0, 0)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        // perform observation of stream details
        loadData()
    }
    
    func loadData() {
        // clear all songs before loading new data
        allSongs.removeAll()
        
        FirebaseAPI.ref.child("/streamsHistory/-L8fHrwj2w0VaD64sZp6").observeSingleEvent(of: .value, with: { (snapshot) in
            //let value = snapshot.value as? NSDictionary
            if let stream = Models.FirebaseStream(snapshot: snapshot) {
                self.streamTitle.text = stream.title
                self.numListens.text = String(stream.members.count)
                self.hostName.text = "Hosted by \(stream.host.username)"
                self.hostImg.af_setImage(withURL: URL(string: stream.host.imageURL!)!)
                
            }
        })
        
        FirebaseAPI.ref.child("/membersHistory/-L8fHrwj2w0VaD64sZp6/").observeSingleEvent(of: .value, with: { (snapshot) in
            if !snapshot.exists() {
                self.numListens.text = "0"
            } else {
                self.numListens.text = String(snapshot.childrenCount)
            }
        })
        
        FirebaseAPI.ref.child("/songsHistory/-L8fHrwj2w0VaD64sZp6").observeSingleEvent(of: .value, with: { (snapshot) in
            self.numSongs.text = String(snapshot.childrenCount)
            let enumerator = snapshot.children
            while let song = enumerator.nextObject() as? DataSnapshot {
                let firebaseSong = Models.FirebaseSong(snapshot: song)
                // MARK: refactor - but yyy??
                let spotifySong = Models.SpotifySong(songName: (firebaseSong?.songName)!, artistName: (firebaseSong?.artistName)!, spotifyID: (firebaseSong?.spotifyID)!, duration: (firebaseSong?.duration)!, coverArtURL: (firebaseSong?.coverArtURL)!)
                self.allSongs.append(spotifySong)
            }
            print("all songs", self.allSongs)
            self.threadSafeReloadView()
        })
    }
    
    private func threadSafeReloadView() {
        objc_sync_enter(tableView)
        tableView.reloadData()
        objc_sync_exit(tableView)
    }
    
}


extension StreamsHistoryViewController: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return allSongs.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return tableView.dequeueReusableCell(withIdentifier: "SpotifySearchCell", for: indexPath)
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let cell = cell as! SearchCell
        cell.populateCell(song: self.allSongs[indexPath.row])
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return CGFloat(44)
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = Bundle.main.loadNibNamed("ResumeHeaderTableViewCell", owner: self, options: nil)?.first as! ResumeHeaderTableViewCell
        headerView.backgroundColor = UIColor.clear
        headerView.resumeInviteBtn.layer.cornerRadius = 20
        headerView.resumeInviteBtn.layer.borderWidth = 1
        headerView.resumeInviteBtn.layer.borderColor = UIColor.purple.cgColor
        return headerView
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        //print(headerView.frame.height)
        let y = headerView.frame.height - (scrollView.contentOffset.y + headerView.frame.height)
        let height = min(max(y, 150), 450)
        headerView.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.size.width, height: height)
    }
}
