//
//  StreamController.swift
//  Juke
//
//  Created by Conner Smith on 2/23/17.
//  Copyright © 2017 csmith. All rights reserved.
//

import UIKit
import Alamofire
import AlamofireImage
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
    var stream: Models.Stream!
    let jamsPlayer = JamsPlayer.shared
    let socketManager = SocketManager.sharedInstance
    @IBOutlet var joinStreamButton: UIButton!
    @IBOutlet var listenButton: UIButton!
    var circularProgress = KYCircularProgress()
    var animationTimer = Timer()
    
    @IBAction func joinStream(_ sender: AnyObject) {
        HUD.show(.progress)
        socketManager.joinStream(userID: CurrentUser.user.id, streamID: stream.streamID) { unparsedStream in
            do {
                let stream: Models.Stream = try unbox(dictionary: unparsedStream)
                CurrentUser.stream = stream
                HUD.flash(.success, delay: 1.0) { success in
                    self.tabBarController?.selectedIndex = 1
                }
            } catch {
                print("Error unboxing new stream: ", error)
            }
        }
    }
    
    
    @IBAction func toggleListening(_ sender: AnyObject) {
        if stream.songs.count == 0 {
            return
        }
        
        let newPlayStatus = !listenButton.isSelected
        listenButton.isSelected = newPlayStatus
        setSong(play: newPlayStatus && stream.isPlaying)
        if listenButton.isSelected {
            // disable MyStreamController audio via notification
            NotificationCenter.default.post(name: Notification.Name("handleVisitingStream"), object: nil);
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.delegate = self
        self.tableView.dataSource = self
        NotificationCenter.default.addObserver(self, selector: #selector(StreamController.songFinished), name: Notification.Name("songFinished"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(StreamController.refreshStream), name: Notification.Name("refresh"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(StreamController.syncPositionWithOwner), name: Notification.Name("syncPositionWithOwner"), object: nil)
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
        circularProgress = KYCircularProgress(frame: circularProgressFrame.bounds)
        circularProgress.startAngle =  -1 * M_PI_2
        circularProgress.endAngle = -1 * M_PI_2 + 2*M_PI
        circularProgress.lineWidth = 2.0
        circularProgress.colors = [.blue, .yellow, .red]
        circularProgressFrame.addSubview(circularProgress)
        listenButton.setImage(UIImage(named: "listening.png"), for: .normal)
        listenButton.setImage(UIImage(named: "mute.png"), for: .selected)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navBarTitle = stream.owner.username
        socketManager.visitStream(streamID: stream.streamID)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        socketManager.leaveSocketRoom(streamID: stream.streamID, visitor: true)
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
        return stream.songs.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let song = self.stream!.songs[indexPath.row]
        if indexPath.row == 0 {
            // place first song in the currentlyPlayingLabel
            coverArtImage.af_setImage(withURL: URL(string: song.coverArtURL)!, placeholderImage: nil, filter: CircleFilter())
            currentlyPlayingLabel.text = song.songName
            currentlyPlayingArtistLabel.text = song.artistName
        }
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "SongCell", for: indexPath) as! SongTableViewCell
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
    
    private func updateSlider(song: Models.Song) {
        let normalizedProgress = song.progress / song.duration
        self.circularProgress.progress = normalizedProgress
        self.circularProgress.set(progress: normalizedProgress, duration: 0.25)
        self.currTimeLabel.text = timeIntervalToString(interval: song.progress/1000)
    }
    
    public func setSong(play: Bool) {
        jamsPlayer.setPlayStatus(shouldPlay: play, song: stream.songs[0])
        setTimer(run: !play && stream.isPlaying)
    }
    
    private func setTimer(run: Bool) {
        DispatchQueue.main.async {
            if (run) {
                if !self.animationTimer.isValid {
                    self.animationTimer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(self.updateAnimationProgress), userInfo: nil, repeats: true)
                }
            } else {
                if self.animationTimer.isValid {
                    self.animationTimer.invalidate()
                }
            }
        }
    }
    
    func syncPositionWithOwner(notification: NSNotification) {
        if stream.songs.count == 0 {
            return
        }
        
        if let data = notification.object as? NSDictionary {
            if let eventString = data["event"] as? String {
                
                let songID = data["songID"] as? String
                if songID != stream.songs[0].id {
                    return // notification meant for MyStreamController
                }
                
                switch eventString {
                case "playStatusChanged":
                    let isPlaying = data["isPlaying"] as! Bool
                    stream.isPlaying = isPlaying
                    let progress = data["progress"] as! Double
                    stream.songs[0].progress = progress
                    updateSlider(song: stream!.songs[0])
                    setSong(play: isPlaying && listenButton.isSelected)
                default:
                    print("Received unrecognized ownerSongStatusChanged event: ", eventString);
                }
            }
        }
    }
    
    func updateAnimationProgress() {
        let song = stream.songs[0]
        let newProgress = song.progress + 1000
        stream.songs[0].progress = newProgress
        updateSlider(song: stream.songs[0])
        if abs(newProgress - song.duration) < 2000 {
            songFinished()  // force pop song based on timer
        }
    }
    
    func songFinished() {
        stream.songs.remove(at: 0)
        DispatchQueue.main.async {
            self.tableView.reloadData()
            self.circularProgress.progress = 0.0
            self.loadTopSong()
        }
    }
    
    func songPositionChanged(notification: NSNotification) {
        if stream.songs.count == 0 {
            return
        }
        
        let songs = stream.songs
        let song = songs[0]
        if let data = notification.object as? NSDictionary {
            let progress = data["progress"] as! Double
            let songID = data["songID"] as! String
            if songID != song.id {
                return  // notification meant for MyStreamController
            }
            stream.songs[0].progress = progress
            updateSlider(song: song)
        }
    }
    
    private func loadTopSong() {
        if stream.songs.count > 0 {
            let song = stream.songs[0]
            updateSlider(song: song)
            setSong(play: listenButton.isSelected && stream.isPlaying)
        }
    }
    
    func refreshStream(notification: NSNotification) {
        do {
            if let unparsedStream = notification.object as? UnboxableDictionary {
                let stream: Models.Stream = try unbox(dictionary: unparsedStream)
                if self.stream.streamID != stream.streamID {
                    return  // notification meant for MyStreamController
                }
                self.stream = stream
                DispatchQueue.main.async {
                    self.loadTopSong()
                    self.tableView.reloadData()
                }
            }
        } catch {
            print("error unboxing new stream: ", error)
        }
    }    
}
