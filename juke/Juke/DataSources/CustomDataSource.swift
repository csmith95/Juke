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

class CollectionItem {
    var user: Models.FirebaseUser!
    var stream: Models.FirebaseStream!
    var song: Models.FirebaseSong!
    
    init(snapshot: DataSnapshot) {
        self.user = Models.FirebaseUser(snapshot: snapshot)
        self.stream = Models.FirebaseStream(snapshot: snapshot)
        self.song = Models.FirebaseSong(snapshot: snapshot)
    }
    
    // sanity check
    func isValid() -> Bool {
        return user != nil || stream != nil || song != nil
    }
    
}

class CustomDataSource: NSObject, UITableViewDataSource, UITableViewDelegate {
    
    var collection: [CollectionItem] = [] // all streams
    var filteredCollection: [CollectionItem] = [] // what is displayed to user
    var query = ""
    let ref = Database.database().reference()
    
    // set in subclass because different events should trigger different tables to reload
    // we need to not assume that I am using this for a table... just give me an array and let me do what I want with it
    var reloadEventName: String {
        get {
            fatalError("Subclass should override this property")
        }
    }
    
    var cellName: String {
        get {
            fatalError("Subclass should override this property")
        }
    }
    
    var path: String!
    
    init(path: String) {
        super.init()
        
        if path.isEmpty { return } // for the SongQueueDataSource
        self.path = path
    }
    
    public func listen() {
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
    
    public func detach() {
        ref.child(path).removeAllObservers()
        objc_sync_enter(self)
        collection.removeAll()
        filteredCollection.removeAll()
        objc_sync_exit(self)
    }
    
    // thread safe, delegates work to helpers to modify collection property
    // and signal changes to view controller using post notifications
    func updateCollection(type: DataEventType, snapshot: DataSnapshot) {
        let collectionItem = CollectionItem(snapshot: snapshot)
        if !collectionItem.isValid() { return } // no fields were extracted from snapshot -- do nothing
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
        return tableView.dequeueReusableCell(withIdentifier: cellName, for: indexPath)
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        populateCell(cell: cell, item: filteredCollection[indexPath.row])
    }
    
    @available(iOS 2.0, *)
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredCollection.count
    }
    
    func triggerTableViewRefresh() {
        filteredCollection = collection.filter({ (collectionItem) -> Bool in
            return self.shouldInclude(item: collectionItem)
        })
        NotificationCenter.default.post(name: Notification.Name(reloadEventName), object: nil)
    }
    
    func sort() {
        collection.sort(by: comparator)
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        NotificationCenter.default.post(name: Notification.Name("hideKeyboard"), object: nil)
    }
    
    func handleChildAdded(collectionItem: CollectionItem) {
        if getIndex(collectionItem: collectionItem) == nil {
            collection.append(collectionItem)
            sort()
            triggerTableViewRefresh()
        }
    }
    
    func handleChildRemoved(collectionItem: CollectionItem) {
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
         //assert(false, "This method must be overridden")
        fatalError("This method must be overriden")
    }
    
    func isEqual(current: CollectionItem, other: CollectionItem) -> Bool {
        fatalError("This method must be overriden")
    }
    
    func shouldInclude(item: CollectionItem) -> Bool {
        fatalError("This method must be overriden")
    }
    
    func populateCell(cell: UITableViewCell, item: CollectionItem) {
        fatalError("This method must be overriden")
    }

}
