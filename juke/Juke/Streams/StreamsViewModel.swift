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
    weak var streamsVC: UIViewController? = nil
    var featuredStreams = [Models.FirebaseStream]()
    var followingStreams = [Models.FirebaseStream]()
    
    func parseData() {
        // refresh items
        items.removeAll()
        print("called parseData, removed all items")
        
        // create streamviewmodeltypes
        let followingStreamsItem = FollowingStreamsItem(fStreams: self.followingStreams)
        let featuredStreamsItem = FeaturedStreamsItem(ftrdStreams: self.featuredStreams)
        
        // Because a user may or may not be in a stream
        if let currListening = Current.stream {
            let currStreamItem = CurrentStreamItem(currentStream: currListening)
            items.append(currStreamItem)
        }
        
        // append model types to items list
        
        
        items.append(followingStreamsItem)
        items.append(featuredStreamsItem)
        
        print("Following length", followingStreamsItem.followingStreams.count)
        print("items length", items.count)
        // notify view controller that you have finished updating items list
        delegate?.didFinishUpdates()
        
    }
    
    func loadData() {
        // update when there is a change in streams
        FirebaseAPI.streamsListener { (streams) in
            // clear before adding new streams
            self.followingStreams.removeAll()
            self.featuredStreams.removeAll()
            
            // go through snapshot and assign streams to their appropriate type
            let enumerator = streams.children
            while let stream = enumerator.nextObject() as? DataSnapshot {
                let FIRStream = Models.FirebaseStream(snapshot: stream)
                if (FIRStream?.isFeatured)! { self.featuredStreams.append(FIRStream!) }
                if self.streamHasStarredUser(stream: FIRStream!) { self.followingStreams.append(FIRStream!) }
            }
            
            // update items list
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
        return "Current"
    }
    
    var rowCount: Int {
        return 1
    }
    
    var currStream: Models.FirebaseStream?
    
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
        // if there are no following streams then dequeue no followers cell
        if followingStreams.count == 0 {
            return 1
        }
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
        return "Featured"
    }
    
    var rowCount: Int {
        return 1
    }
    
    var featuredStreams: [Models.FirebaseStream]
    init(ftrdStreams: [Models.FirebaseStream]) {
        self.featuredStreams = ftrdStreams
    }
}

extension StreamsViewModel: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
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
                cell.populateCell(stream: (item?.currStream)!)
                return cell
            }
        case .followingStream:
            
            // dequeue a no followers cell if no following stream
            let item = item as? FollowingStreamsItem
            
            if item?.followingStreams.count == 0 {
                let cell = Bundle.main.loadNibNamed("NoFollowersCell", owner: self, options: nil)?.first as! NoFollowersCell
                cell.parentVC = self.streamsVC
                return cell
            } else {
                if let cell = tableView.dequeueReusableCell(withIdentifier: "StreamCell") as? StreamCell {
                    if let fwStream = item?.followingStreams[indexPath.row] {
                        
                        cell.populateCell(stream: fwStream)
                        return cell
                    }
                }
            }
            
            
            
        case .featuredStream:
            if let cell = tableView.dequeueReusableCell(withIdentifier: "featuredRow") as? FeaturedRow {
                let item = item as? FeaturedStreamsItem
                cell.featuredStreams = item?.featuredStreams
                return cell
            }
        }
        return UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return items[section].sectionTitle
    }
    
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = Bundle.main.loadNibNamed("StreamSectionHeader", owner: self, options: nil)?.first as! StreamSectionHeader!
        
        let text = (items[section].sectionTitle).uppercased()
       
        
        headerView?.sectionTitle.attributedText = NSAttributedString(string: text, attributes: [NSKernAttributeName: 3.5])
        
        return headerView
    }

    
    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        if let headerTitle = view as? UITableViewHeaderFooterView {
            headerTitle.textLabel?.textColor = UIColor.white
            headerTitle.layer.borderWidth = 1
            headerTitle.layer.borderColor = UIColor.white.cgColor
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        // set custom height for featured streams row
        if indexPath.section == 2 {
            return 190
        }
        return 100
    }
}
