//
//  StreamsDataSource.swift
//  Juke
//
//  Created by Kojo Worai Osei on 3/8/18.
//  Copyright © 2018 csmith. All rights reserved.
//

import Foundation
import Firebase

class NewStreamsDataSource {
    var allStreams = [Models.FirebaseStream]()
    var followingStreams = [Models.FirebaseStream]()
    var featuredStreams = [Models.FirebaseStream]()
    
    public func listen() {
        var ref: DatabaseReference!
        ref = Database.database().reference()
        ref.child("streams").observe(DataEventType.value, with: { (snapshot) in
            self.allStreams = snapshot.value as! [Models.FirebaseStream]
        })
    }
}
