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
    let ref = Database.database().reference()
    fileprivate var _refHandle: DatabaseHandle!
    var streams: [DataSnapshot]! = []
    var dataSource: FUITableViewDataSource!
    
    // app vars
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
    
    var currSongProgress = 0.0
    
    // deinit firebase
    deinit {
        
    }
    
    func configureStreamsDatabase() {
//        _refHandle = self.ref.child("streams").observe(.childAdded, with: { [weak self] (snapshot) -> Void in
//            guard let strongSelf = self else { return }
//            strongSelf.streams.append(snapshot)
//            strongSelf.tableView.insertRows(at: [IndexPath(row: strongSelf.streams.count-1, section: 0)], with: .automatic)
//        })
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
        if let song = CurrentUser.stream.song {
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
    }
    
    func delay(_ delay: Double, closure:@escaping () -> Void) {
        DispatchQueue.main.asyncAfter(
            deadline: DispatchTime.now() + Double(Int64(delay * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC), execute: closure)
    }
    
    @IBAction func toggleListening(_ sender: AnyObject) {
        if CurrentUser.stream.song == nil {
            return
        }
        let status = !listenButton.isSelected
        listenButton.isSelected = status
        if CurrentUser.isHost() {
            ref.child("/streams/\(CurrentUser.stream.streamID)/isPlaying").setValue(status)
            CurrentUser.stream.isPlaying = status
        }
        setSong(play: status && CurrentUser.stream.isPlaying)
    }
    
    @IBAction func skipSong(_ sender: Any) {
        //set song to next thing in stream
        if CurrentUser.stream.song == nil {
            return
        }
        songFinished()
    }
    
    @IBAction func returnToPersonalStream(_ sender: Any) {
        let streamID = ref.child("/streams").childByAutoId().key
        let host = Models.FirebaseMember(username: CurrentUser.user.username, imageURL: CurrentUser.user.imageURL)
        var stream: [String: Any?] = [:]
        stream["host"] = host.dictionary
        stream["members"] = host.dictionary
        stream["song"] = nil
        stream["isPlaying"] = false
        let childUpdates: [String: Any] = ["/streams/\(streamID)": stream,
                            "/songs/\(streamID)": NSNull()]
        ref.updateChildValues(childUpdates)
        stream["streamID"] = streamID
        CurrentUser.stream = Models.FirebaseStream(dict: stream)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.delegate = self
        NotificationCenter.default.addObserver(self, selector: #selector(MyStreamController.songFinished), name: Notification.Name("songFinished"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(MyStreamController.songPositionChanged), name: Notification.Name("songPositionChanged"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(MyStreamController.jamsPlayerReady), name: Notification.Name("jamsPlayerReady"), object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.navigationBar.titleTextAttributes = [ NSFontAttributeName: UIFont(name: "Helvetica", size: 15)!]
        self.dataSource = self.tableView.bind(to: self.ref.child("/songs/\(CurrentUser.stream.streamID)"))
            { tableView, indexPath, snapshot in
                let cell = tableView.dequeueReusableCell(withIdentifier: "SongCell", for: indexPath) as! SongTableViewCell
                guard let song = Models.FirebaseSong(snapshot: snapshot) else { return cell }
                //                self.songs[indexPath.row] = song
                cell.populateCell(song: song)
                return cell
            }
        loadTopSong()
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
        if let song = CurrentUser.stream.song, let data = notification.object as? NSDictionary {
            let progress = data["progress"] as! Double
            currSongProgress = progress
            if CurrentUser.isHost() {
                ref.child("/songProgressTable/\(CurrentUser.stream.streamID)").setValue(currSongProgress)
            }
            updateSlider(song: song)
        }
    }
    
    private func updateSlider(song: Models.FirebaseSong) {
        let normalizedProgress = currSongProgress / song.duration
        progressSlider.value = Float(normalizedProgress)
        self.currTimeLabel.text = timeIntervalToString(interval: currSongProgress/1000)
    }
    
    func songFinished() {
        if CurrentUser.stream.song == nil  {
            return
        }
        loadTopSong()
        if (CurrentUser.isHost()) {
            ref.child("/songs/\(CurrentUser.stream.streamID)/").queryOrdered(byChild: "/votes")
                .queryLimited(toLast: 1).observeSingleEvent(of: .value, with: { (snapshot) in
                    print("** songFinished: \(snapshot)")
                    if let nextSong = snapshot.value as? [String: Any] {
                        print(nextSong)
                        self.ref.child("/streams/\(CurrentUser.stream.streamID)/song").setValue(nextSong)
                        self.ref.child("/songs/\(CurrentUser.stream.streamID)/\(snapshot.key)").setValue(NSNull())
                    } else {
                        self.ref.child("/streams/\(CurrentUser.stream.streamID)/song").setValue(NSNull())
                    }
                    self.ref.child("/songProgressTable/\(CurrentUser.stream.streamID))").setValue(0.0)
            }) { error in
                print(error.localizedDescription)
            }
        }
    }
    
    public func setSong(play: Bool) {
        if let song = CurrentUser.stream.song {
            jamsPlayer.setPlayStatus(shouldPlay: play, song: song, progress: currSongProgress)
            if !CurrentUser.isHost() {
                setTimer(run: !play && CurrentUser.stream.isPlaying)
            }
        }
    }
    
    private func setTimer(run: Bool) {
        
        DispatchQueue.main.async {
            if (CurrentUser.isHost() || CurrentUser.stream.song == nil) {
                return  // if owner, don't use timer at all
            }
            
            if (run) {
                if !self.animationTimer.isValid {
                    self.currSongProgress += 300 // trying to offset for the time transition between stopping timer and starting song
                    self.animationTimer = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(self.updateAnimationProgress), userInfo: nil, repeats: true)
                }
            } else {
                if self.animationTimer.isValid {
                    self.currSongProgress += 300 // trying to offset for the time transition between stopping timer and starting song
                    self.animationTimer.invalidate()
                }
            }
        }
    }
    
    func updateAnimationProgress() {
        if let song = CurrentUser.stream.song {
            let newProgress = self.currSongProgress + 500
            updateSlider(song: song)
            if abs(newProgress - song.duration) < 1000 {
                songFinished()  // force pop song based on timer
            }
        } else {
            progressSlider.value = Float(0)
        }
    }
    
    private func loadTopSong() {
        ref.child("/streams/\(CurrentUser.stream.streamID)/song").observeSingleEvent(of: .value, with: { (snapshot) in
            if snapshot.exists() {
                print(snapshot)
                if let song = Models.FirebaseSong(snapshot: snapshot) {
                    print("got song: ", song)
                    CurrentUser.stream.song = song
                    self.coverArtImage.af_setImage(withURL: URL(string: song.coverArtURL)!, placeholderImage: nil)
                    self.bgblurimg.af_setImage(withURL: URL(string:song.coverArtURL)!, placeholderImage: nil)
                    self.currentSongLabel.text = song.songName
                    self.currentArtistLabel.text = song.artistName
                    self.addSongButton.isHidden = false
                    self.listenButton.isHidden = false
                    self.skipButton.isHidden = !CurrentUser.isHost()
                    self.clearStreamButton.isHidden = !CurrentUser.isHost()
                    self.checkIfUserLibContainsCurrentSong(song: song)
                    self.updateSlider(song: song)
                    self.setSong(play: self.listenButton.isSelected && CurrentUser.stream.isPlaying)
                }
            } else {
                self.setEmptyStreamUI()
            }
        }) { error in
            print(error.localizedDescription)
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
        let childUpdates = ["/streams/\(CurrentUser.stream.streamID)/song": NSNull(),
                            "/songs/\(CurrentUser.stream.streamID)": NSNull()]
        ref.updateChildValues(childUpdates)
    }
}
