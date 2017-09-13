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

class FirebaseAPI {
    
    // to avoid calling twice
    private static var streamsTableViewSet = false
    private static var myStreamTableViewSet = false
    
    // firebase ref
    private static let ref = Database.database().reference()
    
    // audio player
    private static let jamsPlayer = JamsPlayer.shared
    
    public static func addStreamChangeListener() {
        
        
    }
    
    public static func addListeners() {
        addMemberJoinedListener()
        addMemberLeftListener()
        addTopSongChangedListener()
        addStreamChangeListener()
    }
    
    private static func addMemberJoinedListener() {
        ref.child("/streams/\(Current.stream.streamID)/members").observe(.childAdded, with:{ (snapshot) in
            // update Current stream
            Current.stream.members.append(Models.FirebaseMember(username: snapshot.key, imageURL: snapshot.value as? String))
            
            print("added: ", snapshot)
            // display Whisper notification
            let colors: [UIColor] = [.red, .green, .blue]
            whisper(title: "\(snapshot.key) joined your stream!" , backgroundColor: colors[Int(arc4random_uniform(UInt32(colors.count)))])
            
            // post event telling controller to resync
            
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
            let colors: [UIColor] = [.red, .green, .blue]
            whisper(title: "\(snapshot.key) left your stream" , backgroundColor: colors[Int(arc4random_uniform(UInt32(colors.count)))])
            
            // post event telling controller to resync
            
            
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
    
    // for all of the changes that affect stream or all streams, update Current vars then
    // post an event called resync() and in that event set the UI
    
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
        }) { error in print(error.localizedDescription) }
    }
    
    private static func topSongChangedHandler(snapshot: DataSnapshot) {
        print("** topSongChangedHandler: ", snapshot)
        if let songDict = snapshot.value as? [String: Any?], let song = Models.FirebaseSong(dict: songDict) {
            Current.stream.song = song
        }
        // resync regardless of whether song is there or not
        self.jamsPlayer.resync()
    }
    
    private static func addTopSongChangedListener() {
        // listen for top song changes -- includes song skips and song finishes
        self.ref.child("/streams/\(Current.stream.streamID)/song").observe(.value, with:{ (snapshot) in
            topSongChangedHandler(snapshot: snapshot)
        }) { error in print(error.localizedDescription) }
        
        // listen for child deleted
        self.ref.child("/streams/\(Current.stream.streamID)/song").observe(.childRemoved, with:{ (snapshot) in
            guard let currSong = Current.stream.song else { return }
            if snapshot.key == currSong.key { // ***** PROBLEM: this fires for all the song properties when a song is deleted... not super efficient
                topSongChangedHandler(snapshot: snapshot)
            }
        }) { error in print(error.localizedDescription) }
    }
    
    public static func addSongQueueTableViewListener(songQueueTableView: UITableView?) -> FUITableViewDataSource? {
        if myStreamTableViewSet { return nil }
        myStreamTableViewSet = true
        guard let tableView = songQueueTableView else { return nil }
        // set tableview to listen to current stream
        let dataSource = tableView.bind(to: self.ref.child("/songs/\(Current.stream.streamID)"))
        { tableView, indexPath, snapshot in
            let cell = tableView.dequeueReusableCell(withIdentifier: "SongCell", for: indexPath) as! SongTableViewCell
            guard let song = Models.FirebaseSong(snapshot: snapshot) else { return cell }
            //                self.songs[indexPath.row] = song
            cell.populateCell(song: song)
            return cell
        }
        return dataSource
    }
    
    public static func addDiscoverStreamsTableViewListener(allStreamsTableView: UITableView?) -> FUITableViewDataSource? {
        if streamsTableViewSet { return nil }
        streamsTableViewSet = true
        guard let tableView = allStreamsTableView else { return nil }
        let dataSource = tableView.bind(to: FirebaseAPI.ref.child("streams")) { tableView, indexPath, snapshot in
            let cell = tableView.dequeueReusableCell(withIdentifier: "StreamCell", for: indexPath) as! StreamCell
            guard let stream = Models.FirebaseStream(snapshot: snapshot) else { return cell }
            cell.populateCell(stream: stream)
            return cell
        }
        return dataSource
    }
    
    public static func removeListeners() {
        // TODO
    }
    
}
