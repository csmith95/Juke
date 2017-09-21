//
//  StarredUsersDataSource.swift
//  Juke
//
//  Created by Conner Smith on 9/18/17.
//  Copyright © 2017 csmith. All rights reserved.
//

import Foundation

class StarredUsersDataSource: CustomDataSource {
    
    override var reloadEventName: String {
        get {
            return "reloadStarredUsers"
        }
    }
    
    override var cellName: String {
        get {
            return "StarredUserCell"
        }
    }
    
    init() {
        super.init(path: "starredTable/\(Current.user!.spotifyID)")
    }
    
    override func isEqual(current: CollectionItem, other: CollectionItem) -> Bool {
        return other.user.spotifyID == current.user.spotifyID
    }
    
    // comparator function used for sorting in super class
    override func comparator(first: CollectionItem, second: CollectionItem) -> Bool {
        return first.user.username < second.user.username
    }
    
    override func shouldInclude(item: CollectionItem) -> Bool {
        if query.isEmpty {
            return true
        }
        return item.user.username.lowercased().contains(query.lowercased())
    }
    
    override func populateCell(cell: UITableViewCell, item: CollectionItem) {
        let cell = cell as! StarredUserCell
        cell.populateCell(member: item.user)
    }
    
    override func handleChildAdded(collectionItem: CollectionItem) {
        if collectionItem.user != nil {
            Current.addStarredUser(user: collectionItem.user)
        }
        super.handleChildAdded(collectionItem: collectionItem)
    }
    
    override func handleChildRemoved(collectionItem: CollectionItem) {
        if collectionItem.user != nil {
            Current.removeStarredUser(user: collectionItem.user)
        }
        super.handleChildRemoved(collectionItem: collectionItem)
    }
    
}
