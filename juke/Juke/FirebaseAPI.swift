//
//  FirebaseAPI.swift
//  Juke
//
//  Created by Conner Smith on 8/18/17.
//  Copyright © 2017 csmith. All rights reserved.
//

import Foundation
import Firebase
import FirebaseDatabaseUI
import Whisper
import ChameleonFramework
import Alamofire

class FirebaseAPI {
    
    // listened for in MyStreamController
    public enum FirebaseEvent {
        case MemberJoined
        case MemberLeft
        case TopSongChanged
        case SetProgress
        case PlayStatusChanged
        case StreamTitleChanged
    }
    
    private static var observedPaths: [String] = []
    
    // firebase ref
    public static let ref = Database.database().reference()
    
    // audio player
    private static let jamsPlayer = JamsPlayer.shared
    public static var progressLocked = false
    
    // this method is called from Current.swift when stream is reassigned a new value
    public static func addListeners() {
        addPresenceListener()
        guard let _ = Current.stream else { return }
        addMemberLeftListener()
        addMemberJoinedListener()
        addMemberPresenceChangeListener() // used to listen for online/offline change
        addTopSongChangedListener()
        addSongPlayStatusListener()
        addStreamDeletedListener()
        addStreamTitleChangedListener()
    }
    
    private static func addStreamDeletedListener() {
        let path = "/streams/\(Current.stream!.streamID)"
        ref.child(path).observe(.childRemoved, with:{ (snapshot) in
            guard let stream = Current.stream else { return }
            if snapshot.key == "host" {    // if deleted stream is my stream
                Current.stream = nil    // this entails firebase calls and posted notifications that will initiate segue in middle tab. See Current.swift

                // display Whisper notification
                whisper(title: "\(stream.host.username) erased stream \"\(stream.title)\"" , backgroundColor: FlatPink())
                
                // post event telling empty stream controller to refresh in case queue was empty, so
                // controller wasn't active
                NotificationCenter.default.post(name: Notification.Name("streamDeleted"), object: nil)
            }
        })
        self.observedPaths.append(path)
    }
    
    private static func addSongPlayStatusListener() {
        let path = "streams/\(Current.stream!.streamID)/isPlaying"
        ref.child(path).observe(.value, with:{ (snapshot) in
            if Current.isHost() { return }

            if snapshot.exists(), let isPlaying = snapshot.value as? Bool {
                Current.stream!.isPlaying = isPlaying
                self.listenForSongProgress(shouldUnlockProgress: false)    // fetch updated status
            } else {
                Current.stream!.isPlaying = false
            }
            jamsPlayer.resync()
            NotificationCenter.default.post(name: Notification.Name("firebaseEvent"), object: FirebaseEvent.PlayStatusChanged)
            NotificationCenter.default.post(name: Notification.Name("firebaseEventLockScreen"), object: FirebaseEvent.PlayStatusChanged)
        }) { err in print(err.localizedDescription)}
        observedPaths.append(path)
    }
    
    private static func addMemberPresenceChangeListener() {
        // listen for member presence changes
        let path = "/streams/\(Current.stream!.streamID)/members"
        ref.child(path).observe(.childChanged, with:{ (snapshot) in
            if Current.stream == nil { return }
            guard let changedMember = Models.FirebaseUser(snapshot: snapshot) else { return }
            if let index = Current.stream!.members.index(where: { (member) -> Bool in
                member.spotifyID == changedMember.spotifyID
            }) {
                Current.stream?.members[index] = changedMember // update member
            }
        }) { error in print(error.localizedDescription)}
        observedPaths.append(path)  // only need to append this path once -- not again for member joined/member left
        
        // listen for host presence changes
        let hostPath = "/streams/\(Current.stream!.streamID)/host"
        ref.child(hostPath).observe(.childChanged, with:{ (snapshot) in
            guard let host = Models.FirebaseUser(snapshot: snapshot) else { return }
            Current.stream?.host = host
        }) { error in print(error.localizedDescription)}
        observedPaths.append(hostPath)
    }
    
