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
    
    struct SongData {
        let songName: String
        let artist: String
        let id: String
    }
    
    @IBOutlet var currentlyPlayingArtistLabel: UILabel!
    @IBOutlet var currentlyPlayingLabel: UILabel!
    @IBOutlet var songProgressSlider: UISlider!
    @IBOutlet var currentlyPlayingView: UIView!
    @IBOutlet var tableView: UITableView!
    var group: GroupsController.Group?
    let jamsPlayer = JamsPlayer.shared
    var songIDs = [String]()
    var songData = [String: SongData]()     // id --> songName, artist, id
    var selectedIndex: IndexPath?
    
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
        fetchSongIDs()
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
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        // play cell at position 0 if it's not already playing
        if indexPath.row == 0 {
            let id = self.songIDs[0]
            if jamsPlayer.isPlaying(trackID: id) {
                return
            }
            DispatchQueue.global(qos: .background).async {
                self.jamsPlayer.playSong(trackID: id)
            }
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
        return songIDs.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if indexPath.row == 0 {
            // place first song in the currentlyPlayingLabel
            if let song = self.songData[self.songIDs[0]] {
                self.currentlyPlayingLabel.text = song.songName
                self.currentlyPlayingArtistLabel.text = song.artist
            }
        }
        
        let cell = self.tableView.dequeueReusableCell(withIdentifier: "SongCell", for: indexPath) as! SongTableViewCell
        if let song = self.songData[self.songIDs[indexPath.row]] {
            cell.songName.text = song.songName
            cell.artist.text = song.artist
        }

        return cell
    }
    
    func songPositionChanged(notification: NSNotification) {
        if let progress = notification.object as? Float {
            songProgressSlider.setValue(progress, animated: true)
        }
    }
    
    func songFinished() {
        // pop first song, play next song
        let params: Parameters = ["group_id":self.group?.id as String!]
        print(params)
        Alamofire.request(ServerConstants.kJukeServerURL + ServerConstants.kPopSong, method: .post, parameters: params).responseJSON { response in
            switch response.result {
            case .success:
                print(response.result.value)
                print("Popped song")
                self.fetchSongIDs()
            case .failure(let error):
                print(error)
            }
        }
    }
    
    private func fetchSongData() {
        let group = DispatchGroup() // to ensure view only reloads after all songs fetched
        self.songData.removeAll()
        for id in self.songIDs {
            group.enter()
            Alamofire.request(ServerConstants.kSpotifyTrackDataURL + id, method: .get).responseJSON { response in
                switch response.result {
                case .success:
                    if let response = response.result.value as? NSDictionary {
                        objc_sync_enter(self.songData)
                        let id = response["id"] as! String
                        let songName = response["name"] as! String
                        let artist = ((response["artists"] as! NSArray)[0] as! NSDictionary)["name"] as! String
                        self.songData[id] = SongData(songName: songName, artist: artist, id: id)
                        objc_sync_exit(self.songData)
                    }
                case .failure(let error):
                    print(error)
                }
                group.leave()
            }
        }
        
        // reload on main thread after all responses come in
        group.notify(queue: .main) {
            self.tableView.reloadData()
        }
    }
    
    
    // fetch songs and trigger table reload
    private func fetchSongIDs() {
        // note that Alamofire doesn't work with optionals -- must force unwrap with "as String!"
        let params: Parameters = ["group_id":self.group?.id as String!]
        Alamofire.request(ServerConstants.kJukeServerURL + ServerConstants.kFetchSongsPath, method: .get, parameters: params).responseJSON { response in
            switch response.result {
            case .success:
                if let response = response.result.value as? [String]{
                    // the line below transforms [*:*:id] --> [id]
                    self.songIDs = response.map {$0.characters.split{$0 == ":"}.map(String.init)[2]}
                    self.fetchSongData()
                }
            case .failure(let error):
                print(error)
            }
        }
    }

}
