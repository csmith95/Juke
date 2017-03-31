//
//  JamsPlayer.swift
//  Juke
//
//  Created by Conner Smith on 3/8/17.
//  Copyright © 2017 csmith. All rights reserved.
//

import Foundation

class JamsPlayer: NSObject, SPTAudioStreamingDelegate, SPTAudioStreamingPlaybackDelegate {
    
    static let shared = JamsPlayer()
    private let userDefaults = UserDefaults.standard
    private let sharedInstance = SPTAudioStreamingController.sharedInstance()
    private var session: SPTSession? = nil
    private let kClientID = "77d4489425fe464483f0934f99847c8b"
    private var position: TimeInterval = 0.0
    
    override private init() {
        super.init()
        do {
            try sharedInstance?.start(withClientId: kClientID)
            sharedInstance?.delegate = self
            sharedInstance?.playbackDelegate = self
            refreshSession()
        } catch let err {
            print(err)
        }
    }
    
    func audioStreamingDidLogin(_ audioStreaming: SPTAudioStreamingController!) {
        print("AudioStreamer logged in!")
    }
    
    func audioStreaming(_ audioStreaming: SPTAudioStreamingController!, didReceiveError error: Error!) {
        print(error)
    }
    
    func audioStreaming(_ audioStreaming: SPTAudioStreamingController!, didReceiveMessage message: String!) {
        print("Received message: ", message)
    }
    
    func audioStreaming(_ audioStreaming: SPTAudioStreamingController!, didReceive event: SpPlaybackEvent) {
        if event == SPPlaybackNotifyTrackChanged {
            if audioStreaming.metadata == nil {
                return
            }
            // track changed -- tell StreamController to pop first song, play next song
            if let currentTrack = audioStreaming.metadata.currentTrack {
                let duration_ms = currentTrack.duration * 1000
                if self.position >= duration_ms - 2000 {
                    self.position = 0.0
                    NotificationCenter.default.post(name: Notification.Name("songFinished"), object: nil)
                }
            }
        }
    }
    
    private func refreshSession() {
        if (session != nil && sharedInstance!.loggedIn && session!.isValid()) {
            return
        }
        
        if let sessionObj = userDefaults.object(forKey: "SpotifySession") {
            let sessionDataObj = sessionObj as! Data
            self.session = NSKeyedUnarchiver.unarchiveObject(with: sessionDataObj) as? SPTSession
            let token:String = session?.accessToken as String!
            self.sharedInstance?.login(withAccessToken: token)
        }
    }
    
    public func isPlaying(trackID: String) -> Bool {
        if let audioStreamer = sharedInstance {
            if audioStreamer.metadata == nil {
                return false
            }
            
            if let currentTrack = audioStreamer.metadata.currentTrack {
                let id = currentTrack.uri.characters.split{$0 == ":"}.map(String.init)[2]
                return id == trackID && audioStreamer.playbackState.isPlaying
            }
        }
        return false
    }
    
    func audioStreaming(_ audioStreaming: SPTAudioStreamingController!, didChangePosition position: TimeInterval) {
        // signal StreamController so that it can update UISlider
        self.position = position * 1000
        let data = ["position": self.position]
        NotificationCenter.default.post(name: Notification.Name("songPositionChanged"), object: data)
    }
    
    public func loadSong(trackID: String, progress: Double) {
        if let session = self.session {
            if !session.isValid() {
                print("session no longer valid")
                return
            }
            
            let uri = "spotify:track:" + trackID
            sharedInstance?.playSpotifyURI(uri, startingWith: 0, startingWithPosition: progress, callback: { (error) in
                if let error = error {
                    print(error)
                } else {
                    self.setPlayStatus(shouldPlay: false, trackID: trackID, position: progress) // load then pause
                }
            })
        }
    }
    
    public func setPlayStatus(shouldPlay: Bool, trackID: String, position: Double) {
        if shouldPlay {
            let uri = "spotify:track:" + trackID
            sharedInstance?.playSpotifyURI(uri, startingWith: 0, startingWithPosition: position, callback: { (error) in
                if let error = error {
                    print(error)
                }
            })
        } else {
            sharedInstance?.setIsPlaying(false, callback: { (err) in
                if let err = err {
                    print(err)
                }
            })
        }
    }
}

