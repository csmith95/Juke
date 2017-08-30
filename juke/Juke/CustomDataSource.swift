//
//  CustomDataSource.swift
//  Juke
//
//  Created by Conner Smith on 8/29/17.
//  Copyright © 2017 csmith. All rights reserved.
//

import Foundation
import Firebase
import FirebaseDatabaseUI
import PKHUD

class CollectionItem {
    var friend: Models.FirebaseUser!
    var stream: Models.FirebaseStream!
    var song: Models.FirebaseSong!
    
    init(snapshot: DataSnapshot) {
        self.friend = Models.FirebaseUser(snapshot: snapshot)
        self.stream = Models.FirebaseStream(snapshot: snapshot)
        self.song = Models.FirebaseSong(snapshot: snapshot)
    }
    
}

class CustomDataSource: NSObject, UITableViewDataSource, UITableViewDelegate {
    
    private var collection: [CollectionItem] = [] // all streams
    var filteredCollection: [CollectionItem] = [] // what is displayed to user
    var query = ""
    private let ref = Database.database().reference()
    
    init(path: String) {
        super.init()
        
        // add listeners to detect db changes
        ref.child(path).observe(.childChanged, with: { (snapshot) in
            self.updateCollection(type: .childChanged, snapshot: snapshot)
        })
        
        ref.child(path).observe(.childAdded, with: { (snapshot) in
            self.updateCollection(type: .childAdded, snapshot: snapshot)
        })
        
        ref.child(path).observe(.childRemoved, with: { (snapshot) in
            self.updateCollection(type: .childRemoved, snapshot: snapshot)
        })
    }
    
    // thread safe, delegates work to helpers to modify collection property
    // and signal changes to view controller using post notifications
    private func updateCollection(type: DataEventType, snapshot: DataSnapshot) {
        let collectionItem = CollectionItem(snapshot: snapshot)
        objc_sync_enter(self)
        switch (type) {
        case .childAdded:
            handleChildAdded(collectionItem: collectionItem)
            break
        case .childRemoved:
            handleChildRemoved(collectionItem: collectionItem)
            break
        case .childChanged:
            handleChildChanged(collectionItem: collectionItem)
            break
        default:
            print("unrecognized DataEventType")
        }
        objc_sync_exit(self)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return populateCell(tableView: tableView, indexPath: indexPath, item: filteredCollection[indexPath.row])
    }
    
    @available(iOS 2.0, *)
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredCollection.count
    }
    
    private func triggerTableViewRefresh() {
        filteredCollection = collection.filter({ (collectionItem) -> Bool in
            return self.shouldInclude(item: collectionItem)
        })

        NotificationCenter.default.post(name: Notification.Name("reloadCollection"), object: nil)
    }
    
    private func sort() {
        collection.sort(by: comparator)
    }
    
    private func handleChildAdded(collectionItem: CollectionItem) {
        if getIndex(collectionItem: collectionItem) == nil {
            collection.append(collectionItem)
            sort()
            triggerTableViewRefresh()
        }
    }
    
    private func handleChildRemoved(collectionItem: CollectionItem) {
        guard let index = getIndex(collectionItem: collectionItem) else { return }
        collection.remove(at: index.row)
        triggerTableViewRefresh()
    }
    
    private func handleChildChanged(collectionItem: CollectionItem) {
        guard let currIndex = getIndex(collectionItem: collectionItem) else { return }
        collection[currIndex.row] = collectionItem // update collection with new data
        sort()
        triggerTableViewRefresh()
    }
    
    private func getIndex(collectionItem: CollectionItem) -> IndexPath? {
        guard let index = collection.index(where: { (other) -> Bool in
            return self.isEqual(current: collectionItem, other: other)
        }) else { return nil }
        return IndexPath(row: index, section: 0)
    }
    
    private func findNewIndex(collectionItem: CollectionItem) -> IndexPath {
        for index in 0..<collection.count {
            if isEqual(current: collectionItem, other: collection[index]) { continue } // don't look at current stream
            if comparator(first: collectionItem, second: collectionItem) {
                return IndexPath(row: index, section: 0)
            }
        }
        return IndexPath(row: collection.count-1, section: 0)
    }
    
    public func searchBy(query: String) {
        self.query = query
        triggerTableViewRefresh()
    }
    
    // *** Methods below here must be implemented in subclasses ***
    // also note they're all threadsafe because they're called 
    // from inside updateCollection, where the data source object
    // itself is locked
    
    // returns true iff first comes before second
    func comparator(first: CollectionItem, second: CollectionItem) -> Bool {
         assert(false, "This method must be overridden")
    }
    
    func isEqual(current: CollectionItem, other: CollectionItem) -> Bool {
        assert(false, "This method must be overridden")
    }
    
    func shouldInclude(item: CollectionItem) -> Bool {
        assert(false, "This method must be overridden")
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        assert(false, "This method must be overridden")
    }
    
    func populateCell(tableView: UITableView, indexPath: IndexPath, item: CollectionItem) -> UITableViewCell {
        assert(false, "This method must be overridden")
    }
}

class StreamsDataSource: CustomDataSource {
    
    init() {
       super.init(path: "streams")
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let stream = filteredCollection[indexPath.row].stream!
        HUD.show(.progress)
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
        let included = item.stream.streamID != Current.stream.streamID && item.stream.song != nil
        if !included || query.isEmpty {
            return included
        }
        return item.stream.host.username.contains(query)
    }
    
    override func populateCell(tableView: UITableView, indexPath: IndexPath, item: CollectionItem) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "StreamCell", for: indexPath) as! StreamCell
        cell.populateCell(stream: self.filteredCollection[indexPath.row].stream)
        return cell
    }
}


class FriendsDataSource: CustomDataSource {
    init() {
        super.init(path: "users")
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // TODO
        print("nothing")
    }
    
    override func isEqual(current: CollectionItem, other: CollectionItem) -> Bool {
        return other.friend.spotifyID == current.friend.spotifyID
    }
    
    // comparator function used for sorting in super class
    override func comparator(first: CollectionItem, second: CollectionItem) -> Bool {
        return first.friend.username < second.friend.username
    }
    
    override func shouldInclude(item: CollectionItem) -> Bool {
        let included = item.friend.spotifyID != Current.user.spotifyID
        if !included || query.isEmpty {
            return included
        }
        return item.friend.username.contains(query)
    }
    
    override func populateCell(tableView: UITableView, indexPath: IndexPath, item: CollectionItem) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "FriendCell", for: indexPath) as! FriendCell
        cell.populateCell(member: self.filteredCollection[indexPath.row].friend)
        return cell
    }
}
