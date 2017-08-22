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
    private static var songQueueDataSourceSet = false
    private static var allStreamsDataSourceSet = false
    
    // firebase ref
    private static let ref = Database.database().reference()
    
    // audio player
    private static let jamsPlayer = JamsPlayer.shared
    
    public static func addListeners() {
        addMemberJoinedListener()
        addMemberLeftListener()
        addTopSongChangedListener()
        addSongPlayStatusListener()
    }
    
    private static func addSongPlayStatusListener() {
        ref.child("streams/\(Current.stream.streamID)/isPlaying").observe(.value, with:{ (snapshot) in
            if snapshot.exists(), let isPlaying = snapshot.value as? Bool {
                Current.stream.isPlaying = isPlaying
                // post event telling controller to resync
                NotificationCenter.default.post(name: Notification.Name("firebaseEvent"), object: FirebaseEvent.ResyncStream)
            }
        }) { err in print(err.localizedDescription)}
    }
    
    private static func addMemberJoinedListener() {
        ref.child("/streams/\(Current.stream.streamID)/members").observe(.childAdded, with:{ (snapshot) in
            // update Current stream
            let member = Models.FirebaseMember(username: snapshot.key, imageURL: snapshot.value as? String)
            if member.username == Current.user.username { return }      // because this event fires once at start up with all members (including host)
            if Current.stream.members.contains(where: { (other) -> Bool in
                return member.username == other.username
            }) {
                // member already in client member list -- ignore this event
                return
            } else {
                Current.stream.members.append(member)
            }
            
            // display Whisper notification
            whisper(title: "\(snapshot.key) joined your stream!" , backgroundColor: RandomFlatColorWithShade(.light))
            
            // post event telling controller to resync
            NotificationCenter.default.post(name: Notification.Name("firebaseEvent"), object: FirebaseEvent.MemberJoined)
            
        }) { error in print(error.localizedDescription)}
    }
    
    private static func addMemberLeftListener() {
        ref.child("/streams/\(Current.stream.streamID)/members").observe(.childRemoved, with:{ (snapshot) in
            
            // update Current stream
            let member = Models.FirebaseMember(username: snapshot.key, imageURL: snapshot.value as? String)
            guard let index = Current.stream.members.index(where: { (other) -> Bool in
                return member.username == other.username
            }) else {
                return // no matching member -- don't send any alert
            }
            Current.stream.members.remove(at: index)
            
            // display Whisper notification
            whisper(title: "\(snapshot.key) left your stream" , backgroundColor: RandomFlatColorWithShade(.light))
            
            // post event telling controller to resync
            NotificationCenter.default.post(name: Notification.Name("firebaseEvent"), object: FirebaseEvent.MemberLeft)
            
            
        }) { error in print(error.localizedDescription) }
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
                if abs(jamsPlayer.position_ms - updatedProgress) <= 3000 {
                    return
                }
                jamsPlayer.position_ms = updatedProgress
            } else {
                jamsPlayer.position_ms = 0.0
            }
            jamsPlayer.resync()
            
            // post event telling controller to resync
            NotificationCenter.default.post(name: Notification.Name("firebaseEvent"), object: FirebaseEvent.SetProgress)
        }) { error in print(error.localizedDescription) }
    }
    
    // deletes top song in current stream -- should only be called by host when spotify signals
    // that song ended or when host presses skip
    // then this method loads top song from list of queued songs, if any exists
    public static func popTopSong(dataSource: FUITableViewDataSource!) {
        
        // reset progress in any case
        self.ref.child("/songProgressTable/\(Current.stream.streamID)").setValue(0.0)
        jamsPlayer.position_ms = 0.0
        
        guard let snapshot = dataSource.items.first else {
            // no songs queued
            self.ref.child("/streams/\(Current.stream.streamID)/song").removeValue()
            ref.child("streams/\(Current.stream.streamID)/isPlaying").setValue(false)
            return
        }
        
        guard let nextSong = Models.FirebaseSong(snapshot: snapshot) else {
            // error parsing next song
            self.ref.child("/streams/\(Current.stream.streamID)/song").removeValue()
            ref.child("streams/\(Current.stream.streamID)/isPlaying").setValue(false)
            return
        }
        
        // set next song
        self.ref.child("/streams/\(Current.stream.streamID)/song").setValue(nextSong.firebaseDict)
        self.ref.child("/songs/\(Current.stream.streamID)/\(snapshot.key)").removeValue()
    }
    
    private static func addTopSongChangedListener() {
        // listen for top song changes -- includes song skips and song finishes
        self.ref.child("/streams/\(Current.stream.streamID)/song").observe(.value, with:{ (snapshot) in
            Current.stream.song = Models.FirebaseSong(snapshot: snapshot)
            // resync regardless of whether song is there or not
            self.jamsPlayer.resync()
            self.listenForSongProgress() // fetch new progress
            
            // post event telling controller to resync
            NotificationCenter.default.post(name: Notification.Name("firebaseEvent"), object: FirebaseEvent.ResyncStream)
        }) { error in print(error.localizedDescription) }
    }
    
    public static func addSongQueueTableViewListener(songQueueTableView: UITableView?) -> FUITableViewDataSource? {
        guard let tableView = songQueueTableView else { return nil }
        if songQueueDataSourceSet { return nil }
        songQueueDataSourceSet = true
        // set tableview to listen to current stream
        let dataSource = tableView.bind(to: self.ref.child("/songs/\(Current.stream.streamID)"))
        { tableView, indexPath, snapshot in
            let cell = tableView.dequeueReusableCell(withIdentifier: "SongCell", for: indexPath) as! SongTableViewCell
            guard let song = Models.FirebaseSong(snapshot: snapshot) else { return cell }
            print("\n\(song.firebaseDict)\n")
            cell.populateCell(song: song)
            return cell
        }
        return dataSource
    }
    
    public static func addDiscoverStreamsTableViewListener(allStreamsTableView: UITableView?) -> FUITableViewDataSource? {
        guard let tableView = allStreamsTableView else { return nil }
        if allStreamsDataSourceSet { return nil }
        allStreamsDataSourceSet = true
        let dataSource = tableView.bind(to: FirebaseAPI.ref.child("streams")) { tableView, indexPath, snapshot in
            let cell = tableView.dequeueReusableCell(withIdentifier: "StreamCell", for: indexPath) as! StreamCell
            guard let stream = Models.FirebaseStream(snapshot: snapshot) else { return cell }
            cell.populateCell(stream: stream)
            return cell
        }
        return dataSource
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
        
        // TODO: detach listeners to the current stream
        
        let streamID = stream.streamID
        let currentStreamID = Current.user.tunedInto
        if currentStreamID != streamID || currentStreamID != Current.stream.streamID {
            ref.child("/streams/\(streamID)").observeSingleEvent(of: .value, with: { (snapshot) in
                if !snapshot.exists() { callback(false); return; }    // do nothing if this new stream doesn't exist anymore (concurrency)
                
                // resync to new stream
                Current.user.tunedInto = streamID
                Current.stream = stream
                
                // post event telling controller to resync
                self.songQueueDataSourceSet = false
                self.allStreamsDataSourceSet = false
                NotificationCenter.default.post(name: Notification.Name("firebaseEvent"), object: FirebaseEvent.SwitchedStreams)
                
                // callback provided by StreamsTableViewController to communicate success/failure
                callback(true)
                
                // write to firebase stream members lists
                let childUpdates: [String: Any?] = ["/streams/\(streamID)/members/\(Current.user.username)": Current.user.imageURL,
                                                    "/streams/\(String(describing: currentStreamID))/members/\(Current.user.username)": NSNull()]
                self.ref.updateChildValues(childUpdates)
            }) {error in print(error.localizedDescription)}
        }
    }
    
    public static func setPlayStatus(status: Bool) {
        ref.child("/streams/\(Current.stream.streamID)/isPlaying").setValue(status)
    }
    
    public static func clearStream() {
        ref.child("songs/\(Current.stream.streamID)").removeValue()
        ref.child("streams/\(Current.stream.streamID)/song").removeValue()
        ref.child("streams/\(Current.stream.streamID)/isPlaying").setValue(false)
        NotificationCenter.default.post(name: Notification.Name("firebaseEvent"), object: FirebaseEvent.ResyncStream)
    }
    
    // creates and joins empty stream with user as host
    public static func createNewStream() {
        
        // TODO: detach listeners, add new
        
        let host = Models.FirebaseMember(username: Current.user.username, imageURL: Current.user.imageURL)
        let newStream = Models.FirebaseStream(host: host)
        let childUpdates: [String: Any] = ["/streams/\(newStream.streamID)": newStream.firebaseDict,
                                           "/songs/\(newStream.streamID)": NSNull(),
                                           "/users/\(Current.user.spotifyID)/tunedInto": newStream.streamID]
        ref.updateChildValues(childUpdates)
        Current.stream = newStream
        Current.user.tunedInto = newStream.streamID
        
        // tell view controllers to resync
        songQueueDataSourceSet = false
        allStreamsDataSourceSet = false
        NotificationCenter.default.post(name: Notification.Name("firebaseEvent"), object: FirebaseEvent.SwitchedStreams)
    }
    
    public static func updateSongProgress() {
        ref.child("/songProgressTable/\(Current.stream.streamID)").setValue(jamsPlayer.position_ms)
    }
    
    public static func removeListeners() {
        // TODO
    }
    
}
