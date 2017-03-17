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
        let duration: Double
    }
    
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
    let playImage = UIImage(named: "play.png")
    let pauseImage = UIImage(named: "pause.png")
    
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
    
    @IBAction func barButtonPressed(_ sender: AnyObject) {
        if self.songs.count == 0 {
            return
        }
        
        let song = self.songs[0]
        let button = sender as! UIBarButtonItem
        var newImage: UIImage
        var newPlayStatus: Bool
        if button.image == playImage {
            // was paused --> switch to pauseImage & play song
            newImage = pauseImage!
            newPlayStatus = true
        } else {
            // was playing --> switch to playImage & pause song
            newImage = playImage!
            newPlayStatus = false
        }

        button.image = newImage
        jamsPlayer.setPlayStatus(shouldPlay: newPlayStatus, trackID: song.spotify_id, position: song.progress)
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
        
        let song = songs[0]
        if let data = notification.object as? NSDictionary {
            // update slider
            let progress = data["position"] as! Double
            updateSlider(song: song, progress: progress)
            
            // update progress in db if current user is playlist owner
            if ViewController.currSpotifyID == group?.owner_spotify_id {
                let song_id = self.songs[0].spotify_id
                socketManager.updateSongPositionChanged(group_id: group!.id, song_id: song_id, position: progress)
            }
        }
    }
    
    private func updateSlider(song: Song, progress: Double) {
        let ratio = progress / song.duration
        let timeLeft = song.duration - progress
        self.songProgressSlider.setValue(Float(ratio), animated: true)
        self.currTimeLabel.text = timeIntervalToString(interval: progress)
        self.timeLeftLabel.text = "-" + timeIntervalToString(interval: timeLeft)
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
    
    private func loadTopSong() {
        if self.songs.count > 0 {
            let song = self.songs[0]
            // update UI on main thread
            DispatchQueue.main.async {
                self.updateSlider(song: song, progress: song.progress)
            }
            
            DispatchQueue.global(qos: .background).async {
                // play cell at position 0 if it's not already playing
                let id = song.spotify_id
                if self.jamsPlayer.isPlaying(trackID: id) {
                    return  // if already playing, let it play
                }
                
                // otherwise, load song and wait for user to press play or tune in/out
                self.jamsPlayer.loadSong(trackID: id, progress: song.progress)
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
                        let duration = item["duration"] as! Double
                        let votes = item["votes"] as! Int
                        self.songs.append(Song(songName: song, artist: artist, spotify_id: id, votes: votes, progress: progress, duration: duration))
                    }
                    // update UI on main thread
                    DispatchQueue.main.async {
                        self.tableView.reloadData()
                    }
                    
                    if songs.count > 0 {
                        self.loadTopSong()
                    }
                }
            case .failure(let error):
                print(error)
            }
        }
    }
    
}
