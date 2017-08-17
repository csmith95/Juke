//
//  FirebaseAPI.swift
//  Juke
//
//  Created by Conner Smith on 8/16/17.
//  Copyright © 2017 csmith. All rights reserved.
//

import Foundation
import Firebase

class FirebaseAPI {
    var isOpen = false
    
    static let sharedInstance = FirebaseAPI()
    let ref = Database.database().reference().child("streams")
    
    //  I added functions for firebase reference in this class
    
    func observeNotifications(){
        
        //firebase call here
        ref.observe(DataEventType.childRemoved, with: { (snapshot) in
            print(snapshot)
        })
    }
    
}
