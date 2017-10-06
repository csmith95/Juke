//
//  StreamsDataSource.swift
//  Juke
//
//  Created by Conner Smith on 9/18/17.
//  Copyright © 2017 csmith. All rights reserved.
//

import Foundation

class StreamsDataSource: CustomDataSource {
    
    override var reloadEventName: String {
        get {
            return "reloadStreams"
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
        objc_sync_enter(self)
        let stream = filteredCollection[indexPath.row].stream!
        let object = ["stream": stream]
        NotificationCenter.default.post(name: Notification.Name("newStreamSelected"), object: object)
        objc_sync_exit(self)
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
        // add if you are starred by the current user
        var included = (item.stream.song != nil)
        if let currentStream = Current.stream {
            included = (included && item.stream.streamID != currentStream.streamID)
        }
        
        if !included || query.isEmpty {
            return included
        }
        
        return item.stream.host.username.lowercased().contains(query.lowercased())
    }
    
    override func populateCell(cell: UITableViewCell, item: CollectionItem) {
        let cell = cell as! StreamCell
        cell.populateCell(stream: item.stream)
    }
}
