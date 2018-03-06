//
//  StreamsViewModel.swift
//  Juke
//
//  Created by Kojo Worai Osei on 3/5/18.
//  Copyright © 2018 csmith. All rights reserved.
//

import Foundation
import UIKit

enum StreamsViewModelType {
    case currentStream
    case followingStream
    case featuredStream
}

protocol StreamsViewModelItem {
    var type: StreamsViewModelType { get }
    var sectionTitle: String { get }
    var rowCount: Int { get }
}

protocol StreamsViewModelDelegate: class {
    func didFinishUpdates()
}

class StreamsViewModel: NSObject {
    var items = [StreamsViewModelItem]()
    weak var delegate: StreamsViewModelDelegate?
    
    private func getData() {
        // refresh items
        items.removeAll()
        // create streamviewmodeltypes
        let followingStreamsItem = FollowingStreamsItem(fStreams: StarredStreamsDataSource().filteredCollection)
        let featuredStreamsItem = FeaturedStreamsItem(ftrdStreams: StreamsDataSource().featuredStreams)
        let currStreamItem = CurrentStreamItem(currentStream: Current.stream!)
        
        items.append(followingStreamsItem)
        items.append(featuredStreamsItem)
        items.append(currStreamItem)
        
        delegate?.didFinishUpdates()
        
    }
}

class CurrentStreamItem: StreamsViewModelItem {
    var type: StreamsViewModelType {
        return .currentStream
    }
    
    var sectionTitle: String {
        return "Current Stream"
    }
    
    var rowCount: Int {
        return 1
    }
    
    var currStream: Models.FirebaseStream
    
    init(currentStream: Models.FirebaseStream) {
        self.currStream = currentStream
    }
}

class FollowingStreamsItem: StreamsViewModelItem {
    var type: StreamsViewModelType {
        return .followingStream
    }
    
    var sectionTitle: String {
        return "Following"
    }
    
    var rowCount: Int {
        return followingStreams.count
    }
    
    var followingStreams: [CollectionItem]
    init(fStreams: [CollectionItem]) {
        self.followingStreams = fStreams
    }
}

class FeaturedStreamsItem: StreamsViewModelItem {
    var type: StreamsViewModelType {
        return .followingStream
    }
    
    var sectionTitle: String {
        return "Featured Streams"
    }
    
    var rowCount: Int {
        return 1
    }
    
    var featuredStreams: [Models.FirebaseStream]
    init(ftrdStreams: [Models.FirebaseStream]) {
        self.featuredStreams = ftrdStreams
    }
}