    private static func addMemberJoinedListener() {
        let path = "/streams/\(Current.stream!.streamID)/members"   // don't append to observedPaths again (see memberChange)
        ref.child(path).observe(.childAdded, with:{ (snapshot) in
            // update Current stream
            guard let stream = Current.stream else { return }
            guard let member = Models.FirebaseUser(snapshot: snapshot) else { return }
            if stream.members.contains(where: { (other) -> Bool in
                return member.spotifyID == other.spotifyID
            }) || Current.user?.spotifyID == member.spotifyID {
                // member already in client member list -- ignore this event -- triggered when observer
                // first registered
                return
            } else {
                Current.stream!.members.append(member)
            }
            
            // display Whisper notification
            whisper(title: "\(member.username) joined your stream!" , backgroundColor: FlatPink())
            
            // post event telling controller to update UI
            NotificationCenter.default.post(name: Notification.Name("firebaseEvent"), object: FirebaseEvent.MemberJoined)
            
        }) { error in print(error.localizedDescription)}
    }
    
    private static func addMemberLeftListener() {
        let path = "/streams/\(Current.stream!.streamID)/members"   // don't append to observedPaths again (see memberChange)
        ref.child(path).observe(.childRemoved, with:{ (snapshot) in
            // update Current stream
            guard let member = Models.FirebaseUser(snapshot: snapshot) else { return }
            guard let index = Current.stream!.members.index(where: { (other) -> Bool in
                return member.spotifyID == other.spotifyID
            }) else {
                return
            }
            if Current.user?.spotifyID == member.spotifyID {
                return
            }
            Current.stream!.members.remove(at: index)
            
            // display Whisper notification
            whisper(title: "\(member.username) left your stream" , backgroundColor: FlatPink())
            
            // post event telling controller to update UI
            NotificationCenter.default.post(name: Notification.Name("firebaseEvent"), object: FirebaseEvent.MemberLeft)
            
        }) { error in print(error.localizedDescription) }
    }
    
    public static func whisper(title: String, backgroundColor: UIColor) {
        let murmur = Murmur(title: title, backgroundColor: backgroundColor, titleColor: FlatWhite(), font: UIFont.boldSystemFont(ofSize: 16))
        Whisper.show(whistle: murmur, action: .show(4.0))
    }
    
    // listens once to song progress and triggers update if necessary (out of sync by > 3 seconds)
    // this is called by other classes to trigger a progress resync or get progress initially after
    // joining a new stream
    public static func listenForSongProgress(shouldUnlockProgress: Bool) {
        guard let stream = Current.stream else {
            if shouldUnlockProgress { objc_sync_exit(progressLocked) }
            return
        }
        
        self.ref.child("/songProgressTable/\(stream.streamID)").observeSingleEvent(of: .value, with: { (snapshot) in
            // note that setting jamsPlayer will trigger a resync if off by > 4 seconds
            if snapshot.exists(), let updatedProgress = snapshot.value as? Double {
                jamsPlayer.position_ms = updatedProgress
            } else {
                jamsPlayer.position_ms = 0.0
            }
            if shouldUnlockProgress { objc_sync_exit(progressLocked) }
            
            // post event telling controller to resync
            NotificationCenter.default.post(name: Notification.Name("firebaseEvent"), object: FirebaseEvent.SetProgress)
        }) { error in
            if shouldUnlockProgress { objc_sync_exit(progressLocked) }
            print(error.localizedDescription)
        }
    }
    
