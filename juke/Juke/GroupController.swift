//
//  GroupController.swift
//  Juke
//
//  Created by Conner Smith on 2/23/17.
//  Copyright © 2017 csmith. All rights reserved.
//

import UIKit
import Alamofire

class GroupController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    var navBarTitle: String? {
        get {
            return self.navigationItem.title
        }
        set (newValue) {
            self.navigationItem.title = newValue
        }
    }
    
    struct Song {
        let songName: String
        let artist: String
        let spotify_id: String
        let votes: Int
        let progress: Double    // progress in song, synced with owner's device
    }
    
    @IBOutlet var barButton: UIBarButtonItem!
    @IBOutlet var currTimeLabel: UILabel!
    @IBOutlet var timeLeftLabel: UILabel!
    @IBOutlet var currentlyPlayingArtistLabel: UILabel!
    @IBOutlet var currentlyPlayingLabel: UILabel!
    @IBOutlet var songProgressSlider: UISlider!
    @IBOutlet var currentlyPlayingView: UIView!
    @IBOutlet var tableView: UITableView!
    var group: GroupsController.Group?
    let jamsPlayer = JamsPlayer.shared
    var songs = [Song]()
    var selectedIndex: IndexPath?
    let socketManager = SocketManager.sharedInstance
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.delegate = self
        self.tableView.dataSource = self
        NotificationCenter.default.addObserver(self, selector: #selector(GroupController.songFinished), name: Notification.Name("songFinished"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(GroupController.songPositionChanged), name: Notification.Name("songPositionChanged"), object: nil)
        currentlyPlayingView.layer.cornerRadius = 10;
        currentlyPlayingView.layer.masksToBounds = true;
        currentlyPlayingView.layer.borderColor = UIColor.gray.cgColor;
        currentlyPlayingView.layer.borderWidth = 0.5;
        currentlyPlayingView.layer.contentsScale = UIScreen.main.scale;
        currentlyPlayingView.layer.shadowColor = UIColor.black.cgColor;
        currentlyPlayingView.layer.shadowRadius = 5.0;
        currentlyPlayingView.layer.shadowOpacity = 0.5;
        currentlyPlayingView.layer.masksToBounds = false;
        currentlyPlayingView.clipsToBounds = false;
        songProgressSlider.setThumbImage(UIImage(named: "slider_cap"), for: .normal)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navBarTitle = group?.name
        fetchSongs()
    }
    
    @IBAction func searchButtonPressed(_ sender: AnyObject) {
        performSegue(withIdentifier: "searchSegue", sender: sender)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == "searchSegue") {
            let vc = segue.destination as! SearchTableViewController
            vc.group = self.group
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.row == 0 {
            return 0    // hide first row -- should be currently playing track
        }
        return 40
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Table view data source
    
    func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return songs.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let song = self.songs[indexPath.row]
        if indexPath.row == 0 {
            // place first song in the currentlyPlayingLabel
            self.currentlyPlayingLabel.text = song.songName
            self.currentlyPlayingArtistLabel.text = song.artist
        }
        
        let cell = self.tableView.dequeueReusableCell(withIdentifier: "SongCell", for: indexPath) as! SongTableViewCell
        cell.songName.text = song.songName
        cell.artist.text = song.artist
        return cell
    }
    
    private func timeIntervalToString(interval: TimeInterval) -> String {
        let ti = NSInteger(interval)
        let seconds = ti % 60
        let minutes = (ti / 60) % 60
        return NSString(format: "%0.2d:%0.2d", minutes, seconds) as String
    }
    
    func songPositionChanged(notification: NSNotification) {
        if self.songs.count == 0 {
            return
        }
        
        if let data = notification.object as? NSDictionary {
            songProgressSlider.setValue(data["ratio"] as! Float, animated: true)
            let pos = data["position"] as! TimeInterval
            self.currTimeLabel.text = timeIntervalToString(interval: pos)
            let timeLeft = (data["duration"] as! TimeInterval) - pos
            self.timeLeftLabel.text = "-" + timeIntervalToString(interval: timeLeft)
            
            // update progress in db if current user is playlist owner
            if ViewController.currSpotifyID == group?.owner_spotify_id {
                let song_id = self.songs[0].spotify_id
                socketManager.updateSongPositionChanged(group_id: group!.id, song_id: song_id, position: pos)
            }
        }
    }
    
    func songFinished() {
        // pop first song, play next song
        let params: Parameters = ["group_id":self.group?.id as String!]
        Alamofire.request(ServerConstants.kJukeServerURL + ServerConstants.kPopSong, method: .post, parameters: params).responseJSON { response in
            switch response.result {
            case .success:
                self.fetchSongs()
            case .failure(let error):
                print(error)
            }
        }
    }
    
    private func playTopSong() {
        // play first song
        if self.songs.count > 0 {
            DispatchQueue.global(qos: .background).async {
                // play cell at position 0 if it's not already playing
                let song = self.songs[0]
                let id = song.spotify_id
                if self.jamsPlayer.isPlaying(trackID: id) {
                    return
                }
                self.jamsPlayer.playSong(trackID: id, progress: song.progress)
            }
        }
    }
    
    // fetch songs and trigger table reload
    private func fetchSongs() {
        // note that Alamofire doesn't work with optionals -- must force unwrap with "as String!"
        let params: Parameters = ["group_id": self.group?.id as String!]
        Alamofire.request(ServerConstants.kJukeServerURL + ServerConstants.kFetchSongsPath, method: .get, parameters: params).responseJSON { response in
            switch response.result {
            case .success:
                if let songs = response.result.value as? [NSDictionary] {
                    self.songs.removeAll()
                    for item in songs {
                        let id = item["spotify_id"] as! String
                        let song = item["songName"] as! String
                        let artist = item["artistName"] as! String
                        let progress = item["progress"] as! Double
                        let votes = item["votes"] as! Int
                        self.songs.append(Song(songName: song, artist: artist, spotify_id: id, votes: votes, progress: progress))
                    }
                    // update UI on main thread
                    DispatchQueue.main.async {
                        self.tableView.reloadData()
                    }
                    
                    self.playTopSong()
                }
            case .failure(let error):
                print(error)
            }
        }
    }
    
}
