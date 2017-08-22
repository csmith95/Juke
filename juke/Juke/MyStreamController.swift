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
import Firebase
import FirebaseDatabaseUI

class MyStreamController: UIViewController, UITableViewDelegate {
    
    // firebase vars
    var dataSource: FUITableViewDataSource!
    
    // app vars
    @IBOutlet var numMembersLabel: UILabel!
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
    @IBOutlet public var listenButton: UIButton!
    var animationTimer = Timer()
    
    var navBarTitle: String? {
        get {
            return self.navigationItem.title
        }
        set (newValue) {
            self.navigationItem.title = newValue
        }
    }
    
    @IBAction func addSongToLibPressed(_ sender: Any) {
        let path = addSongButton.isSelected ? ServerConstants.kDeleteSongByIDPath : ServerConstants.kAddSongByIDPath
        let method: HTTPMethod = addSongButton.isSelected ? .delete : .put
        if let song = Current.stream.song {
            let headers = [
                "Authorization": "Bearer " + Current.accessToken
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
    }
    
    func delay(_ delay: Double, closure:@escaping () -> Void) {
        DispatchQueue.main.asyncAfter(
            deadline: DispatchTime.now() + Double(Int64(delay * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC), execute: closure)
    }
    
    @IBAction func toggleListening(_ sender: AnyObject) {
        print("called toggleListening")
        if Current.stream.song == nil {
            return
        }
        let status = !listenButton.isSelected
        listenButton.isSelected = status
        if Current.isHost() {
            FirebaseAPI.setPlayStatus(status: status)
            Current.stream.isPlaying = status
        }
        setSong(play: status && Current.stream.isPlaying)
    }
    
    @IBAction func skipSong(_ sender: Any) {
        songFinished()
    }
    
    @IBAction func returnToPersonalStream(_ sender: Any) {
        FirebaseAPI.createNewStream()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.delegate = self
        // first 2 respond to spotify events
        NotificationCenter.default.addObserver(self, selector: #selector(MyStreamController.songFinished), name: Notification.Name("songFinished"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(MyStreamController.songPositionChanged), name: Notification.Name("songPositionChanged"), object: nil)
        
        // when audio streamer logs in, respond by trying to load top song
        NotificationCenter.default.addObserver(self, selector: #selector(MyStreamController.jamsPlayerReady), name: Notification.Name("jamsPlayerReady"), object: nil)
        
        // resyncing
        NotificationCenter.default.addObserver(self, selector: #selector(MyStreamController.firebaseEventHandler), name: Notification.Name("firebaseEvent"), object: nil)
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.navigationBar.titleTextAttributes = [ NSFontAttributeName: UIFont(name: "Helvetica", size: 15)!]
        FirebaseAPI.listenForSongProgress()
        if let dataSource = FirebaseAPI.addSongQueueTableViewListener(songQueueTableView: self.tableView) {
            self.dataSource = dataSource
        }
    }
    
    
    private func setUpControlButtons() {
        if Current.isHost() {
            // controls for the owner
            listenButton.setImage(UIImage(named: "ic_play_arrow_white_48pt.png"), for: .normal)
            listenButton.setImage(UIImage(named: "ic_pause_white_48pt.png"), for: .selected)
            skipButton.isHidden = false
            exitStreamButton.isHidden = true
            listenButton.isSelected = Current.stream.isPlaying
        } else {
            listenButton.setImage(UIImage(named: "listening.png"), for: .normal)
            listenButton.setImage(UIImage(named: "mute.png"), for: .selected)
            skipButton.isHidden = true
            exitStreamButton.isHidden = false
        }
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    private func timeIntervalToString(interval: TimeInterval) -> String {
        let ti = NSInteger(interval)
        let seconds = ti % 60
        let minutes = (ti / 60) % 60
        return NSString(format: "%0.2d:%0.2d", minutes, seconds) as String
    }
    
    func songPositionChanged(notification: NSNotification) {
        if let song = Current.stream.song, let data = notification.object as? NSDictionary {
            let progress = data["progress"] as! Double
            jamsPlayer.position_ms = progress
            if Current.isHost() {
                FirebaseAPI.updateSongProgress()
            }
            updateSlider(song: song)
        }
    }
    
    private func updateSlider(song: Models.FirebaseSong?) {
        guard let song = song else {
            progressSlider.value = Float(0.0)
            self.currTimeLabel.text = timeIntervalToString(interval: 0.0/1000)
            return
        }
        let normalizedProgress = jamsPlayer.position_ms / song.duration
        progressSlider.value = Float(normalizedProgress)
        self.currTimeLabel.text = timeIntervalToString(interval: jamsPlayer.position_ms/1000)
    }
    
    func songFinished() {
        if Current.stream.song == nil  {
            return
        }
        if (Current.isHost()) {
            FirebaseAPI.popTopSong(dataSource: dataSource) // this pops top song and loads next, if any
        }
    }
    
    public func setSong(play: Bool) {
        jamsPlayer.setPlayStatus(shouldPlay: play, topSong: Current.stream.song)
        if !Current.isHost() {
            setTimer(run: !play && Current.stream.isPlaying)
        }
    }
    
    private func setTimer(run: Bool) {
        
        DispatchQueue.main.async {
            if (Current.isHost() || Current.stream.song == nil) {
                return  // if owner, don't use timer at all
            }
            
            if (run) {
                if !self.animationTimer.isValid {
                    self.jamsPlayer.position_ms += 300 // trying to offset for the time transition between stopping timer and starting song
                    self.animationTimer = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(self.updateAnimationProgress), userInfo: nil, repeats: true)
                }
            } else {
                if self.animationTimer.isValid {
                    self.jamsPlayer.position_ms += 300 // trying to offset for the time transition between stopping timer and starting song
                    self.animationTimer.invalidate()
                }
            }
        }
    }
    
    @IBAction func clearStream(_ sender: Any) {
        FirebaseAPI.clearStream()
    }

    func updateAnimationProgress() {
        if let song = Current.stream.song {
            let newProgress = jamsPlayer.position_ms + 500
            updateSlider(song: song)
            if abs(newProgress - song.duration) < 1000 {
                songFinished()  // force pop song based on timer
            }
        } else {
            progressSlider.value = Float(0)
        }
    }
    
    func loadTopSong() {
        if let song = Current.stream.song {
            print("Load top song: ", song)
            self.coverArtImage.af_setImage(withURL: URL(string: song.coverArtURL)!, placeholderImage: nil)
            self.bgblurimg.af_setImage(withURL: URL(string:song.coverArtURL)!, placeholderImage: nil)
            self.currentSongLabel.text = song.songName
            self.currentArtistLabel.text = song.artistName
            self.addSongButton.isHidden = false
            self.listenButton.isHidden = false
            self.listenButton.isSelected = Current.stream.isPlaying
            self.skipButton.isHidden = !Current.isHost()
            self.clearStreamButton.isHidden = !Current.isHost()
            self.checkIfUserLibContainsCurrentSong(song: song)
            self.updateSlider(song: song)
            self.setSong(play: self.listenButton.isSelected && Current.stream.isPlaying)
            self.noSongsLabel.isHidden = true
        } else {
            self.setEmptyStreamUI()
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
    
    func checkIfUserLibContainsCurrentSong(song: Models.FirebaseSong) {
        let headers = [
            "Authorization": "Bearer " + Current.accessToken
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
        setSong(play: listenButton.isSelected && Current.stream.isPlaying)
    }
    
    func firebaseEventHandler(notification: NSNotification) {
        guard let event = notification.object as? FirebaseAPI.FirebaseEvent else { print("erro"); return }
        switch event {
        case .MemberJoined, .MemberLeft:
            self.numMembersLabel.text = String(Current.stream.members.count)
            break
        case .ResyncStream:
            print("fired resync")
            self.loadTopSong()
            self.jamsPlayer.resync()
            break
            
        case .SwitchedStreams:
            print("fired switched")
            self.loadTopSong()
            self.jamsPlayer.resync()
            
            // update queue data source
            if let newDataSource = FirebaseAPI.addSongQueueTableViewListener(songQueueTableView: self.tableView) {
                self.dataSource = newDataSource
            }
            break
        case .SetProgress:
            self.updateSlider(song: Current.stream.song)
        }
    }

}
