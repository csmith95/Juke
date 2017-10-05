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
    enum FirebaseEvent {
        case MemberJoined
        case MemberLeft
        case TopSongChanged
        case SetProgress
        case PlayStatusChanged
        case StreamTitleChanged
    }
    
    private static var observedPaths: [String] = []
    
    // firebase ref
    private static let ref = Database.database().reference()
    
    // audio player
    private static let jamsPlayer = JamsPlayer.shared
    
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
            if Current.isHost() {
                // this fixes this bug: play music. lock screen. when locked, pause stream.
                // open app. without this line, the play/pause state doesn't get updated.
                NotificationCenter.default.post(name: Notification.Name("firebaseEvent"), object: FirebaseEvent.PlayStatusChanged)
                return
            }
            
            if snapshot.exists(), let isPlaying = snapshot.value as? Bool {
                Current.stream!.isPlaying = isPlaying
                self.listenForSongProgress()    // fetch updated status
                NotificationCenter.default.post(name: Notification.Name("firebaseEvent"), object: FirebaseEvent.PlayStatusChanged)
                NotificationCenter.default.post(name: Notification.Name("firebaseEventLockScreen"), object: FirebaseEvent.PlayStatusChanged)
            }
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
    public static func listenForSongProgress() {
        guard let stream = Current.stream else { return }
        self.ref.child("/songProgressTable/\(stream.streamID)").observeSingleEvent(of: .value, with: { (snapshot) in
            if Current.isHost() { return }
            
            // note that setting jamsPlayer will trigger a resync if off by > 4 seconds
            if snapshot.exists(), let updatedProgress = snapshot.value as? Double {
                jamsPlayer.position_ms = updatedProgress
            } else {
                jamsPlayer.position_ms = 0.0
            }
            
            // post event telling controller to resync
            NotificationCenter.default.post(name: Notification.Name("firebaseEvent"), object: FirebaseEvent.SetProgress)
        }) { error in print(error.localizedDescription) }
    }
    
    // deletes top song in current stream -- should only be called by host when spotify signals
    // that song ended or when host presses skip
    // then this method loads top song from list of queued songs, if any exists
    public static func popTopSong(nextSong: Models.FirebaseSong?) {
        
        // ** note that only the host touches this method **
        
        guard let stream = Current.stream else { return }
        // reset progress in any case
        self.ref.child("/songProgressTable/\(stream.streamID)").setValue(0.0)
        
        if let next = nextSong {
            self.ref.child("/streams/\(stream.streamID)/song").setValue(next.firebaseDict)
            self.ref.child("/songs/\(stream.streamID)/\(next.key)").removeValue()
        } else {
            // no songs queued
            self.ref.child("/streams/\(stream.streamID)/song").removeValue()
            ref.child("streams/\(stream.streamID)/isPlaying").setValue(false)
        }
    }
    
    private static func addTopSongChangedListener() {
        guard let stream = Current.stream else { return }
        // listen for top song changes -- includes song skips and song finishes
        let path = "/streams/\(stream.streamID)/song"
        self.ref.child(path).observe(.value, with: { (snapshot) in
            guard let stream = Current.stream else { return }
            
            if Current.isHost() && stream.song != nil {
                return
            }
            
            Current.stream!.song = Models.FirebaseSong(snapshot: snapshot)
            self.jamsPlayer.position_ms = 0.0
            self.listenForSongProgress()
            
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
            // you are the host so update path: stream/host
//            self.ref.child("/streams/\(stream.streamID)/host/\(user.spotifyID)/online").onDisconnectSetValue(false)
            
            // you are the host so pause stream playing
            self.ref.child("/streams/\(stream.streamID)/isPlaying").onDisconnectSetValue(false)
        } else {
            // you are not the host so update stream/members
//            self.ref.child("/streams/\(stream.streamID)/members/\(user.spotifyID)/online").onDisconnectSetValue(false)
        }
    }

    
    public static func setOnlineTrue() {
        return
        // update main user object
        guard let user = Current.user else { return }
        self.ref.child("/users/\(user.spotifyID)/online").setValue(true)
        Current.user!.online = true
        
        // add a presence listener when we do this because currently it's only added
        // whenever user change streams (not really guaranteed)
        self.ref.child("/users/\(user.spotifyID)/online").onDisconnectSetValue(false)

        // STREAM object update
        // before setting anything, make sure stream still exists in db
        guard let stream = Current.stream else { return }
        ref.child("/streams/\(stream.streamID)").observeSingleEvent(of: .value, with: { (snapshot) in
            if snapshot.exists(), let _ = snapshot.value as? [String: Any?] {
                if Current.isHost() {
                    self.ref.child("/streams/\(stream.streamID)/host/\(user.spotifyID)/online").setValue(true)
                } else {
                    self.ref.child("/streams/\(stream.streamID)/members/\(user.spotifyID)/online").setValue(true)
                }
            }
        })
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
        }) {error in print(error.localizedDescription)}
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
    public static func createNewStream(title: String, callback: @escaping ((Void) -> Void)) {
        let newStream = Models.FirebaseStream()
        
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
        self.ref.child("users/\(user.spotifyID)/fcmToken").setValue(fcmToken)
        guard let stream = Current.stream else { return }
        if Current.isHost() {
            self.ref.child("streams/\(stream.streamID)/host/\(user.spotifyID)/fcmToken").setValue(fcmToken)
        } else {
            self.ref.child("streams/\(stream.streamID)/members/\(user.spotifyID)/fcmToken").setValue(fcmToken)
        }
    }

    public static func fetchStream(streamID: String, callback: @escaping ((_: Models.FirebaseStream?) -> Void)) {
        self.ref.child("/streams/\(streamID)").observeSingleEvent(of: .value, with:{ (snapshot) in
            if let stream = Models.FirebaseStream(snapshot: snapshot) {
                callback(stream)
            } else {
                callback(nil)
            }
        })
    }
    
    public static func loginUser(spotifyUser: Models.SpotifyUser, callback: @escaping ((_: Bool) -> Void)) {
        ref.child("users/\(spotifyUser.spotifyID)").observeSingleEvent(of: .value, with: { (snapshot) in
            if snapshot.exists() {
                if var userDict = snapshot.value as? [String: Any?] {
                    userDict["spotifyID"] = spotifyUser.spotifyID
                    Current.user = Models.FirebaseUser(dict: userDict)
                    self.ref.child("users/\(spotifyUser.spotifyID)/online").setValue(true)
                }
            } else {
                // add user if user does not exist
                var newUserDict: [String: Any?] = ["imageURL": spotifyUser.imageURL,
                                                   "tunedInto": nil,
                                                   "online": true]
                if let username = spotifyUser.username {
                    newUserDict["username"] = username
                } else {
                    newUserDict["username"] = spotifyUser.spotifyID // use spotifyID if no spotify username
                }
                // set firebase messaging token
                let token = Messaging.messaging().fcmToken
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
                    }
                    callback(true)
                }) {error in
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
    
    public static func updateVotes(song: Models.FirebaseSong, upvoted: Bool) {
        guard let stream = Current.stream else { return }
        guard let user = Current.user else { return }
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
    }
    
    public static func addToStarredTable(user: Models.FirebaseUser) {
        guard let currUser = Current.user else { return }
        self.ref.child("/starredTable/\(currUser.spotifyID)").child(user.spotifyID).setValue(user.firebaseDict)
    }
    
    public static func removeFromStarredTable(user: Models.FirebaseUser) {
        guard let currUser = Current.user else { return }
        self.ref.child("/starredTable/\(currUser.spotifyID)").child(user.spotifyID).removeValue()
    }
    
    // Function URL: https://us-central1-juke-9fbd6.cloudfunctions.net/sendNotification
    public static func sendNotification(receiver: Models.FirebaseUser) {
        guard let user = Current.user else { return }
        let params: Parameters = [
            "sender": user.firebaseDict,
            "receiver": receiver.firebaseDict
        ]
        
        print("called sendNotification")
        Alamofire.request(Constants.kSendNotificationsURL, method: .post, parameters: params, encoding: JSONEncoding.default).responseJSON { response in
            
            print("response came back", response)
        }
    }
}
