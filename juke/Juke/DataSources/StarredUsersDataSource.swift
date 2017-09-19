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
    
    override func populateCell(tableView: UITableView, indexPath: IndexPath, item: CollectionItem) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "StarredUserCell", for: indexPath) as! StarredUserCell
        cell.populateCell(member: self.filteredCollection[indexPath.row].user)
        return cell
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
