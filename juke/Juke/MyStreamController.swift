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
    
    @IBOutlet var clearStreamButton: UIButton!
    @IBOutlet var addSongButton: UIButton!
    @IBOutlet var currentArtistLabel: UILabel!
    @IBOutlet var currentSongLabel: UILabel!
    @IBOutlet weak var bgblurimg: UIImageView!
    @IBOutlet var coverArtImage: UIImageView!
    @IBOutlet weak var noSongsLabel: UILabel!
    @IBOutlet weak var exitStreamButton: UIButton!
    @IBOutlet weak var progressSlider: UISlider!
    @IBOutlet weak var currTimeLabel: UILabel!
    @IBOutlet weak var skipButton: UIButton!
    @IBOutlet var tableView: UITableView!
    let jamsPlayer = JamsPlayer.shared
    let socketManager = SocketManager.sharedInstance
    @IBOutlet public var listenButton: UIButton!
    var animationTimer = Timer()
    let defaultImage = CircleFilter().filter(UIImage(named: "juke_icon")!)
    
    @IBAction func addSongToLibPressed(_ sender: Any) {
    
        let path = addSongButton.isSelected ? ServerConstants.kDeleteSongByIDPath : ServerConstants.kAddSongByIDPath
        let method: HTTPMethod = addSongButton.isSelected ? .delete : .put
        let song = CurrentUser.stream.songs[0]
        let headers = [
            "Authorization": "Bearer " + CurrentUser.accessToken
        ]
        let url = URL(string: ServerConstants.kSpotifyBaseURL+path+song.spotifyID)!
        let message = addSongButton.isSelected ? "Removed from your library" : "Saved to your library!"
        self.addSongButton.isSelected = !self.addSongButton.isSelected
        Alamofire.request(url, method: method, headers: headers).validate().response() { response in
            self.delay(1.0) {
                HUD.flash(.label(message), delay: 0.75)
            }
        }
    }
    
    func delay(_ delay: Double, closure:@escaping () -> Void) {
        DispatchQueue.main.asyncAfter(
            deadline: DispatchTime.now() + Double(Int64(delay * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC), execute: closure)
    }
    
    @IBAction func toggleListening(_ sender: AnyObject) {
        if CurrentUser.stream.songs.count == 0 {
            return
        }
        let status = !listenButton.isSelected
        listenButton.isSelected = status
        let song = CurrentUser.stream.songs[0]
        if CurrentUser.isHost() {
            socketManager.songPlayStatusChanged(streamID: CurrentUser.stream.streamID, songID: song.id, progress: song.progress, isPlaying: status)
            CurrentUser.stream.isPlaying = status
        }
        setSong(play: status && CurrentUser.stream.isPlaying)
    }
    
    @IBAction func skipSong(_ sender: Any) {
        //set song to next thing in stream
        if CurrentUser.stream.songs.count == 0 {
            return
        }
        songFinished()
    }
    
    @IBAction func returnToPersonalStream(_ sender: Any) {
        socketManager.splitFromStream(userID: CurrentUser.user.id);
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.delegate = self
        self.tableView.dataSource = self
        NotificationCenter.default.addObserver(self, selector: #selector(MyStreamController.songFinished), name: Notification.Name("songFinished"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(MyStreamController.songPositionChanged), name: Notification.Name("songPositionChanged"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(MyStreamController.syncPositionWithOwner), name: Notification.Name("syncPositionWithOwner"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(MyStreamController.fetchMyStream), name: Notification.Name("refreshStream"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(MyStreamController.jamsPlayerReady), name: Notification.Name("jamsPlayerReady"), object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.navigationBar.titleTextAttributes = [ NSFontAttributeName: UIFont(name: "Helvetica", size: 15)!]
        if !CurrentUser.fetched {
            setEmptyStreamUI()
        }
        fetchMyStream()
    }
    
    private func setUpControlButtons() {
        if CurrentUser.isHost() {
            // controls for the owner
            listenButton.setImage(UIImage(named: "ic_play_arrow_white_48pt.png"), for: .normal)
            listenButton.setImage(UIImage(named: "ic_pause_white_48pt.png"), for: .selected)
            skipButton.isHidden = false
            exitStreamButton.isHidden = true
            listenButton.isSelected = CurrentUser.stream.isPlaying
        } else {
            listenButton.setImage(UIImage(named: "listening.png"), for: .normal)
            listenButton.setImage(UIImage(named: "mute.png"), for: .selected)
            skipButton.isHidden = true
            exitStreamButton.isHidden = false
        }
    }
    
    func fetchMyStream() {
        // fetch stream for user. if not tuned in or is returning to personal stream, creates and returns an offline stream by default
        let url = ServerConstants.kJukeServerURL + ServerConstants.kFetchStream
        let params: Parameters = ["ownerSpotifyID": CurrentUser.user.spotifyID]
        Alamofire.request(url, method: .get, parameters: params).validate().responseJSON { response in
            switch response.result {
            case .success:
                do {
                    let unparsedStream = response.result.value as! UnboxableDictionary
                    let stream: Models.Stream = try unbox(dictionary: unparsedStream)
                    CurrentUser.stream = stream
                    if let owner = stream.owner.username {
                        self.navBarTitle = owner + "'s Stream"
                    } else {
                        self.navBarTitle = "Current Stream"
                    }
                    CurrentUser.user.tunedInto = stream.streamID
                    CurrentUser.fetched = true
                    self.setUpControlButtons()
                    self.tableView.reloadData()
                    if stream.songs.count > 0 {
                        self.noSongsLabel.isHidden = true
                        if !JamsPlayer.shared.isPlaying(song: stream.songs[0]) {
                            self.loadTopSong()  // otherwise sounds choppy if playback progress is adjusted every time page is loaded
                        }
                    } else {
                        // no songs in stream so show noSongsLabel
                        self.setEmptyStreamUI()
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
                    return
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
                return
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
        progressSlider.value = Float(normalizedProgress)
        self.currTimeLabel.text = timeIntervalToString(interval: song.progress/1000)
    }
    
    func songFinished() {
        CurrentUser.stream.songs.remove(at: 0)
        DispatchQueue.main.async {
            self.tableView.reloadData()
            self.loadTopSong()
        }
        
        if !CurrentUser.isHost() {
            return; // if you are not the owner, don't post to DB. let owner's device manage DB
        }
        
        socketManager.popSong(data: [CurrentUser.stream.streamID])
    }
    
    public func setSong(play: Bool) {
        if CurrentUser.fetched == false {
            return;
        }
        
        let song: Models.Song? = CurrentUser.stream.songs.count > 0 ? CurrentUser.stream.songs[0] : nil
        jamsPlayer.setPlayStatus(shouldPlay: play, song: song)
        if !CurrentUser.isHost() {
            setTimer(run: !play && CurrentUser.stream.isPlaying)
        }
    }
    
    private func setTimer(run: Bool) {
        
        DispatchQueue.main.async {
            if (CurrentUser.isHost() || CurrentUser.stream.songs.count == 0) {
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
        if CurrentUser.stream.songs.count == 0 {
            progressSlider.value = Float(0)
            return
        }
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
            coverArtImage.af_setImage(withURL: URL(string: song.coverArtURL)!, placeholderImage: nil)
            bgblurimg.af_setImage(withURL: URL(string:song.coverArtURL)!, placeholderImage: nil)
            currentSongLabel.text = song.songName
            currentArtistLabel.text = song.artistName
            addSongButton.isHidden = false
            listenButton.isHidden = false
            skipButton.isHidden = !CurrentUser.isHost()
            clearStreamButton.isHidden = !CurrentUser.isHost()
            checkIfUserLibContainsCurrentSong(song: song)
            updateSlider(song: song)
            setSong(play: listenButton.isSelected && CurrentUser.stream.isPlaying)
        } else {
            setEmptyStreamUI()
        }
    }
    
    private func setEmptyStreamUI() {
        self.noSongsLabel.isHidden = false
        coverArtImage.image = #imageLiteral(resourceName: "jukedef")
        bgblurimg.image = #imageLiteral(resourceName: "jukedef")
        currentSongLabel.text = ""
        currentArtistLabel.text = ""
        addSongButton.isHidden = true
        progressSlider.value = 0.0
        listenButton.isHidden = true
        skipButton.isHidden = true
        clearStreamButton.isHidden = true
        setSong(play: false)
    }
    
    func checkIfUserLibContainsCurrentSong(song: Models.Song) {
        let headers = [
            "Authorization": "Bearer " + CurrentUser.accessToken
        ]
        let url = URL(string: ServerConstants.kSpotifyBaseURL+ServerConstants.kContainsSongPath+song.spotifyID)!
        Alamofire.request(url, method: .get, headers: headers)
            .validate().responseJSON { response in
                switch response.result {
                    case .success:
                        let array = response.value as! [Bool]
                        let containsSong = array[0]
                        self.addSongButton.isSelected = containsSong
                    case .failure(let error):
                        print("error checking if song is already in lib: ", error)
                }
        }
    }
    
    func jamsPlayerReady() {
        setSong(play: listenButton.isSelected && CurrentUser.stream.isPlaying)
    }
    
    @IBAction func clearStreamButtonPressed(_ sender: Any) {
        socketManager.clearStream()
    }
}
