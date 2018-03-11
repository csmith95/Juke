//
//  StreamsViewModel.swift
//  Juke
//
//  Created by Kojo Worai Osei on 3/5/18.
//  Copyright © 2018 csmith. All rights reserved.
//

import Foundation
import UIKit
import Firebase

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
    var featuredStreams = [Models.FirebaseStream]()
    var followingStreams = [Models.FirebaseStream]()
    
    func parseData() {
        // refresh items
        items.removeAll()
        
        // create streamviewmodeltypes
        let followingStreamsItem = FollowingStreamsItem(fStreams: self.followingStreams)
        let featuredStreamsItem = FeaturedStreamsItem(ftrdStreams: self.featuredStreams)
        let currStreamItem = CurrentStreamItem(currentStream: Current.stream!)
        
        items.append(currStreamItem)
        items.append(followingStreamsItem)
        items.append(featuredStreamsItem)
        
        print("FOLLOWING STREAMS ITEMS", followingStreamsItem.followingStreams)
        print("featuredstreamsitem", featuredStreamsItem.featuredStreams)
        print("currstreamsitem", currStreamItem.currStream)
        delegate?.didFinishUpdates()
        
    }
    
    func loadData() {
        FirebaseAPI.streamsListener { (streams) in
            let enumerator = streams.children
            while let stream = enumerator.nextObject() as? DataSnapshot {
                let FIRStream = Models.FirebaseStream(snapshot: stream)
                if (FIRStream?.isFeatured)! { self.featuredStreams.append(FIRStream!) }
                if self.streamHasStarredUser(stream: FIRStream!) { self.followingStreams.append(FIRStream!) }
            }
            self.parseData()
        }
    }
    
    func streamHasStarredUser(stream: Models.FirebaseStream) -> Bool {
        if (Current.isStarred(user: stream.host)) { return true }
        
        for user in stream.members {
            if (Current.isStarred(user: user)) { return true }
        }
        return false
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
    
    var followingStreams: [Models.FirebaseStream]
    init(fStreams: [Models.FirebaseStream]) {
        self.followingStreams = fStreams
    }
}

class FeaturedStreamsItem: StreamsViewModelItem {
    var type: StreamsViewModelType {
        return .featuredStream
    }
    
    var sectionTitle: String {
        return "Featured Streams"
    }
    
    var rowCount: Int {
        return featuredStreams.count
    }
    
    var featuredStreams: [Models.FirebaseStream]
    init(ftrdStreams: [Models.FirebaseStream]) {
        self.featuredStreams = ftrdStreams
    }
}

extension StreamsViewModel: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        print(items)
        return items.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items[section].rowCount
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = items[indexPath.section]
        switch item.type {
        case .currentStream:
            if let cell = tableView.dequeueReusableCell(withIdentifier: "StreamCell") as? StreamCell {
                //let cell = cell as! StreamCell
                let item = item as? CurrentStreamItem
                print("item in currStream case", item as Any)
                cell.populateCell(stream: (item?.currStream)!)
                return cell
            }
        case .followingStream:
            if let cell = tableView.dequeueReusableCell(withIdentifier: "StreamCell") as? StreamCell {
                //let cell = cell as! StreamCell
                let item = item as? FollowingStreamsItem
                print("item in followingStream case", item as Any)
                if let fwStream = item?.followingStreams[indexPath.row] {
                    
                    cell.populateCell(stream: fwStream)
                    return cell
                }
            }
        case .featuredStream:
            print("in featuredStreams case")
            if let cell = tableView.dequeueReusableCell(withIdentifier: "StreamCell") as? StreamCell {
                let item = item as? FeaturedStreamsItem
                print("item in featuredStream case", item?.featuredStreams as Any)
                if !((item?.featuredStreams.isEmpty)!), let featuredStream = item?.featuredStreams[indexPath.row] {
                    cell.populateCell(stream: featuredStream)
                    return cell
                }
                
            }
        }
        return UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return items[section].sectionTitle
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = UIView()
        view.backgroundColor = UIColor.red
        return view
    }
    
}
