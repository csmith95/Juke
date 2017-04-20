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
import PKHUD

class MyStreamController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    var navBarTitle: String? {
        get {
            return self.navigationItem.title
        }
        set (newValue) {
            self.navigationItem.title = newValue
        }
    }
    
    @IBOutlet var currentlyPlayingImageView: UIImageView!
    @IBOutlet var splitButton: UIButton!
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
    @IBOutlet public var listenButton: UIButton!
    var circularProgress = KYCircularProgress()
    var animationTimer = Timer()
    let defaultImage = CircleFilter().filter(UIImage(named: "juke_icon")!)
    
    @IBAction func toggleListening(_ sender: AnyObject) {
        let newPlayStatus = !listenButton.isSelected
        setListeningStatus(status: newPlayStatus)
    }
    
    func handleVisitingStream(notification: NSNotification) {
        setListeningStatus(status: false)
    }
    
    private func setListeningStatus(status: Bool) {
        if CurrentUser.stream.songs.count == 0 {
            return
        }
        let song = CurrentUser.stream.songs[0]
        listenButton.isSelected = status
        if CurrentUser.isHost() {
            socketManager.songPlayStatusChanged(streamID: CurrentUser.stream.streamID, songID: song.id, progress: song.progress, isPlaying: status)
            CurrentUser.stream.isPlaying = status
        }
        
        setSong(play: status && CurrentUser.stream.isPlaying)
    }
    
    @IBAction func toggleOnlineStatus(_ sender: AnyObject) {
        let newOnlineStatus = !onlineButton.isSelected
        onlineButton.isSelected = newOnlineStatus
        let url = ServerConstants.kJukeServerURL + ServerConstants.kChangeOnlineStatus
        let params: Parameters = ["streamID": CurrentUser.stream.streamID, "isLive": newOnlineStatus]
        Alamofire.request(url, method: .post, parameters: params).validate().responseJSON { response in
            switch response.result {
            case .success:
                do {
                    let unparsedStream = response.result.value as! UnboxableDictionary
                    let stream: Models.Stream = try unbox(dictionary: unparsedStream)
                    CurrentUser.stream = stream
                } catch {
                    print("error unboxing new stream after changing online status: ", error)
                }
            case .failure(let error):
                print("error changing live status: ", error)
            }
        }
    }
   
    @IBAction func splitButtonPressed(_ sender: AnyObject) {
        socketManager.splitFromStream(userID: CurrentUser.user.id);
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.delegate = self
        self.tableView.dataSource = self
        NotificationCenter.default.addObserver(self, selector: #selector(MyStreamController.songFinished), name: Notification.Name("songFinished"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(MyStreamController.songPositionChanged), name: Notification.Name("songPositionChanged"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(MyStreamController.syncPositionWithOwner), name: Notification.Name("syncPositionWithOwner"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(MyStreamController.refreshStream), name: Notification.Name("refreshMyStream"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(MyStreamController.handleVisitingStream), name: Notification.Name("handleVisitingStream"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(MyStreamController.jamsPlayerReady), name: Notification.Name("jamsPlayerReady"), object: nil)
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
        fetchMyStream()
    }
    
    private func setUpControlButtons() {
        if CurrentUser.isHost() {
            // controls for the owner
            listenButton.setImage(UIImage(named: "play.png"), for: .normal)
            listenButton.setImage(UIImage(named: "pause.png"), for: .selected)
            // only let host toggle online/offline
            onlineButton.setImage(UIImage(named: "online.png"), for: .normal)
            onlineButton.setImage(UIImage(named: "offline.png"), for: .selected)
            onlineButton.isSelected = CurrentUser.stream.isLive
            // allow host to split if more than 1 member
            splitButton.isHidden = (CurrentUser.stream.members.count == 1)
            // **** TODO: allow host to clear or skip songs ****
        } else {
            splitButton.isHidden = false
            listenButton.setImage(UIImage(named: "listening.png"), for: .normal)
            listenButton.setImage(UIImage(named: "mute.png"), for: .selected)
        }
        onlineButton.isHidden = !CurrentUser.isHost()
        listenButton.isSelected = CurrentUser.stream.isPlaying
    }
    
    func refreshStream(notification: NSNotification) {
        print("my stream controller received refreshStream")
        fetchMyStream()
    }
    
    private func fetchMyStream() {
        // fetch stream for user. if not tuned in, creates and returns an offline stream by default
        let url = ServerConstants.kJukeServerURL + ServerConstants.kFetchStream
        let params: Parameters = ["ownerSpotifyID": CurrentUser.user.spotifyID]
        Alamofire.request(url, method: .get, parameters: params).validate().responseJSON { response in
            switch response.result {
            case .success:
                do {
                    let unparsedStream = response.result.value as! UnboxableDictionary
                    let stream: Models.Stream = try unbox(dictionary: unparsedStream)
                    CurrentUser.stream = stream
                    CurrentUser.user.tunedInto = stream.streamID
                    CurrentUser.fetched = true
                    self.setUpControlButtons()
                    self.tableView.reloadData()
                    if stream.songs.count > 0 {
                        if !JamsPlayer.shared.isPlaying(song: stream.songs[0]) {
                            self.loadTopSong()  // otherwise sounds choppy if playback progress is adjusted every time page is loaded
                        }
                    }
                    self.socketManager.joinSocketRoom(streamID: CurrentUser.stream.streamID)
                } catch {
                    print("Error unboxing stream: ", error)
                }
                
            case .failure(let error):
                print("Error fetching stream: ", error)
            }
        }
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50
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
        if (CurrentUser.fetched == false) {
            return 0
        }
        return CurrentUser.stream.songs.count-1     // -1 because the first one is loaded up top
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let song = CurrentUser.stream.songs[indexPath.row+1]
        let cell = self.tableView.dequeueReusableCell(withIdentifier: "SongCell", for: indexPath) as! SongTableViewCell
        cell.songName.text = song.songName
        cell.artist.text = song.artistName
        let imageFilter = CircleFilter()
        if let unwrappedUrl = song.memberImageURL {
            cell.memberImageView.af_setImage(withURL: URL(string: unwrappedUrl)!, placeholderImage: defaultImage, filter: imageFilter)
        } else {
            cell.memberImageView.image = imageFilter.filter(defaultImage)
        }
        return cell
    }
    
    private func timeIntervalToString(interval: TimeInterval) -> String {
        let ti = NSInteger(interval)
        let seconds = ti % 60
        let minutes = (ti / 60) % 60
        return NSString(format: "%0.2d:%0.2d", minutes, seconds) as String
    }
    
    func syncPositionWithOwner(notification: NSNotification) {
        if CurrentUser.stream.songs.count == 0 {
            return
        }
        
        if CurrentUser.isHost() {
            return  // owner is already synced with device
        }
        
        if let data = notification.object as? NSDictionary {
            if let eventString = data["event"] as? String {
                
                let songID = data["songID"] as? String
                if songID != CurrentUser.stream.songs[0].id {
                    return // notification meant for a visited StreamController
                }
                
                switch eventString {
                case "playStatusChanged":
                    let isPlaying = data["isPlaying"] as! Bool
                    CurrentUser.stream.isPlaying = isPlaying
                    let progress = data["progress"] as! Double
                    CurrentUser.stream.songs[0].progress = progress
                    updateSlider(song: CurrentUser.stream.songs[0])
                    setSong(play: isPlaying && listenButton.isSelected)
                default:
                    print("Received unrecognized ownerSongStatusChanged event: ", eventString);
                }
            }
        }
    }
    
    func songPositionChanged(notification: NSNotification) {
        if CurrentUser.stream.songs.count == 0 {
            return
        }
        
        let songs = CurrentUser.stream.songs
        let song = songs[0]
        if let data = notification.object as? NSDictionary {
            let songID = data["songID"] as! String
            if songID != song.id {
                return  // notification meant for a visited StreamController
            }
            let progress = data["progress"] as! Double
            CurrentUser.stream.songs[0].progress = progress
            // update progress in db if current user is playlist owner
            if CurrentUser.isHost() {
                socketManager.songPositionChanged(songID: song.id, position: progress)
            }
            
            // update slider
            updateSlider(song: song)
        }
    }
    
    private func updateSlider(song: Models.Song) {
        let normalizedProgress = song.progress / song.duration
        self.circularProgress.progress = normalizedProgress
        self.circularProgress.set(progress: normalizedProgress, duration: 0.5)
        self.currTimeLabel.text = timeIntervalToString(interval: song.progress/1000)
    }
    
    func songFinished() {
        print("received pop")
        CurrentUser.stream.songs.remove(at: 0)
        DispatchQueue.main.async {
            self.tableView.reloadData()
            self.circularProgress.progress = 0.0
            self.loadTopSong()
        }
        
        if !CurrentUser.isHost() {
            return; // if you are not the owner, don't post to DB. let owner's device manage DB
        }
        
        let stream = CurrentUser.stream!
        let params: Parameters = ["streamID": stream.streamID]
        Alamofire.request(ServerConstants.kJukeServerURL + ServerConstants.kPopSong, method: .post, parameters: params).responseJSON { response in
            switch response.result {
            case .success:
                print("Popped finished song from DB")
            case .failure(let error):
                print(error)
            }
        }
    }
    
    public func setSong(play: Bool) {
        if CurrentUser.fetched == false || CurrentUser.stream?.songs.count == 0 {
            return;
        }
        
        self.jamsPlayer.setPlayStatus(shouldPlay: play, song: CurrentUser.stream.songs[0])
        if CurrentUser.user.spotifyID != CurrentUser.stream.owner.spotifyID {
            setTimer(run: !play && CurrentUser.stream.isPlaying)
        }
    }
    
    private func setTimer(run: Bool) {
        
        DispatchQueue.main.async {
            if CurrentUser.isHost() {
                return  // if owner, don't use timer at all
            }
            
            if (run) {
                if !self.animationTimer.isValid {
                    CurrentUser.stream.songs[0].progress += 300 // trying to offset for the time transition between stopping timer and starting song
                    self.animationTimer = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(self.updateAnimationProgress), userInfo: nil, repeats: true)
                }
            } else {
                if self.animationTimer.isValid {
                    CurrentUser.stream.songs[0].progress += 300 // trying to offset for the time transition between stopping timer and starting song
                    self.animationTimer.invalidate()
                }
            }
        }
    }
    
    func updateAnimationProgress() {
        let song = CurrentUser.stream.songs[0]
        let newProgress = song.progress + 500
        CurrentUser.stream.songs[0].progress = newProgress
        updateSlider(song: CurrentUser.stream.songs[0])
        if abs(newProgress - song.duration) < 1000 {
            songFinished()  // force pop song based on timer
        }
    }
    
    private func loadTopSong() {
        let songs = CurrentUser.stream.songs
        if songs.count > 0 {
            let song = songs[0]
            // place first song in the currentlyPlayingLabel
            coverArtImage.af_setImage(withURL: URL(string: song.coverArtURL)!, placeholderImage: nil, filter: CircleFilter())
            self.currentlyPlayingLabel.text = song.songName
            self.currentlyPlayingArtistLabel.text = song.artistName
            
            // set up background
            currentlyPlayingImageView.af_setImage(withURL: URL(string: song.coverArtURL)!, placeholderImage: nil, filter: BlurFilter()) { response in
                self.currentlyPlayingImageView.alpha = 0.6
                if let image = response.result.value {
                    self.currentlyPlayingImageView.image = RoundedCornersFilter(radius: 20.0).filter(image)
                }
            }
            
            updateSlider(song: song)
            setSong(play: listenButton.isSelected && CurrentUser.stream.isPlaying)
        } else {
            // **** TODO: no songs left -- display custom UI ****
            
        }
    }
    
    func jamsPlayerReady() {
        setSong(play: listenButton.isSelected && CurrentUser.stream.isPlaying)
    }
}
