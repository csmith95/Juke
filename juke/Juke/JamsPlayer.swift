//
//  JamsPlayer.swift
//  Juke
//
//  Created by Conner Smith on 3/8/17.
//  Copyright © 2017 csmith. All rights reserved.
//

import Foundation
import AVFoundation

class JamsPlayer: NSObject, SPTAudioStreamingDelegate, SPTAudioStreamingPlaybackDelegate {
    
    static let shared = JamsPlayer()
    private let userDefaults = UserDefaults.standard
    private let sharedInstance = SPTAudioStreamingController.sharedInstance()
    private var session: SPTSession? = nil
    private let kClientID = "77d4489425fe464483f0934f99847c8b"
    private var position: TimeInterval = 0.0
    private var songJukeID: String? // Juke id of currently playing song
    
    
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
    
    func audioStreaming(_ audioStreaming: SPTAudioStreamingController!, didChangePlaybackStatus isPlaying: Bool) {
        print("status changed: ", isPlaying)
        // allows background audio streaming
        if isPlaying {
            try? AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
            try? AVAudioSession.sharedInstance().setActive(true)
        } else {
//            try? AVAudioSession.sharedInstance().setActive(false)
            print("tried off")
        }
    }
    
    func audioStreamingDidLogin(_ audioStreaming: SPTAudioStreamingController!) {
        print("AudioStreamer logged in!")
        NotificationCenter.default.post(name: Notification.Name("jamsPlayerReady"), object: nil)
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
            print("received event")
            // track changed -- tell StreamController to pop first song, play next song
            if let currentTrack = audioStreaming.metadata.currentTrack {
                let duration_ms = currentTrack.duration * 1000
                if self.position >= duration_ms - 2000 {
                    self.position = 0.0
                    NotificationCenter.default.post(name: Notification.Name("songFinished"), object: nil)
                    print("posted pop")
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
    
    public func isPlaying(song: Models.Song) -> Bool {
        
        if self.songJukeID == nil {
            return false   // first, check that a song is playing or loaded
        }
        
        if self.songJukeID != song.id {
            return false    // check that they are the same song objects in Juke DB, not just the same spotify song
        }
        
        if let audioStreamer = sharedInstance {
            return audioStreamer.playbackState.isPlaying   // check that song is playing, not paused
        }
        return false
    }
    
    func audioStreaming(_ audioStreaming: SPTAudioStreamingController!, didChangePosition position: TimeInterval) {
        // signal StreamController so that it can update UISlider
        let position_ms = position * 1000
        self.position = position_ms
        let data: [String:Any] = ["songID": self.songJukeID, "progress": self.position]
        NotificationCenter.default.post(name: Notification.Name("songPositionChanged"), object: data)
    }
    
    public func setPlayStatus(shouldPlay: Bool, song: Models.Song) {
        if shouldPlay {
            print("shouldPlay")
            let position = song.progress / 1000
            let uri = "spotify:track:" + song.spotifyID
            sharedInstance?.playSpotifyURI(uri, startingWith: 0, startingWithPosition: position, callback: { (error) in
                if let error = error {
                    print(error)
                } else {
                    self.songJukeID = song.id
                    print("playing: ", self.songJukeID)
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

