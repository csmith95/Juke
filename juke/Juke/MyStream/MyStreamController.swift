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
    
    @IBOutlet var addToSpotifyLibButton: UIButton!
    @IBOutlet var numContributorsButton: UIButton!
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
            guard let stream = Current.stream else { return }
            guard let song = stream.song else {
                self.progressValue = 0.0
                self.currTimeLabel.text = timeIntervalToString(interval: 0.0)
                return
            }
            
            if abs(newValue - song.duration) < 1000 {
                self.songFinished()  // force pop song based on timer
            } else if abs(newValue - self.progressValue) < 1000 {
                return  // to minimize UI updates
            }
            else {
                let normalizedProgress = newValue / song.duration
                self.progressSlider.value = Float(normalizedProgress)
                self.currTimeLabel.text = timeIntervalToString(interval: newValue/1000)
                self.progressValue = newValue
            }
        }
    }
    
    func delay(_ delay: Double, closure:@escaping () -> Void) {
        DispatchQueue.main.asyncAfter(
            deadline: DispatchTime.now() + Double(Int64(delay * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC), execute: closure)
    }
    
    @IBAction func toggleListening(_ sender: AnyObject) {
        guard let _ = Current.stream else { return }
        let status = !listenButton.isSelected
        listenButton.isSelected = status
        Current.listenSelected = status
        handleAutomaticProgressSlider()
        FirebaseAPI.listenForSongProgress() // fetch real song progress to maintain sync
        if Current.isHost() {
            print("set status: ", status)
            FirebaseAPI.setPlayStatus(status: status)
            Current.stream!.isPlaying = status
        }
        jamsPlayer.resync()
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
        FirebaseAPI.listenForSongProgress() // will update if progress difference > 3 seconds
        songsDataSource.setObservedStream()
        self.setUpControlButtons()
        FirebaseAPI.setfcmtoken()
        setUI()
        reloadSongs()
    }
    
    private func setUI() {
        guard let stream = Current.stream else {
            setEmptyStreamUI()
            return
        }
        
        let numMembers = stream.members.count + 1 // +1 for host
        let numMembersString = "\(numMembers) member" + (numMembers > 1 ? "s" : "")
        numContributorsButton.setTitle(numMembersString, for: .normal)   // +1 for host
        streamNameLabel.text = stream.title
        if let song = stream.song {
            self.coverArtImage.af_setImage(withURL: URL(string: song.coverArtURL)!, placeholderImage: nil)
            self.coverArtImage.isHidden = false
            self.bgblurimg.af_setImage(withURL: URL(string:song.coverArtURL)!, placeholderImage: nil)
            self.currentSongLabel.text = song.songName
            self.currentArtistLabel.text = song.artistName
            self.listenButton.isHidden = false
            if Current.isHost() {
                self.listenButton.isSelected = stream.isPlaying
            }
            self.checkIfUserLibContainsCurrentSong(song: song)
            progressSlider.isHidden = false
            currTimeLabel.isHidden = false
        } else {
            self.setEmptyStreamUI()
        }
    }
    
    
    private func setUpControlButtons() {
        guard let stream = Current.stream else { return }
        if Current.isHost() {
            // controls for the owner
            listenButton.setImage(UIImage(named: "ic_play_arrow_white_48pt.png"), for: .normal)
            listenButton.setImage(UIImage(named: "ic_pause_white_48pt.png"), for: .selected)
            listenButton.isSelected = stream.isPlaying
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
    
    private func handleAutomaticProgressSlider() {
        guard let stream = Current.stream else { return }
        if Current.isHost() {
            return  // if owner, don't use timer at all
        }
        
        if (!Current.listenSelected && stream.isPlaying) {
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
    
    private func setEmptyStreamUI() {
        // notification handled in MyStreamRootViewController
        NotificationCenter.default.post(name: Notification.Name("userStreamChanged"), object: nil)
    }
    
    @IBAction func addToSpotifyLibButtonPressed(_ sender: Any) {
        let songAdded = !addToSpotifyLibButton.isSelected
        let path = songAdded ? Constants.kAddSongByIDPath: Constants.kDeleteSongByIDPath
        let method: HTTPMethod = songAdded ? .put : .delete
        if let song = Current.stream?.song {
            let headers = [
                "Authorization": "Bearer " + SessionManager.accessToken
            ]
            let url = URL(string: Constants.kSpotifyBaseURL+path+song.spotifyID)!
            addToSpotifyLibButton.isSelected = !addToSpotifyLibButton.isSelected
            Alamofire.request(url, method: method, headers: headers).validate().responseData() { response in
                switch response.result {
                case .success:
                    // tell spotify search table view controller to update lib
                    NotificationCenter.default.post(name: Notification.Name("libraryChanged"), object: song)
                    self.delay(0.5) {
                        let message = songAdded ? "Saved \(song.songName) to your library!" : "Removed \(song.songName) from your library"
                        HUD.flash(.labeledSuccess(title: nil, subtitle: message), delay: 1.00)
                    }
                    break
                case .failure(let error):
                    print("Error saving to spotify lib: ", error)
                    self.delay(0.5) {
                        HUD.flash(.labeledError(title: nil, subtitle: "Error saving \(song.songName) to your librar"), delay: 1.00)
                    }
                }
            }
        }
    }
    
    func checkIfUserLibContainsCurrentSong(song: Models.FirebaseSong) {
        let headers = [
            "Authorization": "Bearer " + SessionManager.accessToken
        ]
        let url = URL(string: Constants.kSpotifyBaseURL+Constants.kContainsSongPath+song.spotifyID)!
        Alamofire.request(url, method: .get, headers: headers)
            .validate().responseJSON { response in
                switch response.result {
                    case .success:
                        let array = response.value as! [Bool]
                        let containsSong = array[0]
                        self.addToSpotifyLibButton.isHidden = false
                        self.addToSpotifyLibButton.isSelected = containsSong
                    case .failure(let error):
                        self.addToSpotifyLibButton.isHidden = true
                        print("error checking if song is already in lib: ", error)
                }
        }
    }
    
    func jamsPlayerReady() {
        guard let _ = Current.stream else { return }
        jamsPlayer.resync()
    }
    
    func firebaseEventHandler(notification: NSNotification) {
        guard let event = notification.object as? FirebaseAPI.FirebaseEvent else { print("erro"); return }
        switch event {
        case .MemberJoined, .MemberLeft:
            break
        case .PlayStatusChanged:
            self.handleAutomaticProgressSlider()
        case .TopSongChanged:
            self.setUI()
            break
        case .SetProgress:
            self.progressSliderValue = jamsPlayer.position_ms
        }
    }

    @IBAction func showMenuButtonPressed(_ sender: Any) {
        let actionController = MenuActionController()
        
        if Current.isHost() {
            actionController.addAction(Action("Skip Song", style: .default, handler: { action in
                self.songFinished()
            }))
        }
        
        let leaveMessage = Current.isHost() ? "End Stream" : "Leave Stream"
        actionController.addAction(Action(leaveMessage, style: .default, handler: { action in
            Current.stream = nil    // see Current.swift for everything this entails
        }))
        
        actionController.addAction(Action("Close", style: .cancel, handler: nil))
        present(actionController, animated: true, completion: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ShowMembers" {
            guard let stream = Current.stream else { return }
            let dest = segue.destination as! MembersTableViewController
            dest.stream = stream
        }
    }
    
    @IBAction func unwindToViewControllerNameHere(segue: UIStoryboardSegue) {
        //nothing goes here
    }
    
    // set status bar text to white
    override var preferredStatusBarStyle: UIStatusBarStyle { return .lightContent }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
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

