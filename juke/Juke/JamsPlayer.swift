//
//  JamsPlayer.swift
//  Juke
//
//  Created by Conner Smith on 3/8/17.
//  Copyright © 2017 csmith. All rights reserved.
//

import Foundation

class JamsPlayer  {
    
    static let sharedInstance = SPTAudioStreamingController.sharedInstance()
    
    //This prevents others from using the default '()' initializer for this class.
    private init() {
        print("JAMS!")
    }
    
    public func playTrack() {
        
    
    }
    
    public func pause() {
    
    
    }

}
