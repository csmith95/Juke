//
//  StreamsDataSource.swift
//  Juke
//
//  Created by Conner Smith on 9/18/17.
//  Copyright © 2017 csmith. All rights reserved.
//

import Foundation
import PKHUD

class StreamsDataSource: CustomDataSource {
    
    override var reloadEventName: String {
        get {
            return "reloadStreams"
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
        var included = (item.stream.song != nil)
        if let currentStream = Current.stream {
            included = (included && item.stream.streamID != currentStream.streamID)
        }
        if !included || query.isEmpty {
            return included
        }
        return item.stream.host.username.lowercased().contains(query.lowercased())
    }
    
    override func populateCell(tableView: UITableView, indexPath: IndexPath, item: CollectionItem) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "StreamCell", for: indexPath) as! StreamCell
        cell.populateCell(stream: self.filteredCollection[indexPath.row].stream)
        return cell
    }
}
