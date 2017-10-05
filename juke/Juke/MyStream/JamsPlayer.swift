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
    private let player = SPTAudioStreamingController.sharedInstance()
    private let kClientID = "77d4489425fe464483f0934f99847c8b"
    private var old_position_ms: TimeInterval?
    public var position_ms: TimeInterval {
        
        didSet(newPosition) {
            if old_position_ms == nil || abs(newPosition - old_position_ms!) >= 4000 {
                self.resync()
            }
            old_position_ms = newPosition
        }
    
        willSet(newPosition) {
            if newPosition == 0.0 {
                 old_position_ms = nil
            }
        }
    }
    
    
    private struct PendingPlayOperation {
        var song: Models.FirebaseSong
    }
    private var loggedInWithToken: String?
    private var pendingPlayOperation: PendingPlayOperation?
    
    override private init() {
        self.position_ms = 0.0
        print("init jams player")
        super.init()
        do {
            try player?.start(withClientId: kClientID)
            player?.delegate = self
            player?.playbackDelegate = self
            try? AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
            try? AVAudioSession.sharedInstance().setActive(true)
        } catch let err {
            print(err)
        }
    }
    
    public func login() {
        // get/refresh token
        SessionManager.executeWithToken(callback: { (token) in
            self.authenticatePlayer()   // sign in
        })
    }

    func audioStreamingDidLogin(_ audioStreaming: SPTAudioStreamingController!) {
        print("**** Audio Player audio logged in")
        if let pending = pendingPlayOperation {
            self.tryPlaying(topSong: pending.song)
        }
    }
    
    func audioStreaming(_ audioStreaming: SPTAudioStreamingController!, didReceiveError error: Error!) {
        print(error)
    }
    
    func audioStreaming(_ audioStreaming: SPTAudioStreamingController!, didReceive event: SpPlaybackEvent) {
        if !Current.isHost() { return } // listen to owner's phone -- otherwise double skip sometimes happens
        if event == SPPlaybackNotifyTrackChanged {
            if audioStreaming.metadata == nil {
                return
            }
            
            // track changed -- tell StreamController to pop first song, play next song
            if let currentTrack = audioStreaming.metadata.currentTrack {
                let duration_ms = currentTrack.duration * 1000
                if self.position_ms >= duration_ms - 2000 {
                    self.position_ms = 0.0
                    NotificationCenter.default.post(name: Notification.Name("songFinished"), object: nil)
                }
            }
        }
    }
    
    private func authenticatePlayer() {
        print("*** Audio Player logging in with token: \(SessionManager.accessToken)")
        self.loggedInWithToken = SessionManager.accessToken
        player?.login(withAccessToken: SessionManager.accessToken)
    }
    
    func audioStreaming(_ audioStreaming: SPTAudioStreamingController!, didChangePosition position: TimeInterval) {
        // signal MyStreamController so that it can update UISlider and update Firebase if host
        position_ms = position * 1000
        let data: [String:Any] = ["progress": position_ms]
        NotificationCenter.default.post(name: Notification.Name("songPositionChanged"), object: data)
    }
    
    public func setPlayStatus(shouldPlay: Bool, topSong: Models.FirebaseSong?) {
        objc_sync_enter(pendingPlayOperation)
        
        // don't need token to stop playing
        if !shouldPlay || topSong == nil {
            pendingPlayOperation = nil
            self.stopPlaying()
            objc_sync_exit(pendingPlayOperation)
            return
        }
        
        guard let song = topSong else { return }
        SessionManager.executeWithToken { (token) in
            guard let token = token else { return }
            guard let loggedInToken = self.loggedInWithToken, loggedInToken == token else {
                self.pendingPlayOperation = PendingPlayOperation(song: song)
                self.authenticatePlayer()
                objc_sync_exit(self.pendingPlayOperation)
                return
            }
            
            self.pendingPlayOperation = nil
            // tokens match -- go ahead and play song
            self.tryPlaying(topSong: song)
        }
    }
    
    func stopPlaying() {
        print("STOP")
        player?.setIsPlaying(false, callback: { (err) in
            if let _ = err {
                print("error in stopPlaying")
            }
        });
        return
    }
    
    func tryPlaying(topSong: Models.FirebaseSong) {
        print("GO")

        // not sure if this is good style, but these 2 lines are the magic behind background streaming
        let position = position_ms / 1000
        let uri = "spotify:track:" + topSong.spotifyID
        player?.playSpotifyURI(uri, startingWith: 0, startingWithPosition: position, callback: { (error) in
            if let _ = error {
                print("error in tryPlaying")
            }
        });
    }

    
    public func resync() {
        guard let stream = Current.stream, let song = stream.song else {
            // if no stream found, shut down music player
            stopPlaying()
            return
        }
        
        if !stream.isPlaying {
            stopPlaying()
            return
        }
        
        // below here we know stream is set to playing. play music if host or if member && listen button selected
        if Current.isHost() {
            setPlayStatus(shouldPlay: true, topSong: song)
        } else {
            if Current.listenSelected {
                setPlayStatus(shouldPlay: true, topSong: song)
            } else {
                setPlayStatus(shouldPlay: false, topSong: song)
            }
        }
    }

}

