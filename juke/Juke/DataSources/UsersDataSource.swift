//
//  UsersDataSource.swift
//  Juke
//
//  Created by Conner Smith on 9/18/17.
//  Copyright © 2017 csmith. All rights reserved.
//

import Foundation

class UsersDataSource: CustomDataSource {
    
    override var reloadEventName: String {
        get {
            return "reloadAllUsers"
        }
    }
    
    override var cellName: String {
        get {
            return "UserCell"
        }
    }
    
    init() {
        print("init")
        super.init(path: "users")
    }
    
    override func isEqual(current: CollectionItem, other: CollectionItem) -> Bool {
        return other.user.spotifyID == current.user.spotifyID
    }
    
    // comparator function used for sorting in super class
    override func comparator(first: CollectionItem, second: CollectionItem) -> Bool {
        return first.user.username < second.user.username
    }
    
    override func shouldInclude(item: CollectionItem) -> Bool {
        guard let user = Current.user else { return true }
        let included = item.user.spotifyID != user.spotifyID
        if !included || query.isEmpty {
            return included
        }
        return item.user.username.lowercased().contains(query.lowercased())
    }
    
    override func populateCell(cell: UITableViewCell, item: CollectionItem) {
        let cell = cell as! UserCell
        cell.populateCell(member: item.user)
    }
}
