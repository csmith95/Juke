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
import PKHUD

class StreamController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    var navBarTitle: String? {
        get {
            return self.navigationItem.title
        }
        set (newValue) {
            self.navigationItem.title = newValue
        }
    }
    
    @IBOutlet var circularProgressFrame: UIView!
    @IBOutlet var coverArtImage: UIImageView!
    @IBOutlet var barButton: UIBarButtonItem!
    @IBOutlet var currTimeLabel: UILabel!
    @IBOutlet var currentlyPlayingArtistLabel: UILabel!
    @IBOutlet var currentlyPlayingLabel: UILabel!
    @IBOutlet var currentlyPlayingView: UIView!
    @IBOutlet var tableView: UITableView!
    var stream: Models.Stream?
    let jamsPlayer = JamsPlayer.shared
    let socketManager = SocketManager.sharedInstance
    @IBOutlet var joinStreamButton: UIButton!
    @IBOutlet var listenButton: UIButton!
    var circularProgress = KYCircularProgress()
    
    @IBAction func joinStream(_ sender: AnyObject) {
        HUD.show(.progress)
        socketManager.joinStream(userID: CurrentUser.currUser!.id, streamID: stream!.streamID) { unparsedStream in
            do {
                let stream: Models.Stream = try unbox(dictionary: unparsedStream)
                CurrentUser.currStream = stream
                print("Joined stream: ", stream)
                HUD.flash(.success, delay: 1.0) { success in
                    self.tabBarController?.selectedIndex = 1
                }
            } catch {
                print("Error unboxing new stream: ", error)
            }
        }
    }
    
    
    @IBAction func toggleListening(_ sender: AnyObject) {
        if self.stream!.songs.count == 0 {
            return
        }
        
        let song = self.stream!.songs[0]
        let newPlayStatus = !listenButton.isSelected
        listenButton.isSelected = newPlayStatus
        jamsPlayer.setPlayStatus(shouldPlay: newPlayStatus, trackID: song.spotifyID, position: song.progress)
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
        listenButton.setImage(UIImage(named: "listening.png"), for: .normal)
        listenButton.setImage(UIImage(named: "mute.png"), for: .selected)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navBarTitle = stream?.owner.username
        let songs = self.stream!.songs
        if songs.count > 0 {
            coverArtImage.image = songs[0].coverArt!.af_imageRoundedIntoCircle()
            circularProgress = KYCircularProgress(frame: circularProgressFrame.bounds)
            circularProgress.startAngle =  -1 * M_PI_2
            circularProgress.endAngle = -1 * M_PI_2 + 2*M_PI
            circularProgress.lineWidth = 2.0
            circularProgress.colors = [.blue, .yellow, .red]
            circularProgressFrame.addSubview(circularProgress)
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
        return self.stream!.songs.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let song = self.stream!.songs[indexPath.row]
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
        if self.stream!.songs.count == 0 {
            return
        }
        
        let song = self.stream!.songs[0]
        if let data = notification.object as? NSDictionary {
            // update slider
            let progress = data["position"] as! Double
            updateSlider(song: song, progress: progress)
        }
    }
    
    private func updateSlider(song: Models.Song, progress: Double) {
        let normalizedProgress = progress / song.duration
        circularProgress.progress = normalizedProgress
        self.currTimeLabel.text = timeIntervalToString(interval: progress/1000)
    }
    
    func songFinished() {
        // pop first song, play next song
        let params: Parameters = ["streamID": stream?.streamID as String!]
        Alamofire.request(ServerConstants.kJukeServerURL + ServerConstants.kPopSong, method: .post, parameters: params).responseJSON { response in
            switch response.result {
            case .success:
                self.stream?.songs.remove(at: 0)    // instead of unboxing entire stream, for now just pop first song
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
                self.loadTopSong(shouldPlay: true)
            case .failure(let error):
                print(error)
            }
        }
    }
    
    private func loadTopSong(shouldPlay: Bool) {
        if self.stream!.songs.count > 0 {
            let song = self.stream!.songs[0]
            self.updateSlider(song: song, progress: song.progress)
            
            if self.jamsPlayer.isPlaying(trackID: song.spotifyID) {
                listenButton.isSelected = true
                return  // if already playing, let it play
            }
            
            DispatchQueue.global(qos: .background).async {
                // load song and wait for user to press play or tune in/out
                self.jamsPlayer.loadSong(trackID: song.spotifyID, progress: song.progress, shouldPlay: shouldPlay)
            }
        }
    }
}