    // deletes top song in current stream -- should only be called by host when spotify signals
    // that song ended or when host presses skip
    // then this method loads top song from list of queued songs, if any exists
    public static func popTopSong(nextSong: Models.FirebaseSong?) {
        
        // ** note that only the host touches this method **
        
        guard let stream = Current.stream else { return }
        // reset progress in any case
        objc_sync_enter(progressLocked) // unlocked in setProgressLock()
        print("setting progress to 0.0")
        self.ref.child("/songProgressTable/\(stream.streamID)").setValue(0.0)
        
        if let next = nextSong {
            self.ref.child("/streams/\(stream.streamID)/song").setValue(next.firebaseDict)
            self.ref.child("/songs/\(stream.streamID)/\(next.key)").removeValue()
        } else {
            // no songs queued
            self.ref.child("/streams/\(stream.streamID)/song").removeValue()
            setPlayStatus(status: false)    // pause stream -- no songs queued
        }
        setProgressLock()
        jamsPlayer.position_ms = 0.0    // trigger a local resync
        
        // post event telling controllers to resync so it's very responsive for host
        // others will get the update in topSongChangedListener
        NotificationCenter.default.post(name: Notification.Name("firebaseEvent"), object: FirebaseEvent.TopSongChanged)
        NotificationCenter.default.post(name: Notification.Name("firebaseEventLockScreen"), object: FirebaseEvent.TopSongChanged)
    }
    
    // this fixes the issue where spotify playback updates come in late -- strategy is to not let
    // host update progress
    private static func setProgressLock() {
        progressLocked = true
        print("progress locked")
        let when = DispatchTime.now() + 2 // unlock progress updates after 2 seconds to flush out lingering spotify progress updates from previous song
        DispatchQueue.global().asyncAfter(deadline: when) {
            print("progress unlocked")
            progressLocked = false
            objc_sync_exit(progressLocked)
        }
    }
    
    private static func addTopSongChangedListener() {
        guard let stream = Current.stream else { return }
        // listen for top song changes -- includes song skips and song finishes
        let path = "/streams/\(stream.streamID)/song"
        self.ref.child(path).observe(.value, with: { (snapshot) in
            guard let stream = Current.stream else { return }
            
            if Current.isHost() {
                if stream.song == nil { // if queue was empty, need to fire events so that the MyStream view is loaded again instead of empty view
                    Current.stream!.song = Models.FirebaseSong(snapshot: snapshot)
                    self.jamsPlayer.position_ms = 0.0
                    NotificationCenter.default.post(name: Notification.Name("firebaseEvent"), object: FirebaseEvent.TopSongChanged)
                    NotificationCenter.default.post(name: Notification.Name("firebaseEventLockScreen"), object: FirebaseEvent.TopSongChanged)
                }
                return
            }
            
            objc_sync_enter(progressLocked) // unlocked in listenForSongProgress() after getting the reading
            Current.stream!.song = Models.FirebaseSong(snapshot: snapshot)
            
            // since most of the time this will be the case, kick this off while
            // waiting for listenForProgress to give an updated progress (sometimes not beginning of song)
            self.jamsPlayer.position_ms = 0.0

            self.listenForSongProgress(shouldUnlockProgress: true)
            
            // post event telling controller to resync in case it's already active
            NotificationCenter.default.post(name: Notification.Name("firebaseEvent"), object: FirebaseEvent.TopSongChanged)
            NotificationCenter.default.post(name: Notification.Name("firebaseEventLockScreen"), object: FirebaseEvent.TopSongChanged)
            
        }) { error in print(error.localizedDescription) }
        observedPaths.append(path)
    }
    
    public static func addPresenceListener() {
        guard let user = Current.user else { return }
        
        // update main user object
        self.ref.child("/users/\(user.spotifyID)/online").onDisconnectSetValue(false)
        
        // STREAM object updates
        guard let stream = Current.stream else { return }
        if Current.isHost() {
            self.ref.child("/streams/\(stream.streamID)/isPlaying").onDisconnectSetValue(false)
            print("added listener for stream: ", stream.streamID)
        }
    }
    
