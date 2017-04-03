//
//  StreamController.swift
//  Juke
//
//  Created by Conner Smith on 2/23/17.
//  Copyright © 2017 csmith. All rights reserved.
//

import UIKit
import Alamofire
import Unbox
import KYCircularProgress
import AlamofireImage

class MyStreamController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    var navBarTitle: String? {
        get {
            return self.navigationItem.title
        }
        set (newValue) {
            self.navigationItem.title = newValue
        }
    }
    
    @IBOutlet var onlineButton: UIButton!
    @IBOutlet var circularProgressFrame: UIView!
    @IBOutlet var coverArtImage: UIImageView!
    @IBOutlet var barButton: UIBarButtonItem!
    @IBOutlet var currTimeLabel: UILabel!
    @IBOutlet var currentlyPlayingArtistLabel: UILabel!
    @IBOutlet var currentlyPlayingLabel: UILabel!
    @IBOutlet var currentlyPlayingView: UIView!
    @IBOutlet var tableView: UITableView!
    let jamsPlayer = JamsPlayer.shared
    let socketManager = SocketManager.sharedInstance
    @IBOutlet var listenButton: UIButton!
    var circularProgress = KYCircularProgress()
    
    @IBAction func toggleListening(_ sender: AnyObject) {
        if CurrentUser.currStream!.songs.count == 0 {
            return
        }
        
        let song = CurrentUser.currStream!.songs[0]
        let newPlayStatus = !listenButton.isSelected
        listenButton.isSelected = newPlayStatus
        jamsPlayer.setPlayStatus(shouldPlay: newPlayStatus, trackID: song.spotifyID, position: song.progress)
    }
    
    @IBAction func toggleOnlineStatus(_ sender: AnyObject) {
        let newOnlineStatus = !onlineButton.isSelected
        onlineButton.isSelected = newOnlineStatus
        let url = ServerConstants.kJukeServerURL + ServerConstants.kChangeOnlineStatus
        let params: Parameters = ["streamID": CurrentUser.currStream!.streamID, "isLive": newOnlineStatus]
        Alamofire.request(url, method: .post, parameters: params).validate().responseJSON { response in
            switch response.result {
            case .success:
                do {
                    let unparsedStream = response.result.value as! UnboxableDictionary
                    let stream: Models.Stream = try unbox(dictionary: unparsedStream)
                    CurrentUser.currStream = stream
                } catch {
                    print("error unboxing new stream after changing online status: ", error)
                }
            case .failure(let error):
                print("error changing live status: ", error)
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.delegate = self
        self.tableView.dataSource = self
        NotificationCenter.default.addObserver(self, selector: #selector(StreamController.songFinished), name: Notification.Name("songFinished"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(StreamController.songPositionChanged), name: Notification.Name("songPositionChanged"), object: nil)
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
        self.circularProgress = KYCircularProgress(frame: self.circularProgressFrame.bounds)
        self.circularProgress.startAngle =  -1 * M_PI_2
        self.circularProgress.endAngle = -1 * M_PI_2 + 2*M_PI
        self.circularProgress.lineWidth = 2.0
        self.circularProgress.colors = [.blue, .yellow, .red]
        self.circularProgressFrame.addSubview(self.circularProgress)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navBarTitle = "My Jam"
        self.onlineButton.setImage(UIImage(named: "online.png"), for: .normal)
        self.onlineButton.setImage(UIImage(named: "offline.png"), for: .selected)
        fetchMyStream();
    }
    
    func fetchMyStream() {
        // fetch stream for user. if not tuned in, creates and returns an offline stream by default
        let url = ServerConstants.kJukeServerURL + ServerConstants.kFetchStream
        let params: Parameters = ["ownerSpotifyID": CurrentUser.currUser!.spotifyID]
        Alamofire.request(url, method: .get, parameters: params).validate().responseJSON { response in
            switch response.result {
            case .success:
                do {
                    let unparsedStream = response.result.value as! UnboxableDictionary
                    let stream: Models.Stream = try unbox(dictionary: unparsedStream)
                    CurrentUser.currStream = stream
                    
                    // TODO: join socket room on backend..? not sure how without going through socket events
                    // self.socketManager.joinStream(userID: CurrentUser.currUser!.id, streamID: CurrentUser.currStream!.streamID)
                    DispatchQueue.main.async {
                        self.onlineButton.isSelected = CurrentUser.currStream!.isLive
                        if (CurrentUser.currStream?.owner.spotifyID == CurrentUser.currUser?.spotifyID) {
                            self.listenButton.setImage(UIImage(named: "play.png"), for: .normal)
                            self.listenButton.setImage(UIImage(named: "pause.png"), for: .selected)
                        } else {
                            self.listenButton.setImage(UIImage(named: "listening.png"), for: .normal)
                            self.listenButton.setImage(UIImage(named: "mute.png"), for: .selected)
                        }
                        self.tableView.reloadData()
                        self.loadTopSong(shouldPlay: false)
                    }
                } catch {
                    print("Error unboxing stream: ", error)
                }
                
            case .failure(let error):
                print("Error fetching stream: ", error)
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

//    // MARK: - Table view data source
    func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        if (CurrentUser.currStream == nil) {
            return 0
        }
        return CurrentUser.currStream!.songs.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let song = CurrentUser.currStream!.songs[indexPath.row]
        if indexPath.row == 0 {
            // place first song in the currentlyPlayingLabel
            self.currentlyPlayingLabel.text = song.songName
            self.currentlyPlayingArtistLabel.text = song.artistName
        }
        
        let cell = self.tableView.dequeueReusableCell(withIdentifier: "SongCell", for: indexPath) as! SongTableViewCell
        cell.songName.text = song.songName
        cell.artist.text = song.artistName
        return cell
    }
    
    private func timeIntervalToString(interval: TimeInterval) -> String {
        let ti = NSInteger(interval)
        let seconds = ti % 60
        let minutes = (ti / 60) % 60
        return NSString(format: "%0.2d:%0.2d", minutes, seconds) as String
    }
    
    func songPositionChanged(notification: NSNotification) {
        if CurrentUser.currStream == nil || CurrentUser.currStream!.songs.count == 0 {
            return
        }
        
        let stream = CurrentUser.currStream!
        let songs = stream.songs
        let song = songs[0]
        if let data = notification.object as? NSDictionary {
            // update slider
            let progress = data["position"] as! Double
            updateSlider(song: song, progress: progress)
            
            // update progress in db if current user is playlist owner
            if CurrentUser.currUser?.spotifyID == stream.owner.spotifyID {
                CurrentUser.currStream?.songs[0].progress = progress
                socketManager.updateSongPositionChanged(streamID: stream.streamID, position: progress)
            }
        }
    }
    
    private func updateSlider(song: Models.Song, progress: Double) {
        let normalizedProgress = progress / song.duration
        circularProgress.progress = normalizedProgress
        self.currTimeLabel.text = timeIntervalToString(interval: progress/1000)
    }
    
    func songFinished() {
        // pop first song, play next song
        let stream = CurrentUser.currStream!
        let params: Parameters = ["streamID": stream.streamID]
        Alamofire.request(ServerConstants.kJukeServerURL + ServerConstants.kPopSong, method: .post, parameters: params).responseJSON { response in
            switch response.result {
            case .success:
                CurrentUser.currStream!.songs.remove(at: 0)
                DispatchQueue.main.async {
                    self.loadTopSong(shouldPlay: true)
                    self.tableView.reloadData()
                    self.circularProgress.progress = 0.0
                }
                
            case .failure(let error):
                print(error)
            }
        }
    }
    
    private func loadTopSong(shouldPlay: Bool) {
        let songs = CurrentUser.currStream!.songs
        if songs.count > 0 {
            let song = songs[0]
            self.coverArtImage.af_setImage(withURL: URL(string: song.coverArtURL)!, placeholderImage: nil, filter: CircleFilter())
            self.updateSlider(song: song, progress: song.progress)
            
            if self.jamsPlayer.isPlaying(trackID: song.spotifyID) {
                listenButton.isSelected = true  // if already playing, let it play. otherwise use the shouldPlay boolean
                return
            } else {
                listenButton.isSelected = shouldPlay
            }
            
            // load song and wait for user to press play or tune in/out
            self.jamsPlayer.loadSong(trackID: song.spotifyID, progress: song.progress, shouldPlay: shouldPlay)
        } else {
            // no songs left -- reset
            
        }
    }
}
