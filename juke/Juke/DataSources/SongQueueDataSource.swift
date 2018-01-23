//
//  SongQueueDataSource.swift
//  Juke
//
//  Created by Conner Smith on 9/18/17.
//  Copyright © 2017 csmith. All rights reserved.
//

import Foundation

class SongQueueDataSource: CustomDataSource {
    
    private var observedStreamID = ""
    
    override var reloadEventName: String {
        get {
            return "reloadSongs"
        }
    }
    
    override var cellName: String {
        get {
            return "SongCell"
        }
    }
    
    init() {
        super.init(path: "")
    }
    
    // this should be called whenever user changes streams
    // or just whenever the MyStreamController view will appear
    public func setObservedStream() {
        objc_sync_enter(self)
        defer  { objc_sync_exit(self) }
        guard let stream = Current.stream else {
            ref.child("/songs/\(observedStreamID)").removeAllObservers()
            filteredCollection.removeAll()
            collection.removeAll()
            return
        }
        if stream.streamID == observedStreamID { return } // don't set observer for same stream twice
        
        // remove old observer
        ref.child("/songs/\(observedStreamID)").removeAllObservers()
        observedStreamID = stream.streamID
        filteredCollection.removeAll()
        collection.removeAll()
        
        let path = "/songs/\(observedStreamID)"
        // add listeners to detect song queue changes
        ref.child(path).observe(.childChanged, with: { (snapshot) in
            super.updateCollection(type: .childChanged, snapshot: snapshot)
        })
        
        ref.child(path).observe(.childAdded, with: { (snapshot) in
            super.updateCollection(type: .childAdded, snapshot: snapshot)
        })
        
        ref.child(path).observe(.childRemoved, with: { (snapshot) in
            super.updateCollection(type: .childRemoved, snapshot: snapshot)
        })
        
        // handles bug in build 5 bugs in which new qeueue is empty except for top song when
        // new stream is joined
        triggerTableViewRefresh()
    }
    
    override func isEqual(current: CollectionItem, other: CollectionItem) -> Bool {
        return other.song.key == current.song.key
    }
    
    override func sort() {
        if let stream = Current.stream {
            if stream.isFeatured ?? false {
                return // don't sort if featured stream
            }
        }
        super.sort()
    }
    
    // comparator function used for sorting in super class
    override func comparator(first: CollectionItem, second: CollectionItem) -> Bool {
        
        if first.song.upvoters.count != second.song.upvoters.count {
            return first.song.upvoters.count > second.song.upvoters.count
        }
        // same # of votes. use timestamp to sort
        if let time1 = first.song.timestamp, let time2 = second.song.timestamp {
            return time1 < time2
        }
        
        // user is running a version that doesn't have timestamps -- just resort to the
        // vote count (this will be super weird for people running different versions...)
        return first.song.upvoters.count > second.song.upvoters.count
    }
    
    override func shouldInclude(item: CollectionItem) -> Bool {
        return true // don't filter out any queued songs
    }
    
   override func populateCell(cell: UITableViewCell, item: CollectionItem) {
        let cell = cell as! SongTableViewCell
        cell.populateCell(song: item.song)
    }
    
    public func getNextSong() -> Models.FirebaseSong? {
        // note only host calls this method
        objc_sync_enter(self)
        let topSong = filteredCollection.first?.song
        if topSong != nil {
            filteredCollection.remove(at: 0)
        }
//        triggerTableViewRefresh()   // so it's very responsive for host
        objc_sync_exit(self)
        return topSong
    }
    
}