    private static func queueSongHelper(spotifySong: Models.SpotifySong) {
        guard let stream = Current.stream, let song = Models.FirebaseSong(song: spotifySong) else { return }
        self.ref.child("/streams/\(stream.streamID)/song").observeSingleEvent(of: .value, with: { (snapshot) in
            if snapshot.exists() {
                // if there is already a top song right now (queue not empty), write it to the song queue
                self.ref.child("/songs/\(stream.streamID)/\(song.key)").setValue(song.firebaseDict)
            } else {
                // no current song - set current song
                self.ref.child("/streams/\(stream.streamID)/song").setValue(song.firebaseDict)
            }
        }) { error in print(error.localizedDescription) }
    }
    
    private static func queuePlaylistHelper(songs: [Models.SpotifySong]) {
        guard let stream = Current.stream else { return }
        for index in 0..<songs.count {
            guard let song = Models.FirebaseSong(song: songs[index]) else { continue }
            print("adding song: " + song.songName)
            if index == 0 && stream.song == nil {
                self.ref.child("/streams/\(stream.streamID)/song").setValue(song.firebaseDict)
                continue
            }
            
            self.ref.child("/songs/\(stream.streamID)/\(song.key)").setValue(song.firebaseDict)
        }
    }
    
    public static func queueSong(spotifySong: Models.SpotifySong) {
        if Current.stream == nil {
            FirebaseAPI.createNewStream(title: "\(Current.user!.username)'s Stream") {
                self.queueSongHelper(spotifySong: spotifySong)
            }
        } else {
            queueSongHelper(spotifySong: spotifySong)
        }
    }
    
    public static func queuePlaylist(songs: [Models.SpotifySong]) {
        if songs.count == 0 { return }
        if Current.stream == nil {
            FirebaseAPI.createNewStream(title: "\(Current.user!.username)'s Stream") {
                self.queuePlaylistHelper(songs: songs)
            }
        } else {
            self.queuePlaylistHelper(songs: songs)
        }
        
    }
    
    // called from StreamsTableViewController when user selects a new stream to join
    public static func joinStreamPressed(stream: Models.FirebaseStream, callback: @escaping ((_: Bool) -> Void)) {

        guard let user = Current.user else { return }
        var dict = user.firebaseDict
        dict["tunedInto"] = stream.streamID
        Current.stream = stream
        ref.child("/streams/\(stream.streamID)/members/\(user.spotifyID)").setValue(dict)
        Current.stream!.members.append(user)
        Current.listenSelected = true // default listen when join stream

        // callback to StreamsDataSource/StarredStreamsDataSource to communicate success
        callback(true)
    }
    
    public static func setPlayStatus(status: Bool) {
        guard let stream = Current.stream else { return }
        Current.stream!.isPlaying = status
        ref.child("/streams/\(stream.streamID)/isPlaying").setValue(status)
    }
    
    // clears current song queue
    public static func clearStream() {
        guard let stream = Current.stream else { return }
        ref.child("songs/\(stream.streamID)").removeValue()
    }
    
    // this method is called from Current.swift when stream is assigned a new value
    public static func leaveStream(current: Models.FirebaseStream?, callback: @escaping (() -> Void)) {
        // cancel listeners because they're wired to old stream
        removeAllObservers() {
            // when all observers are removed, update db
            if let currentStreamID = current?.streamID {
                guard let user = Current.user else { return }
                if current?.host.spotifyID == user.spotifyID {
                    // delete current stream and associated resources if host
                    self.ref.child("/streams/\(currentStreamID)").removeValue()
                    self.ref.child("/songs/\(currentStreamID)").removeValue()
                    self.ref.child("/songProgressTable/\(currentStreamID)").removeValue()
                } else {
                    self.ref.child("/streams/\(currentStreamID)/members/\(user.spotifyID)").removeValue()    // remove self from members list
                }
            }
            callback()
        }
    }
    
    public static func joinStream(newStream: Models.FirebaseStream?) {
        guard let user = Current.user else { return }
        ref.child("users/\(user.spotifyID)/tunedInto").setValue(newStream?.streamID ?? NSNull())
        Current.user!.tunedInto = newStream?.streamID
    }
    
