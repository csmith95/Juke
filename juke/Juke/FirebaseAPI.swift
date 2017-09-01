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
        case SwitchedStreams
        case SetProgress
    }
    
    // to avoid adding listeners multiple times
    // when a view controller calls addSongQueueDataListener or 
    // addDiscoverStreamsDataListener, these are set to true
    // if user joins new stream, these are reset to false
    private static var streamMembersDataSourceSet = false
    private static var streamDeletedListenerSet = false
    
    private static var observedPaths: [String] = []
    
    // firebase ref
    private static let ref = Database.database().reference()
    
    // audio player
    private static let jamsPlayer = JamsPlayer.shared
    
    public static func addListeners() {
        addMemberJoinedListener()
        addMemberLeftListener()
        addPresenceListener()
        addTopSongChangedListener()
        addSongPlayStatusListener()
        addStreamDeletedListener()
    }
    
    // if user stream deleted because host leaves, create a new one
    private static func addStreamDeletedListener() {
        // don't add handle to list of handles for this method
        // because it will disable the tableview binding
        // for discover streams table (shit firebase cmon)
        if (streamDeletedListenerSet) { return }
        streamDeletedListenerSet = true
        ref.child("/streams").observe(.childRemoved, with:{ (snapshot) in
            if snapshot.key == Current.stream.streamID {
                self.createNewStream(removeFromCurrentStream: false)
            }
        })
    }
    
    private static func addSongPlayStatusListener() {
        let path = "streams/\(Current.stream.streamID)/isPlaying"
        ref.child(path).observe(.value, with:{ (snapshot) in
            if snapshot.exists(), let isPlaying = snapshot.value as? Bool {
                Current.stream.isPlaying = isPlaying
                self.listenForSongProgress()    // fetch updated status
                NotificationCenter.default.post(name: Notification.Name("firebaseEvent"), object: FirebaseEvent.ResyncStream)
            }
        }) { err in print(err.localizedDescription)}
        observedPaths.append(path)
    }
    
    private static func addMemberJoinedListener() {
        let path = "/streams/\(Current.stream.streamID)/members"
        ref.child(path).observe(.childAdded, with:{ (snapshot) in
            // update Current stream
            guard let member = Models.FirebaseUser(snapshot: snapshot) else { return }
            if Current.stream.members.contains(where: { (other) -> Bool in
                return member.spotifyID == other.spotifyID
            }) || Current.user.spotifyID == member.spotifyID {
                // member already in client member list -- ignore this event -- triggered when observer
                // first registered
                return
            } else {
                Current.stream.members.append(member)
            }
            
            // display Whisper notification
            whisper(title: "\(member.username) joined your stream!" , backgroundColor: RandomFlatColorWithShade(.light))
            
            // post event telling controller to resync
            NotificationCenter.default.post(name: Notification.Name("firebaseEvent"), object: FirebaseEvent.MemberJoined)
            
        }) { error in print(error.localizedDescription)}
    }
    
    private static func addMemberLeftListener() {
        let path = "/streams/\(Current.stream.streamID)/members"
        ref.child(path).observe(.childRemoved, with:{ (snapshot) in
            
            // update Current stream
            guard let member = Models.FirebaseUser(snapshot: snapshot) else { return }
            guard let index = Current.stream.members.index(where: { (other) -> Bool in
                return member.spotifyID == other.spotifyID
            }) else {
                return
            }
            if Current.user.spotifyID == member.spotifyID {
                return
            }
            Current.stream.members.remove(at: index)
            
            // display Whisper notification
            whisper(title: "\(member.username) left your stream" , backgroundColor: RandomFlatColorWithShade(.light))
            
            // post event telling controller to resync
            NotificationCenter.default.post(name: Notification.Name("firebaseEvent"), object: FirebaseEvent.MemberLeft)
            
        }) { error in print(error.localizedDescription) }
        observedPaths.append(path)
    }
    
    static var navigationController: UINavigationController?  {
        get {
            return FirebaseAPI.getNavigationController(viewController: FirebaseAPI.root)
        }
    }
    
    static var root: UIViewController? {
        get {
            return UIApplication.shared.delegate?.window??.rootViewController
        }
    }
    
    static func getNavigationController(viewController: UIViewController?) -> UINavigationController? {
        if let navigationController = viewController as? UINavigationController {
            return navigationController
        }
        
        if let tabBarViewController = viewController as? UITabBarController {
            return getNavigationController(viewController: tabBarViewController.selectedViewController)
        } else if let presentedViewController = viewController?.presentedViewController {
            return getNavigationController(viewController: presentedViewController)
        } else {
            return nil
        }
    }
    
    public static func whisper(title: String, backgroundColor: UIColor) {
        let message = Message(title: title, backgroundColor: backgroundColor)
        guard let navController = navigationController else { return }
        Whisper.show(whisper: message, to: navController, action: .show)
    }
    
    // listens once to song progress and triggers update if necessary (out of sync by > 3 seconds)
    // this is called by other classes to trigger a progress resync or get progress initially after
    // joining a new stream
    public static func listenForSongProgress() {
        self.ref.child("/songProgressTable/\(Current.stream.streamID)").observeSingleEvent(of: .value, with: { (snapshot) in
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
        
        // reset progress in any case
        self.ref.child("/songProgressTable/\(Current.stream.streamID)").setValue(0.0)
        jamsPlayer.position_ms = 0.0
        
        guard let nextSong = dataSource.getNextSong() else {
            // no songs queued
            self.ref.child("/streams/\(Current.stream.streamID)/song").removeValue()
            ref.child("streams/\(Current.stream.streamID)/isPlaying").setValue(false)
            return
        }
        
        // set next song
        self.ref.child("/streams/\(Current.stream.streamID)/song").setValue(nextSong.firebaseDict)
        self.ref.child("/songs/\(Current.stream.streamID)/\(nextSong.key)").removeValue()
    }
    
    private static func addTopSongChangedListener() {
        // listen for top song changes -- includes song skips and song finishes
        let path = "/streams/\(Current.stream.streamID)/song"
        self.ref.child(path).observe(.value, with:{ (snapshot) in
            Current.stream.song = Models.FirebaseSong(snapshot: snapshot)
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
        if Current.isHost() {
            // you are the host so update path: stream/host
            self.ref.child("/streams/\(Current.stream.streamID)/host/\(Current.user.spotifyID)/online").onDisconnectSetValue(false)
            
            // you are the host so pause stream playing
            self.ref.child("/streams/\(Current.stream.streamID)/isPlaying").onDisconnectSetValue(false)
        } else {
            // you are not the host so update stream/members
            self.ref.child("/streams/\(Current.stream.streamID)/members/\(Current.user.spotifyID)/online").onDisconnectSetValue(false)
        }
    }

    
    public static func setOnlineTrue() {
        // update main user object
        self.ref.child("/users/\(Current.user.spotifyID)/online").setValue(true)
        Current.user.online = true

        // STREAM object update
        // no need to do case where user is host because if user is host and goes offline they are no longer host
        if !Current.isHost() {
            self.ref.child("/streams/\(Current.stream.streamID)/members/\(Current.user.spotifyID)/online").setValue(true)
        } else {
            self.ref.child("/streams/\(Current.stream.streamID)/host/\(Current.user.spotifyID)/online").setValue(true)
        }
        
    }
    
    public static func queueSong(spotifySong: Models.SpotifySong) {
        let song = Models.FirebaseSong(song: spotifySong)
        self.ref.child("/streams/\(Current.stream.streamID)/song").observeSingleEvent(of: .value, with: { (snapshot) in
            if snapshot.exists() {
                // if there is already a top song right now (queue not empty), write it to the song queue
                self.ref.child("/songs/\(Current.stream.streamID)/\(song.key)").setValue(song.firebaseDict)
            } else {
                // no current song - set current song
                self.ref.child("/streams/\(Current.stream.streamID)/song").setValue(song.firebaseDict)
            }
        }) {error in print(error.localizedDescription)}
    }
    
    // called from StreamsTableViewController when user selects a new stream to join
    public static func joinStream(stream: Models.FirebaseStream, callback: @escaping ((_: Bool) -> Void)) {
        let streamID = stream.streamID
        let currentStreamID = Current.stream.streamID
        
        if currentStreamID == streamID {
            callback(false)
            return
        }
        
        ref.child("/streams/\(streamID)").observeSingleEvent(of: .value, with: { (snapshot) in
            if !snapshot.exists() { callback(false); return; }    // do nothing if this new stream doesn't exist anymore (concurrency)
            
            if Current.isHost() || Current.stream.members.isEmpty {
                self.deleteCurrentStream()  // remove observers and delete resources if host
            } else {
                removeAllObservers()   // simply remove observers if not host
            }
            
            // resync to new stream
            let childUpdates: [String: Any] = ["/streams/\(streamID)/members/\(Current.user.spotifyID)": Current.user.firebaseDict,
                                                "/streams/\(currentStreamID)/members/\(Current.user.spotifyID)": NSNull(),
                                                "/users/\(Current.user.spotifyID)/tunedInto": streamID]
            self.ref.updateChildValues(childUpdates)
            
            // sync local stream/user info with what was just written to the db above
            Current.user.tunedInto = streamID
            Current.stream = stream
            Current.stream.members.append(Current.user)
            
            self.ref.cancelDisconnectOperations { (err, dbref) in
                // re-add listeners
                print("cancelled earlier disconnect and adding new listeners")
                self.addListeners()
            }
            
            
            // callback provided by StreamsTableViewController to communicate success/failure
            callback(true)
            
            // post event telling controller to resync
            NotificationCenter.default.post(name: Notification.Name("firebaseEvent"), object: FirebaseEvent.SwitchedStreams)
        }) {error in print(error.localizedDescription)}
    }
    
    public static func setPlayStatus(status: Bool) {
        ref.child("/streams/\(Current.stream.streamID)/isPlaying").setValue(status)
    }
    
    // clears current song queue
    public static func clearStream() {
        let childUpdates: [String: Any] = ["songs/\(Current.stream.streamID)": NSNull(),
                            "streams/\(Current.stream.streamID)/song": NSNull(),
                            "streams/\(Current.stream.streamID)/isPlaying": false,
                            "songProgressTable/\(Current.stream.streamID)": 0.0]
        jamsPlayer.position_ms = 0.0
        self.ref.updateChildValues(childUpdates)
        NotificationCenter.default.post(name: Notification.Name("firebaseEvent"), object: FirebaseEvent.ResyncStream)
    }
    
    private static func deleteCurrentStream() {
        // detach listeners to current stream -- new ones are added
        // at the end of this code chunk
        removeAllObservers()
        
        // delete current stream and associated resources
        let currentStreamID = Current.stream.streamID
        self.ref.child("/streams/\(currentStreamID)").removeValue()
        self.ref.child("/songs/\(currentStreamID)").removeValue()
        self.ref.child("/songProgressTable/\(currentStreamID)").removeValue()
        
        self.ref.cancelDisconnectOperations { (err, dbref) in
            // re-add listeners
            print("cancelled earlier disconnect and adding new listeners")
            self.addListeners()
        }
        
    }
    
    // creates and joins empty stream with user
    // this boolean is false in login view controller because we don't want to try to remove
    // user from a stream that doesn't exist -- it will crash (Current.stream is a FirebaseStream!)
    // this method can be used to go from no stream --> new stream or
    // current stream --> new stream. set bool to true for latter case
    public static func createNewStream(removeFromCurrentStream: Bool) {
        
        removeAllObservers()
        
        let newStream = Models.FirebaseStream()
        let childUpdates: [String: Any] = ["streams/\(newStream.streamID)": newStream.firebaseDict,
                                           "users/\(Current.user.spotifyID)/tunedInto": newStream.streamID]
        if removeFromCurrentStream {
            ref.child("streams/\(Current.stream.streamID)/members/\(Current.user.spotifyID)").removeValue()
        }
        Current.stream = newStream
        Current.user.tunedInto = newStream.streamID
        
        ref.updateChildValues(childUpdates)
        jamsPlayer.position_ms = 0.0
        
        // tell view controllers to resync
        self.ref.cancelDisconnectOperations { (err, dbref) in
            // re-add listeners
            print("cancelled earlier disconnect and adding new listeners")
            self.addListeners()
        }
        
        NotificationCenter.default.post(name: Notification.Name("firebaseEvent"), object: FirebaseEvent.SwitchedStreams)
    }
    
    public static func updateSongProgress(progress: Double) {
        ref.child("/songProgressTable/\(Current.stream.streamID)").setValue(progress)
    }
    
    public static func addStreamMembersTableViewListener(streamMembersTableView: UITableView?) -> FUITableViewDataSource? {
        guard let tableView = streamMembersTableView else { return nil }
        let dataSource = tableView.bind(to: FirebaseAPI.ref.child("streams/\(Current.stream.streamID)/members")) { tableView, indexPath, snapshot in
            let cell = tableView.dequeueReusableCell(withIdentifier: "StreamMemberCell", for: indexPath) as! StreamMemberCell
            guard let member = Models.FirebaseUser(snapshot: snapshot) else { return cell }
            cell.populateMemberCell(member: member)
            return cell
        }
        return dataSource
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
        if Current.isHost() {
            self.ref.child("streams/\(Current.stream.streamID)/host/\(Current.user.spotifyID)/fcmToken").setValue(fcmToken)
        } else {
            self.ref.child("streams/\(Current.stream.streamID)/members/\(Current.user.spotifyID)/fcmToken").setValue(fcmToken)
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
    
    
    public static func updateVotes(song: Models.FirebaseSong, upvoted: Bool) {
        if upvoted {
            self.ref.child("/songs/\(Current.stream.streamID)/\(song.key)/upvoters/\(Current.user.spotifyID)").setValue(true)
        } else {
            self.ref.child("/songs/\(Current.stream.streamID)/\(song.key)/upvoters/\(Current.user.spotifyID)").removeValue()
        }
        self.ref.child("/songs/\(Current.stream.streamID)/\(song.key)/votes").runTransactionBlock({ (data) -> TransactionResult in
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
        Alamofire.request(ServerConstants.kSendNotificationsURL, method: .post, parameters: params, encoding: JSONEncoding.default).responseJSON { response in
            
            print("response came back", response)
        }
    }
}
