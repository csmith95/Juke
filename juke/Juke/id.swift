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
    private var progressValue: Double = 0.0
    private var progressSliderValue: Double {
        get {
            return progressValue
        }
        
        set(newValue) {
//            if newValue == 0.0 {
//                self.progressValue = 0.0
//                self.currTimeLabel.text = timeIntervalToString(interval: 0.0/1000)
//                return
//            }
            
            guard let song = Current.stream.song else {
                self.progressValue = 0.0
                self.currTimeLabel.text = timeIntervalToString(interval: 0.0/1000)
                return
            }
            
            if abs(newValue - song.duration) < 1000 {
                self.songFinished()  // force pop song based on timer
            } else if abs(newValue - self.progressValue) < 1000 {
                return  // to avoid extra UI updates
            }
            else {
                let normalizedProgress = newValue / song.duration
                self.progressSlider.value = Float(normalizedProgress)
                self.currTimeLabel.text = timeIntervalToString(interval: newValue/1000)
                self.progressValue = newValue
            }
        }
    }
    
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
        let status = !listenButton.isSelected
        listenButton.isSelected = status
        Current.listenSelected = status
        refreshSongPlayStatus() // for better responsiveness
        FirebaseAPI.listenForSongProgress() // fetch real song progress to maintain sync
        if Current.isHost() {
            FirebaseAPI.setPlayStatus(status: status)
            Current.stream.isPlaying = status
        }
    }
    
    @IBAction func skipSong(_ sender: Any) {
        songFinished()
    }
    
    @IBAction func returnToPersonalStream(_ sender: Any) {
        FirebaseAPI.createNewStream(removeFromCurrentStream: true)
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
        
        // set to online if not marked online
        if !Current.user.online {
            FirebaseAPI.setOnlineTrue()
        }
        loadTopSong()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.navigationBar.titleTextAttributes = [ NSFontAttributeName: UIFont(name: "Helvetica", size: 15)!]
        if Current.isHost() {
            navBarTitle = "Your Stream"
        } else {
            navBarTitle = Current.stream.host.username + "'s Stream"
        }
        FirebaseAPI.listenForSongProgress() // will update if progress difference > 3 seconds
        if let dataSource = FirebaseAPI.addSongQueueTableViewListener(songQueueTableView: self.tableView) {
            self.dataSource = dataSource
        }
        self.setUpControlButtons()
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
        numMembersLabel.text = String(Current.stream.members.count+1)
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
        if let data = notification.object as? NSDictionary {
            let progress = data["progress"] as! Double
            self.progressSliderValue = progress
            if Current.isHost() {
                FirebaseAPI.updateSongProgress(progress: progress)
            }
        }
    }
    
    func songFinished() {
        if Current.stream.song == nil  {
            return
        }
        progressSliderValue = 0.0   // reset
        if (Current.isHost()) {
            FirebaseAPI.popTopSong(dataSource: dataSource) // this pops top song and loads next, if any
        }
    }
    
    private func refreshSongPlayStatus() {
        jamsPlayer.resync()
        handleAutomaticProgressSlider()
    }
    
    private func handleAutomaticProgressSlider() {
        if Current.isHost() {
            return  // if owner, don't use timer at all
        }
        
        if (!Current.listenSelected && Current.stream.isPlaying) {
            if !self.animationTimer.isValid {
                 // trying to offset for the time transition between stopping timer and starting song
                self.progressSliderValue = self.progressSliderValue + 300
                // set function to increment progress slider every 1 seconds
                self.animationTimer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(self.updateAnimationProgress), userInfo: nil, repeats: true)
            }
        } else {
            if self.animationTimer.isValid {
                self.animationTimer.invalidate()
            }
        }
    }
    
    @IBAction func clearStream(_ sender: Any) {
        FirebaseAPI.clearStream()
    }
    
    // fires every half second when timer is on
    func updateAnimationProgress() {
        self.progressSliderValue += 1000
    }
    
    func loadTopSong() {
        if let song = Current.stream.song {
            self.coverArtImage.af_setImage(withURL: URL(string: song.coverArtURL)!, placeholderImage: nil)
            self.bgblurimg.af_setImage(withURL: URL(string:song.coverArtURL)!, placeholderImage: nil)
            self.currentSongLabel.text = song.songName
            self.currentArtistLabel.text = song.artistName
            self.addSongButton.isHidden = false
            self.listenButton.isHidden = false
            if Current.isHost() {
                self.listenButton.isSelected = Current.stream.isPlaying
            }
            self.skipButton.isHidden = !Current.isHost()
            self.clearStreamButton.isHidden = !Current.isHost()
            self.checkIfUserLibContainsCurrentSong(song: song)
            self.refreshSongPlayStatus()
            self.noSongsLabel.isHidden = true
            progressSlider.isHidden = false
            currTimeLabel.isHidden = false
        } else {
            self.setEmptyStreamUI()
        }
        numMembersLabel.text = String(Current.stream.members.count+1) // +1 for host
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
        listenButton.isSelected = false
        Current.listenSelected = false
        skipButton.isHidden = true
        clearStreamButton.isHidden = true
        progressSlider.isHidden = true
        currTimeLabel.isHidden = true
        refreshSongPlayStatus()
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
        refreshSongPlayStatus()
    }
    
    func firebaseEventHandler(notification: NSNotification) {
        guard let event = notification.object as? FirebaseAPI.FirebaseEvent else { print("erro"); return }
        switch event {
        case .MemberJoined, .MemberLeft:
            self.numMembersLabel.text = String(Current.stream.members.count+1) // +1 for host
            break
        case .ResyncStream:
            self.progressSliderValue = jamsPlayer.position_ms
            self.loadTopSong()
            self.refreshSongPlayStatus()
            break
        case .SwitchedStreams:
            self.loadTopSong()
            self.refreshSongPlayStatus()
            
            // update queue data source
            if let newDataSource = FirebaseAPI.addSongQueueTableViewListener(songQueueTableView: self.tableView) {
                self.dataSource = newDataSource
            }
            break
        case .SetProgress:
            self.progressSliderValue = jamsPlayer.position_ms
        }
    }

}