    // creates and joins empty stream with user as host. leaves current stream if any
    public static func createNewStream(title: String, callback: @escaping (() -> Void)) {
        var newStream = Models.FirebaseStream()
        
        // terrible style but this is the most reliable way for now (surpass network calls) to encode
        // featured streams. just change spotify ID to DAP's or Matoma's
        // lmao lmao, love this - Kojo
        if Current.user?.spotifyID ?? "" == "22xpbylgoadqnzdz64o6xppua" {
            newStream.isFeatured = true
        }
        
        // create stream in firebase
        ref.child("streams/\(newStream.streamID)").setValue(newStream.firebaseDict)
        
        // update global vars on device -- this will include firebase calls -- see Current.swift file
        Current.stream = newStream
        jamsPlayer.position_ms = 0.0
        callback()
    }
    
    public static func updateSongProgress(progress: Double) {
        guard let stream = Current.stream else { return }
        ref.child("/songProgressTable/\(stream.streamID)").setValue(progress)
    }
    
    // smh since firebase removeAllObservers() doesn't do what you think it does, need
    // to iterate through list
    private static func removeAllObservers(callback: @escaping (() -> Void)) {
        for path in self.observedPaths {
            self.ref.child(path).removeAllObservers()
        }
        observedPaths.removeAll()
        
        ref.cancelDisconnectOperations { (error, ref) in
            if let err = error {print("error disconnnecting: ", err.localizedDescription)}
            callback()
        }
    }

    public static func setfcmtoken() {
        guard let user = Current.user else { return }
        let fcmToken = Messaging.messaging().fcmToken
        Current.user!.fcmToken = fcmToken
        print("called set token", fcmToken as Any)
        self.ref.child("users/\(user.spotifyID)/fcmToken").setValue(fcmToken)
        guard let stream = Current.stream else { return }
        if Current.isHost() {
            self.ref.child("streams/\(stream.streamID)/host/\(user.spotifyID)/fcmToken").setValue(fcmToken)
        } else {
            self.ref.child("streams/\(stream.streamID)/members/\(user.spotifyID)/fcmToken").setValue(fcmToken)
        }
        
    }
    
    public static func setOnboardTrue() {
        guard let user = Current.user else { return }
        self.ref.child("users/\(user.spotifyID)/onboard").setValue(true)
    }
    
    public static func loginUser(spotifyUser: Models.SpotifyUser, callback: @escaping ((_: Bool) -> Void)) {
        ref.child("users/\(spotifyUser.spotifyID)").observeSingleEvent(of: .value, with: { (snapshot) in
            if snapshot.exists() {
                if var userDict = snapshot.value as? [String: Any?] {
                    userDict["spotifyID"] = spotifyUser.spotifyID
                    Current.user = Models.FirebaseUser(dict: userDict)
                    self.ref.child("users/\(spotifyUser.spotifyID)/online").setValue(true)
                    setfcmtoken()
                }
            } else {
                // add user if user does not exist
                var newUserDict: [String: Any?] = ["imageURL": spotifyUser.imageURL,
                                                   "tunedInto": nil,
                                                   "online": true, "onboard": false]
                if let username = spotifyUser.username {
                    newUserDict["username"] = username
                } else {
                    newUserDict["username"] = spotifyUser.spotifyID // use spotifyID if no spotify username
                }
                // set firebase messaging token
                let token = Messaging.messaging().fcmToken
                print("set fcmToken \(String(describing: token))")
                newUserDict["fcmToken"] = token
                // write to firebase DB
                self.ref.child("users/\(spotifyUser.spotifyID)").setValue(newUserDict)
                newUserDict["spotifyID"] = spotifyUser.spotifyID
                Current.user = Models.FirebaseUser(dict: newUserDict)
            }
            
            // now that current user is set, try to fetch stream
            if let tunedInto = Current.user!.tunedInto {
                self.ref.child("streams/\(tunedInto)").observeSingleEvent(of: .value, with : { (snapshot) in
                    if let stream = Models.FirebaseStream(snapshot: snapshot) {
                        Current.stream = stream
                        if Current.isHost() {
                            // since host doesn't subscribe to all top song changed events, otherwise first song isn't loaded on lock screen
                            // host only listens if queue is empty when song is queued
                            NotificationCenter.default.post(name: Notification.Name("firebaseEventLockScreen"), object: FirebaseEvent.TopSongChanged)
                        }
                    }
                    callback(true)
                }) { error in
                    print(error.localizedDescription)
                    callback(false)
                }
            } else {
                callback(true)
            }
            
        }) {(error) in
            print(error.localizedDescription)
            callback(false)
        }
    }
    
