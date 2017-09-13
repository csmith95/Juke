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
    
    enum FirebaseEvent {
        case MemberJoined
        case MemberLeft
        case ResyncStream
        case LeaveStream
        case SetProgress
    }
    
    private static var observedPaths: [String] = []
    
    // firebase ref
    private static let ref = Database.database().reference()
    
    // audio player
    private static let jamsPlayer = JamsPlayer.shared
    
    public static func addListeners() {
        addPresenceListener()
        guard Current.stream != nil else { return }
        addMemberLeftListener()
        addMemberJoinedListener()
        addTopSongChangedListener()
        addSongPlayStatusListener()
        addStreamDeletedListener()
    }
    
    private static func addStreamDeletedListener() {
        let path = "/streams"
        ref.child("/streams").observe(.childRemoved, with:{ (snapshot) in
            guard let stream = Current.stream else { return }
            if snapshot.key == stream.streamID {    // if deleted stream is my stream
                removeAllObservers()
                NotificationCenter.default.post(name: Notification.Name("firebaseEvent"), object: FirebaseEvent.LeaveStream)
                // display Whisper notification
                whisper(title: "\(stream.host.username) deleted \(stream.title) stream)" , backgroundColor: FlatPink())
            }
        })
        observedPaths.append(path)
    }
    
    private static func addSongPlayStatusListener() {
        let path = "streams/\(Current.stream!.streamID)/isPlaying"
        ref.child(path).observe(.value, with:{ (snapshot) in
            if snapshot.exists(), let isPlaying = snapshot.value as? Bool {
                Current.stream!.isPlaying = isPlaying
                self.listenForSongProgress()    // fetch updated status
                NotificationCenter.default.post(name: Notification.Name("firebaseEvent"), object: FirebaseEvent.ResyncStream)
            }
        }) { err in print(err.localizedDescription)}
        observedPaths.append(path)
    }
    
    private static func addMemberJoinedListener() {
        let path = "/streams/\(Current.stream!.streamID)/members"
        ref.child(path).observe(.childAdded, with:{ (snapshot) in
            // update Current stream
            guard var stream = Current.stream else { return }
            guard let member = Models.FirebaseUser(snapshot: snapshot) else { return }
            if stream.members.contains(where: { (other) -> Bool in
                return member.spotifyID == other.spotifyID
            }) || Current.user.spotifyID == member.spotifyID {
                // member already in client member list -- ignore this event -- triggered when observer
                // first registered
                return
            } else {
                stream.members.append(member)
            }
            
            // display Whisper notification
            whisper(title: "\(member.username) joined your stream!" , backgroundColor: FlatPink())
            
            // post event telling controller to resync
            NotificationCenter.default.post(name: Notification.Name("firebaseEvent"), object: FirebaseEvent.MemberJoined)
            
        }) { error in print(error.localizedDescription)}
    }
    
    private static func addMemberLeftListener() {
        let path = "/streams/\(Current.stream!.streamID)/members"
        ref.child(path).observe(.childRemoved, with:{ (snapshot) in
            
            // update Current stream
            guard let member = Models.FirebaseUser(snapshot: snapshot) else { return }
            guard let index = Current.stream!.members.index(where: { (other) -> Bool in
                return member.spotifyID == other.spotifyID
            }) else {
                return
            }
            if Current.user.spotifyID == member.spotifyID {
                return
            }
            Current.stream!.members.remove(at: index)
            
            // display Whisper notification
            whisper(title: "\(member.username) left your stream" , backgroundColor: FlatPink())
            
            // post event telling controller to resync
            NotificationCenter.default.post(name: Notification.Name("firebaseEvent"), object: FirebaseEvent.MemberLeft)
            
        }) { error in print(error.localizedDescription) }
        observedPaths.append(path)
    }
    
    public static func whisper(title: String, backgroundColor: UIColor) {
        let murmur = Murmur(title: title, backgroundColor: backgroundColor, titleColor: FlatWhite(), font: UIFont.boldSystemFont(ofSize: 14))
        Whisper.show(whistle: murmur, action: .show(1.5))
    }
    
    // listens once to song progress and triggers update if necessary (out of sync by > 3 seconds)
    // this is called by other classes to trigger a progress resync or get progress initially after
    // joining a new stream
    public static func listenForSongProgress() {
        guard let stream = Current.stream else { return }
        self.ref.child("/songProgressTable/\(stream.streamID)").observeSingleEvent(of: .value, with: { (snapshot) in
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
    public static func popTopSong(dataSource: SongQueueDataSource) {
        guard let stream = Current.stream else { return }
        // reset progress in any case
        self.ref.child("/songProgressTable/\(stream.streamID)").setValue(0.0)
        jamsPlayer.position_ms = 0.0
        
        guard let nextSong = dataSource.getNextSong() else {
            // no songs queued
            self.ref.child("/streams/\(stream.streamID)/song").removeValue()
            ref.child("streams/\(stream.streamID)/isPlaying").setValue(false)
            return
        }
        
        // set next song
        self.ref.child("/streams/\(stream.streamID)/song").setValue(nextSong.firebaseDict)
        self.ref.child("/songs/\(stream.streamID)/\(nextSong.key)").removeValue()
    }
    
    private static func addTopSongChangedListener() {
        guard var stream = Current.stream else { return }
        // listen for top song changes -- includes song skips and song finishes
        let path = "/streams/\(stream.streamID)/song"
        self.ref.child(path).observe(.value, with:{ (snapshot) in
            stream.song = Models.FirebaseSong(snapshot: snapshot)
            jamsPlayer.position_ms = 0.0
            // post event telling controller to resync
            NotificationCenter.default.post(name: Notification.Name("firebaseEvent"), object: FirebaseEvent.ResyncStream)
        }) { error in print(error.localizedDescription) }
        observedPaths.append(path)
    }
    
    public static func addPresenceListener() {
        // update main user object
        self.ref.child("/users/\(Current.user.spotifyID)/online").onDisconnectSetValue(false)
        
        // STREAM object updates
        guard let stream = Current.stream else { return }
        if Current.isHost() {
            // you are the host so update path: stream/host
            self.ref.child("/streams/\(stream.streamID)/host/\(Current.user.spotifyID)/online").onDisconnectSetValue(false)
            
            // you are the host so pause stream playing
            self.ref.child("/streams/\(stream.streamID)/isPlaying").onDisconnectSetValue(false)
        } else {
            // you are not the host so update stream/members
            self.ref.child("/streams/\(stream.streamID)/members/\(Current.user.spotifyID)/online").onDisconnectSetValue(false)
        }
    }

    
    public static func setOnlineTrue() {
        // update main user object
        self.ref.child("/users/\(Current.user.spotifyID)/online").setValue(true)
        Current.user.online = true

        // STREAM object update
        guard let stream = Current.stream else { return }
        if !Current.isHost() {
            self.ref.child("/streams/\(stream.streamID)/members/\(Current.user.spotifyID)/online").setValue(true)
        } else {
            self.ref.child("/streams/\(stream.streamID)/host/\(Current.user.spotifyID)/online").setValue(true)
        }
        
    }
    
    public static func queueSong(spotifySong: Models.SpotifySong) {
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
    
    // called from StreamsTableViewController when user selects a new stream to join
    public static func joinStream(stream: Models.FirebaseStream, callback: @escaping ((_: Bool) -> Void)) {
        let streamID = stream.streamID
        
        if let currentStreamID = Current.stream?.streamID {
            if currentStreamID == streamID {    // just to be sure user can never join same stream twice
                callback(false)
                return
            }
        }
        
        ref.child("/streams/\(streamID)").observeSingleEvent(of: .value, with: { (snapshot) in
            if !snapshot.exists() { callback(false); return; }    // do nothing if this new stream doesn't exist anymore (concurrency)
            
            leaveCurrentStream()
            
            // resync to new stream
            let childUpdates: [String: Any] = ["/streams/\(streamID)/members/\(Current.user.spotifyID)": Current.user.firebaseDict,
                                                "/users/\(Current.user.spotifyID)/tunedInto": streamID]
            self.ref.updateChildValues(childUpdates)
            
            // sync local stream/user info with what was just written to the db above
            Current.user.tunedInto = streamID
            Current.stream = stream
            Current.stream!.members.append(Current.user)
            jamsPlayer.position_ms = 0.0
            
            self.ref.cancelDisconnectOperations { (err, dbref) in
                // re-add listeners
                print("cancelled earlier disconnect and adding new listeners")
                self.addListeners()
            }
            
            
            // callback provided by StreamsTableViewController to communicate success/failure
            callback(true)
        }) {error in print(error.localizedDescription)}
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
    
    
    private static func leaveCurrentStream() {
        removeAllObservers()
        if let currentStreamID = Current.stream?.streamID {
            if Current.isHost() {
                deleteCurrentStream()  // delete resources if host
            } else {
                ref.child("/streams/\(currentStreamID)/members/\(Current.user.spotifyID)").removeValue()    // remove self from members list
            }
        }
    }
    
    private static func deleteCurrentStream() {
        // delete current stream and associated resources
        guard let currentStreamID = Current.stream?.streamID else { return }
        self.ref.child("/streams/\(currentStreamID)").removeValue()
        self.ref.child("/songs/\(currentStreamID)").removeValue()
        self.ref.child("/songProgressTable/\(currentStreamID)").removeValue()
    }
    
    // creates and joins empty stream with user as host. leaves current stream if any
    public static func createNewStream(title: String, callback: @escaping ((Void) -> Void)) {
        leaveCurrentStream()
        
        let newStream = Models.FirebaseStream(title: title)
        
        // update firebase
        let childUpdates: [String: Any] = ["streams/\(newStream.streamID)": newStream.firebaseDict,
                                           "users/\(Current.user.spotifyID)/tunedInto": newStream.streamID]
        ref.updateChildValues(childUpdates)
        
        // update global vars on device
        Current.stream = newStream
        Current.user.tunedInto = newStream.streamID
        jamsPlayer.position_ms = 0.0
        
        // tell view controllers to resync
        self.ref.cancelDisconnectOperations { (err, dbref) in
            // re-add listeners
            print("cancelled earlier disconnect and adding new listeners")
            self.addListeners()
        }
        callback()
    }
    
    public static func updateSongProgress(progress: Double) {
        guard let stream = Current.stream else { return }
        ref.child("/songProgressTable/\(stream.streamID)").setValue(progress)
    }
    
    // smh since firebase removeAllObservers() doesn't do what you think it does, need
    // to iterate through list
    // note that removeObserverWithpath is shit and doesn't work
    private static func removeAllObservers() {
        for path in self.observedPaths {
            self.ref.child(path).removeAllObservers()
        }
        observedPaths.removeAll()
    }

    public static func setfcmtoken() {
        let fcmToken = Messaging.messaging().fcmToken
        print("FCMToken", fcmToken!)
        Current.user.fcmToken = fcmToken
        self.ref.child("users/\(Current.user.spotifyID)/fcmToken").setValue(fcmToken)
        guard let stream = Current.stream else { return }
        if Current.isHost() {
            self.ref.child("streams/\(stream.streamID)/host/\(Current.user.spotifyID)/fcmToken").setValue(fcmToken)
        } else {
            self.ref.child("streams/\(stream.streamID)/members/\(Current.user.spotifyID)/fcmToken").setValue(fcmToken)
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
                print("FCM token: \(token ?? "")")
                newUserDict["fcmToken"] = token
                // write to firebase DB
                self.ref.child("users/\(spotifyUser.spotifyID)").setValue(newUserDict)
                newUserDict["spotifyID"] = spotifyUser.spotifyID
                Current.user = Models.FirebaseUser(dict: newUserDict)
            }
            
            // now that current user is set, try to fetch stream
            if let tunedInto = Current.user.tunedInto {
                self.ref.child("streams/\(tunedInto)").observeSingleEvent(of: .value, with : { (snapshot) in
                    if let stream = Models.FirebaseStream(snapshot: snapshot) {
                        Current.stream = stream
                        FirebaseAPI.addListeners()
                    }
                    callback(true)
                }) {error in
                    print(error.localizedDescription)
                    callback(false)
                }
            }
            
        }) {(error) in
            print(error.localizedDescription)
            callback(false)
        }
    }
    
    public static func updateVotes(song: Models.FirebaseSong, upvoted: Bool) {
        guard let stream = Current.stream else { return }
        if upvoted {
            self.ref.child("/songs/\(stream.streamID)/\(song.key)/upvoters/\(Current.user.spotifyID)").setValue(true)
        } else {
            self.ref.child("/songs/\(stream.streamID)/\(song.key)/upvoters/\(Current.user.spotifyID)").removeValue()
        }
        self.ref.child("/songs/\(stream.streamID)/\(song.key)/votes").runTransactionBlock({ (data) -> TransactionResult in
            if let numVotes = data.value as? Int {
                data.value = upvoted ? numVotes+1 : numVotes-1
            }
            return TransactionResult.success(withValue: data)
        }) { (error, committed, snapshot) in
            if let error = error {
                print(error.localizedDescription)
            }
        }
    }
    
    // Function URL: https://us-central1-juke-9fbd6.cloudfunctions.net/sendNotification
    public static func sendNotification(receiver: Models.FirebaseUser) {
        let params: Parameters = [
            "sender": Current.user.firebaseDict,
            "receiver": receiver.firebaseDict
        ]
        
        print("called sendNotification")
        Alamofire.request(Constants.kSendNotificationsURL, method: .post, parameters: params, encoding: JSONEncoding.default).responseJSON { response in
            
            print("response came back", response)
        }
    }
}
