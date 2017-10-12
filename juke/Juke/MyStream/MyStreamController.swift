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
import Presentr

class MyStreamController: UITableViewController {
    
    // firebase vars
    let songsDataSource = SongQueueDataSource()
    
    @IBOutlet var pausedLabel: UILabel!
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
    
    // presenter vars for naming stream
    let presenter: Presentr = {
        let presenter = Presentr(presentationType: .alert)
        presenter.dismissAnimated = true
        presenter.cornerRadius = 10
        presenter.transitionType = TransitionType.coverVerticalFromTop
        presenter.keyboardTranslationType = .moveUp
        return presenter
    }()
    
    lazy var nameStreamViewController: NameStreamViewController = {
        return NameStreamViewController(nibName: "NameStreamViewController", bundle: nil)
    }()
    
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
        if Current.isHost() {
            Current.stream?.isPlaying = status
            FirebaseAPI.setPlayStatus(status: status)   // update db
        } else {
            FirebaseAPI.listenForSongProgress() // fetch real song progress to maintain sync
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
        FirebaseAPI.listenForSongProgress() // will update if progress difference > 4 seconds
        songsDataSource.setObservedStream()
        self.setUpControlButtons()
        setUI()
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
            } else {
                self.listenButton.isSelected = Current.listenSelected
            }
            
            if !Current.isHost() && !stream.isPlaying {
                coverArtImage.alpha = 0.3
                pausedLabel.isHidden = false
            } else {
                coverArtImage.alpha = 1.0
                pausedLabel.isHidden = true
            }
            
            self.checkIfUserLibContainsCurrentSong(song: song)
            progressSlider.isHidden = false
            currTimeLabel.isHidden = false
            progressSliderValue = jamsPlayer.position_ms
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
        if FirebaseAPI.progressLocked { return }
        if let data = notification.object as? NSDictionary {
            let progress = data["progress"] as! Double
            self.progressSliderValue = progress
            if Current.isHost() {
                FirebaseAPI.updateSongProgress(progress: progress)
            }
        }
    }
    
    func songFinished() {
        if (Current.isHost()) {
            let nextSong = songsDataSource.getNextSong()
            Current.stream!.song = nextSong
            FirebaseAPI.popTopSong(nextSong: nextSong)  // UI refresh is triggered from here
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
        jamsPlayer.position_ms += 1000  // also update this so when user toggles, picks up here
    }
    
    private func setEmptyStreamUI() {
        // notification handled in MyStreamRootViewController
        NotificationCenter.default.post(name: Notification.Name("updateMyStreamView"), object: nil)
    }
    
    @IBAction func addToSpotifyLibButtonPressed(_ sender: Any) {
        let songAdded = !addToSpotifyLibButton.isSelected
        let path = songAdded ? Constants.kAddSongByIDPath: Constants.kDeleteSongByIDPath
        let method: HTTPMethod = songAdded ? .put : .delete
        if let song = Current.stream?.song {
            SessionManager.executeWithToken(callback: { (token) in
                guard let token = token else { return }
                let headers = [
                    "Authorization": "Bearer " + token
                ]
                let url = URL(string: Constants.kSpotifyBaseURL+path+song.spotifyID)!
                self.addToSpotifyLibButton.isSelected = !self.addToSpotifyLibButton.isSelected
                Alamofire.request(url, method: method, headers: headers).validate().responseData() { response in
                    switch response.result {
                    case .success:
                        // tell spotify search table view controller to update lib
                        let dict: [String: Any?] = ["song": song, "shouldAdd": songAdded]
                        NotificationCenter.default.post(name: Notification.Name("libraryChanged"), object: dict)
                        self.delay(0.5) {
                            let message = songAdded ? "Saved \(song.songName) to your library!" : "Removed \(song.songName) from your library"
                            HUD.flash(.labeledSuccess(title: nil, subtitle: message), delay: 1.00)
                        }
                        break
                    case .failure(let error):
                        print("Error saving to spotify lib: ", error)
                        self.delay(0.5) {
                            HUD.flash(.labeledError(title: nil, subtitle: "Error saving \(song.songName) to your library"), delay: 1.00)
                        }
                    }
                }
            })
        }
    }
    
    func checkIfUserLibContainsCurrentSong(song: Models.FirebaseSong) {
        
        SessionManager.executeWithToken { (token) in
            guard let token = token else { return }
            let headers = [
                "Authorization": "Bearer " + token
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
    }
    
    func firebaseEventHandler(notification: NSNotification) {
        guard let event = notification.object as? FirebaseAPI.FirebaseEvent else { print("erro"); return }
        switch event {
        case .MemberJoined, .MemberLeft:
            let numMembers = Current.stream!.members.count + 1 // +1 for host
            let numMembersString = "\(numMembers) member" + (numMembers > 1 ? "s" : "")
            self.numContributorsButton.setTitle(numMembersString, for: .normal)
        case .PlayStatusChanged:
            self.handleAutomaticProgressSlider()
            guard let stream = Current.stream else { return }
            if !Current.isHost() && !stream.isPlaying {
                coverArtImage.alpha = 0.3
                pausedLabel.isHidden = false
            } else {
                coverArtImage.alpha = 1.0
                pausedLabel.isHidden = true
            }
        case .TopSongChanged:
            self.setUI()
        case .SetProgress:
            self.progressSliderValue = jamsPlayer.position_ms
        case .StreamTitleChanged:
            self.streamNameLabel.text = Current.stream?.title
        }
    }
    
    let nameStreamPrompts = ["Sunday Candy", "Monday Funday", "Taco Tuesday", "Hump Day Jams", "Thirsty Thursday", "Flashback Friday", "Saturday Vibes"]
    
    func showNameStreamModal() {
        let today = Date()
        let gregorian = Calendar(identifier: .gregorian)
        let dateComponents = gregorian.dateComponents([.weekday], from: today)
        let weekday = dateComponents.weekday!
        nameStreamViewController.placeholder = nameStreamPrompts[weekday-1]
        presenter.viewControllerForContext = self
        customPresentViewController(presenter, viewController: nameStreamViewController, animated: true, completion: nil)
    }
    
    func showEndStreamModal() {
        let title = "Are you sure?"
        let body = "The vibe will be lost forever if you do this!"
        let controller = Presentr.alertViewController(title: title, body: body)
        
        let deleteAction = AlertAction(title: "Sure 🕶", style: .destructive) {
            Current.stream = nil
        }
        
        let okAction = AlertAction(title: "NO, sorry 🙄", style: .cancel) {
            print("Ok!")
        }
        
        controller.addAction(deleteAction)
        controller.addAction(okAction)
        
        presenter.presentationType = .alert
        customPresentViewController(presenter, viewController: controller, animated: true, completion: nil)
    }

    @IBAction func showMenuButtonPressed(_ sender: Any) {
        let actionController = MenuActionController()
        
        if Current.isHost() {
            actionController.addAction(Action("Name Stream", style: .default, handler: { action in
                self.showNameStreamModal()
            }))
            
            actionController.addAction(Action("Skip Song", style: .default, handler: { action in
                self.songFinished()
            }))
            
            actionController.addAction(Action("End Stream", style: .default, handler: { action in
                self.showEndStreamModal()
            }))
        } else {
            actionController.addAction(Action("Leave Stream", style: .default, handler: { action in
                Current.stream = nil    // see Current.swift for everything this entails
            }))
        }
        
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

