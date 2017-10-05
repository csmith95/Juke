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
        guard let stream = Current.stream else {
            ref.child("/songs/\(observedStreamID)").removeAllObservers()
            filteredCollection.removeAll()
            collection.removeAll()
            return
        }
        if stream.streamID == observedStreamID { return } // don't set observer for same stream twice
        
        objc_sync_enter(self)
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
        objc_sync_exit(self)
    }
    
    override func isEqual(current: CollectionItem, other: CollectionItem) -> Bool {
        return other.song.key == current.song.key
    }
    
    // comparator function used for sorting in super class
    override func comparator(first: CollectionItem, second: CollectionItem) -> Bool {
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
        objc_sync_enter(self)
        let topSong = filteredCollection.first?.song
        filteredCollection.remove(at: 0)
        objc_sync_exit(self)
        return topSong
    }
    
}
