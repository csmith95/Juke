//
//  StarredStreamsDataSource.swift
//  Juke
//
//  Created by Kojo Worai Osei on 9/19/17.
//  Copyright © 2017 csmith. All rights reserved.
//

import Foundation
import PKHUD

class StarredStreamsDataSource: CustomDataSource {
    
    override var reloadEventName: String {
        get {
            return "reloadStarredStreams"
        }
    }
    
    override var cellName: String {
        get {
            return "StreamCell"
        }
    }
    
    init() {
        super.init(path: "streams")
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let stream = filteredCollection[indexPath.row].stream!
        FirebaseAPI.joinStream(stream: stream) { success in
            if success {
                NotificationCenter.default.post(name: Notification.Name("newStreamJoined"), object: nil)
                HUD.flash(.success, delay: 1.0)
            } else {
                HUD.flash(.error, delay: 1.0)
            }
        }
    }
    
    override func isEqual(current: CollectionItem, other: CollectionItem) -> Bool {
        return other.stream.streamID == current.stream.streamID
    }
    
    // comparator function used for sorting in super class
    override func comparator(first: CollectionItem, second: CollectionItem) -> Bool {
        let first = first.stream!
        let second = second.stream!
        
        // then sort by play status
        if first.isPlaying && !second.isPlaying { return true }
        if !first.isPlaying && second.isPlaying { return false }
        
        // then by member count
        return first.members.count > second.members.count
    }
    
    override func shouldInclude(item: CollectionItem) -> Bool {
        
        // check if there is a song
        //var included = (item.stream.song != nil)
        if (item.stream.song == nil) { return false }
        
        
        // check if this is not the same as the stream you are currently in
        if let currentStream = Current.stream {
            if (item.stream.streamID == currentStream.streamID) { return false }
        }
        
        // check if stream host is starred
        //if (!Current.isStarred(user: item.stream.host)) { return false } //|| streamHasStarredUser(item: item)
        
        // check if stream member has someone in it
        //if (!streamHasStarredUser(item: item)) { return false }
        
        if (query.isEmpty) {
            return streamHasStarredUser(item: item)
            //print("query is empty")
            //return true
        } else {
            return item.stream.host.username.lowercased().contains(query.lowercased())
        }
        
        //return true
        
        
        // check if anything is in search query
//        if !included || query.isEmpty {
//            return included
//        }
        
        
    }
    
    func streamHasStarredUser(item: CollectionItem) -> Bool {
        if (Current.isStarred(user: item.stream.host)) {
            print("host is in, returning true")
            return true
        }
        
        for user in item.stream.members {
            print("host was not in it... checking users")
            if (Current.isStarred(user: user)) {
                print("found user returning true")
                return true
            }
        }
        print("found no one, returning false")
        return false
    }
    
    override func populateCell(cell: UITableViewCell, item: CollectionItem) {
        let cell = cell as! StreamCell
        cell.populateCell(stream: item.stream)
    }
}
