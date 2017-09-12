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
import XLActionController

class MyStreamController: UITableViewController {
    
    // firebase vars
    let songsDataSource = SongQueueDataSource()
    
    @IBOutlet var numContributorsButton: UIButton!
    var streamName = ""
    @IBOutlet var streamNameLabel: UILabel!
    @IBOutlet var hostLabel: UILabel!
    @IBOutlet var currentArtistLabel: UILabel!
    @IBOutlet var currentSongLabel: UILabel!
    @IBOutlet weak var bgblurimg: UIImageView!
    @IBOutlet var coverArtImage: UIImageView!
    @IBOutlet weak var progressSlider: UISlider!
    @IBOutlet weak var currTimeLabel: UILabel!
    let jamsPlayer = JamsPlayer.shared
    @IBOutlet public var listenButton: UIButton!
    var animationTimer = Timer()
    private var progressValue: Double = 0.0
    private var progressSliderValue: Double {
        get {
            return progressValue
        }
        
        set(newValue) {            
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
//        let path = addSongButton.isSelected ? ServerConstants.kDeleteSongByIDPath : ServerConstants.kAddSongByIDPath
//        let method: HTTPMethod = addSongButton.isSelected ? .delete : .put
//        if let song = Current.stream.song {
//            let headers = [
//                "Authorization": "Bearer " + Current.accessToken
//            ]
//            let url = URL(string: ServerConstants.kSpotifyBaseURL+path+song.spotifyID)!
//            let message = addSongButton.isSelected ? "Removed from your library" : "Saved to your library!"
//            self.addSongButton.isSelected = !self.addSongButton.isSelected
//            Alamofire.request(url, method: method, headers: headers).validate().responseData() { response in
//                switch response.result {
//                case .success:
//                    // tell search table view controller to update lib
//                    NotificationCenter.default.post(name: Notification.Name("libraryChanged"), object: song)
//                    self.delay(0.5) {
//                        HUD.flash(.label(message), delay: 0.75)
//                    }
//                    break
//                case .failure(let error):
//                    print("Error saving to spotify lib: ", error)
//                    self.delay(0.5) {
//                        HUD.flash(.label("Failed to save to your library"), delay: 0.75)
//                    }
//                }
//            }
//        }
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = songsDataSource
        tableView.dataSource = songsDataSource
        // first 2 respond to spotify events
        NotificationCenter.default.addObserver(self, selector: #selector(MyStreamController.songFinished), name: Notification.Name("songFinished"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(MyStreamController.songPositionChanged), name: Notification.Name("songPositionChanged"), object: nil)
        
        // when audio streamer logs in, respond by trying to load top song
        NotificationCenter.default.addObserver(self, selector: #selector(MyStreamController.jamsPlayerReady), name: Notification.Name("jamsPlayerReady"), object: nil)
        
        // resyncing
        NotificationCenter.default.addObserver(self, selector: #selector(MyStreamController.firebaseEventHandler), name: Notification.Name("firebaseEvent"), object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(MyStreamController.reloadSongs), name: Notification.Name("reloadSongs"), object: nil)
        
        progressSlider.setThumbImage(UIImage(named: "slider_thumb.png"), for: .normal)

        
        // set to online if not marked online
        
//        if !Current.user.online {
//            
//        }
    }
    
    func reloadSongs() {
        DispatchQueue.main.async {
            objc_sync_enter(self.tableView.dataSource)
            self.tableView.reloadData()
            objc_sync_exit(self.tableView.dataSource)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.navigationBar.titleTextAttributes = [ NSFontAttributeName: UIFont(name: "Helvetica", size: 15)!]
        streamNameLabel.text = streamName
        FirebaseAPI.listenForSongProgress() // will update if progress difference > 3 seconds
        songsDataSource.setObservedStream()
        self.setUpControlButtons()
        FirebaseAPI.setOnlineTrue()
        FirebaseAPI.setfcmtoken()
        print("USER ONLINE", Current.user.online)
        numContributorsButton.setTitle("\(Current.stream.members.count+1) contributors", for: .normal)
        loadTopSong()
        reloadSongs()
    }
    
    
    private func setUpControlButtons() {
        if Current.isHost() {
            // controls for the owner
            listenButton.setImage(UIImage(named: "ic_play_arrow_white_48pt.png"), for: .normal)
            listenButton.setImage(UIImage(named: "ic_pause_white_48pt.png"), for: .selected)
            listenButton.isSelected = Current.stream.isPlaying
        } else {
            listenButton.setImage(UIImage(named: "listening.png"), for: .normal)
            listenButton.setImage(UIImage(named: "mute.png"), for: .selected)
        }
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
        progressSliderValue = 0.0   // reset
        if (Current.isHost()) {
            FirebaseAPI.popTopSong(dataSource: songsDataSource) // this pops top song and loads next, if any
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
            self.coverArtImage.isHidden = false
            self.bgblurimg.af_setImage(withURL: URL(string:song.coverArtURL)!, placeholderImage: nil)
            self.currentSongLabel.text = song.songName
            self.currentArtistLabel.text = song.artistName
            self.listenButton.isHidden = false
            if Current.isHost() {
                self.listenButton.isSelected = Current.stream.isPlaying
            }
            self.checkIfUserLibContainsCurrentSong(song: song)
//            self.noSongsLabel.isHidden = true
            progressSlider.isHidden = false
            currTimeLabel.isHidden = false
        } else {
            self.setEmptyStreamUI()
        }
    }
    
    private func setEmptyStreamUI() {
//        self.noSongsLabel.isHidden = false
        coverArtImage.isHidden = true
        bgblurimg.image = #imageLiteral(resourceName: "jukedef")
        currentSongLabel.text = ""
        currentArtistLabel.text = ""
        progressSlider.value = 0.0
        listenButton.isHidden = true
        listenButton.isSelected = false
        Current.listenSelected = false
        progressSlider.isHidden = true
        currTimeLabel.isHidden = true
        refreshSongPlayStatus()
    }
    
    func checkIfUserLibContainsCurrentSong(song: Models.FirebaseSong) {
//        let headers = [
//            "Authorization": "Bearer " + Current.accessToken
//        ]
//        let url = URL(string: ServerConstants.kSpotifyBaseURL+ServerConstants.kContainsSongPath+song.spotifyID)!
//        Alamofire.request(url, method: .get, headers: headers)
//            .validate().responseJSON { response in
//                switch response.result {
//                    case .success:
//                        let array = response.value as! [Bool]
//                        let containsSong = array[0]
//                        self.addSongButton.isSelected = containsSong
//                    case .failure(let error):
//                        print("error checking if song is already in lib: ", error)
//                }
//        }
    }
    
    func jamsPlayerReady() {
        refreshSongPlayStatus()
    }
    
    func firebaseEventHandler(notification: NSNotification) {
        guard let event = notification.object as? FirebaseAPI.FirebaseEvent else { print("erro"); return }
        switch event {
        case .MemberJoined, .MemberLeft:
            break
        case .ResyncStream:
            self.progressSliderValue = jamsPlayer.position_ms
            self.loadTopSong()
            self.refreshSongPlayStatus()
            break
        case .SwitchedStreams:
            self.viewWillAppear(true)
            self.refreshSongPlayStatus()
            break
        case .SetProgress:
            self.progressSliderValue = jamsPlayer.position_ms
        default:
            break
        }
    }

    @IBAction func showMenuButtonPressed(_ sender: Any) {
        let actionController = MenuActionController()
        actionController.addAction(Action("Add to Spotify Library", style: .default, handler: { action in
            
        }))
        actionController.addAction(Action("Leave Stream", style: .default, handler: { action in
            self.performSegue(withIdentifier: "leaveStream", sender: nil)
        }))
        
        if Current.isHost() {
            actionController.addAction(Action("Skip Song", style: .default, handler: { action in
                
            }))
        }
        
        actionController.addAction(Action("Close", style: .cancel, handler: nil))
        present(actionController, animated: true, completion: nil)
    }
}

// basic extension to make border radius on button from storyboard
extension UIView {
    
    @IBInspectable var cornerRadius: CGFloat {
        get {
            return layer.cornerRadius
        }
        set {
            layer.cornerRadius = newValue
            layer.masksToBounds = newValue > 0
        }
    }
    
    @IBInspectable var borderWidth: CGFloat {
        get {
            return layer.borderWidth
        }
        set {
            layer.borderWidth = newValue
        }
    }
    
    @IBInspectable var borderColor: UIColor? {
        get {
            return UIColor(cgColor: layer.borderColor!)
        }
        set {
            layer.borderColor = newValue?.cgColor
        }
    }
}

