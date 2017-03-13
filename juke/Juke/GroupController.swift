//
//  GroupController.swift
//  Juke
//
//  Created by Conner Smith on 2/23/17.
//  Copyright © 2017 csmith. All rights reserved.
//

import UIKit
import Alamofire

class GroupController: UIViewController, UITableViewDelegate, UITableViewDataSource, SPTAudioStreamingDelegate, SPTAudioStreamingPlaybackDelegate {

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
    
    @IBOutlet var tableView: UITableView!
    var group: GroupsController.Group?
    let jamsPlayer = JamsPlayer.shared
    var songIDs = [String]()
    var songData = [String: SongData]()     // id --> songName, artist, id
    var selectedIndex: IndexPath?
    
    public static func configureJamsPlayer() {
        // TODO: migrate init code from JamesPlayer
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.delegate = self
        self.tableView.dataSource = self
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
    
    func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        // TODO: play cell at position 0 if it's not already playing
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let previouslySelected = self.selectedIndex {
            let cell = tableView.cellForRow(at: previouslySelected) as! SongTableViewCell
            cell.songName.textColor = UIColor.black
            if previouslySelected.row == indexPath.row {
                DispatchQueue.global(qos: .background).async {
                    self.jamsPlayer.togglePlaybackState()
                }
                return
            }
        }
        
        let selected = tableView.cellForRow(at: indexPath) as! SongTableViewCell
        selected.songName.textColor = UIColor.green
        self.selectedIndex = indexPath
        DispatchQueue.global(qos: .background).async {
            self.jamsPlayer.playSong(trackID: self.songIDs[indexPath.row])
        }
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
        let cell = self.tableView.dequeueReusableCell(withIdentifier: "SongCell", for: indexPath) as! SongTableViewCell
        if let song = self.songData[self.songIDs[indexPath.row]] {
            cell.songName.text = song.songName
            cell.artist.text = song.artist
        }

        return cell
    }
    
    func fetchSongData() {
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
    func fetchSongIDs() {
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