    public static func updateVotes(song: Models.FirebaseSong, upvoted: Bool, topSong: Bool) {
        guard let stream = Current.stream else { return }
        guard let user = Current.user else { return }
        if stream.isFeatured ?? false {
            self.ref.child("/featuredAnalytics/\(stream.host.username)/\(song.spotifyID)/upvoters/\(user.spotifyID)").setValue(upvoted ? true : false)
            if topSong { return }
        }
        
        if upvoted {
            self.ref.child("/songs/\(stream.streamID)/\(song.key)/upvoters/\(user.spotifyID)").setValue(true)
        } else {
            self.ref.child("/songs/\(stream.streamID)/\(song.key)/upvoters/\(user.spotifyID)").removeValue()
        }
        
    }
    
    public static func addStreamTitleChangedListener() {
        guard let stream = Current.stream else { return }
        let path = "/streams/\(stream.streamID)/title"
        ref.child(path).observe(.value, with:{ (snapshot) in
            guard let _ = Current.stream else { return }
            guard let title = snapshot.value as? String else { return }
            Current.stream!.title = title
            NotificationCenter.default.post(name: Notification.Name("firebaseEvent"), object: FirebaseEvent.StreamTitleChanged)
        })
        observedPaths.append("/streams/\(stream.streamID)/title")
    }
    
    public static func setStreamName(name: String) {
        guard let stream = Current.stream else { return }
        self.ref.child("/streams/\(stream.streamID)/title").setValue(name)
        self.ref.child("/streamsHistory/\(stream.streamID)/title").setValue(name)
    }
    
    public static func addToStarredTable(user: Models.FirebaseUser) {
        guard let currUser = Current.user else { return }
        self.ref.child("/starredTable/\(currUser.spotifyID)").child(user.spotifyID).setValue(user.firebaseDict)
    }
    
    public static func removeFromStarredTable(user: Models.FirebaseUser) {
        guard let currUser = Current.user else { return }
        self.ref.child("/starredTable/\(currUser.spotifyID)").child(user.spotifyID).removeValue()
    }
    
    public static func sendNotification(receiver: Models.FirebaseUser) {
        guard let user = Current.user else { return }
        let params: Parameters = [
            "sender": user.firebaseDict,
            "receiver": receiver.spotifyID
        ]
        
        print("called sendnotification with", receiver.fcmToken as Any)
        Alamofire.request(Constants.kSendNotificationsURL, method: .post, parameters: params, encoding: JSONEncoding.default).responseJSON { response in
            print("response came back", response)
        }
    }
    
    public static func updateTimestamp(stream: Models.FirebaseStream) {
        self.ref.child("/streams/\(stream.streamID)/timestamp").setValue(NSDate().timeIntervalSince1970)
    }
    
    // note: currently not using this at all
    public static func checkVerified(spotifyID: String?, callback: @escaping (Bool) -> Void) {
        guard let id = spotifyID else { callback(false); return }
        ref.child("/featuredArtists/"+id).observe(.value, with: { (snapshot) in
            if !snapshot.exists() { callback(false); return }
            callback(true)
        })
    }
    
    // MARK: Stream loading apis:: THIS IS A BAD IDEA - but okay
    public static func streamsListener(callback: @escaping (DataSnapshot) -> Void) {
        ref.child("streams").observe(.value, with: { (snapshot) in
            callback(snapshot)
        })
    }
}
