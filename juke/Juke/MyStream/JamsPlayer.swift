//
//  JamsPlayer.swift
//  Juke
//
//  Created by Conner Smith on 3/8/17.
//  Copyright © 2017 csmith. All rights reserved.
//

import Foundation
import AVFoundation
import MediaPlayer

class JamsPlayer: NSObject, SPTAudioStreamingDelegate, SPTAudioStreamingPlaybackDelegate {
    
    static let shared = JamsPlayer()
    private let userDefaults = UserDefaults.standard
    private let sharedInstance = SPTAudioStreamingController.sharedInstance()
    private var session: SPTSession? = nil
    private let kClientID = "77d4489425fe464483f0934f99847c8b"
    private var old_position_ms: TimeInterval?
    public var position_ms: TimeInterval {
        
        didSet(newPosition) {
            if old_position_ms == nil || abs(newPosition - old_position_ms!) >= 3000 {
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
    
    let mpic = MPNowPlayingInfoCenter.default()
    
    override private init() {
        self.position_ms = 0.0
        super.init()
        do {
            try sharedInstance?.start(withClientId: kClientID)
            sharedInstance?.delegate = self
            sharedInstance?.playbackDelegate = self
            refreshSession()
            try? AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
            try? AVAudioSession.sharedInstance().setActive(true)
            setUpNowPlayingInfoCenter()
        } catch let err {
            print(err)
        }
    }
    
    private func setUpNowPlayingInfoCenter() {
        UIApplication.shared.beginReceivingRemoteControlEvents()
        MPRemoteCommandCenter.shared().playCommand.addTarget {event in
            self.setPlayStatus(shouldPlay: true, topSong: Current.stream?.song)
            return .success
        }
        
        MPRemoteCommandCenter.shared().pauseCommand.addTarget {event in
            self.setPlayStatus(shouldPlay: false, topSong: Current.stream?.song)
            return .success
        }
    }
    
    private func updateNowPlayingInfoCenter() {
        guard let stream = Current.stream, let song = stream.song else {
            mpic.nowPlayingInfo = [String: AnyObject]()
            return
        }
        
        mpic.nowPlayingInfo = [
            MPMediaItemPropertyTitle: song.songName,
            MPMediaItemPropertyArtist: song.artistName,
            MPMediaItemPropertyPlaybackDuration: song.duration/1000,
            MPNowPlayingInfoPropertyElapsedPlaybackTime: self.position_ms/1000,
            MPNowPlayingInfoPropertyPlaybackRate: stream.isPlaying && Current.listenSelected,
        ]
        
        if let image = song.image {
            print("image not nil")
            mpic.nowPlayingInfo![MPMediaItemPropertyArtwork] = image
        } else {
            print("image == nil")
            setImage(url: song.coverArtURL)
        }
    }
    
    private func setImage(url: String) {
        ImageCache.downloadPlaylistImage(url: url) { (image) in
            print("downloaded")
            let mySize = CGSize(width: 400, height: 400)
            Current.stream?.song?.image = MPMediaItemArtwork(boundsSize:mySize) { sz in
                return image.imageScaled(to: mySize)
            }
//            self.mpic.nowPlayingInfo![MPMediaItemPropertyArtwork] = albumArt
            self.updateNowPlayingInfoCenter()
        }
    }

    func audioStreamingDidLogin(_ audioStreaming: SPTAudioStreamingController!) {
        print("** JamsPlayer audio logged in")
        NotificationCenter.default.post(name: Notification.Name("jamsPlayerReady"), object: nil)
    }
    
    func audioStreaming(_ audioStreaming: SPTAudioStreamingController!, didReceiveError error: Error!) {
        print(error)
    }
    
    func audioStreaming(_ audioStreaming: SPTAudioStreamingController!, didReceiveMessage message: String!) {
        print("** JamsPlayer received message: ", message)
    }
    
    func audioStreaming(_ audioStreaming: SPTAudioStreamingController!, didReceive event: SpPlaybackEvent) {
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
    
    func audioStreaming(_ audioStreaming: SPTAudioStreamingController!, didChangePosition position: TimeInterval) {
        // signal StreamController so that it can update UISlider
        position_ms = position * 1000
        let data: [String:Any] = ["progress": position_ms]
        NotificationCenter.default.post(name: Notification.Name("songPositionChanged"), object: data)
    }
    
    private func setPlayStatus(shouldPlay: Bool, topSong: Models.FirebaseSong?) {
        updateNowPlayingInfoCenter()
        guard let player = sharedInstance else { self.refreshSession(); return; }
        guard let song = topSong else {                     // turn off if nil passed in for topSong
            player.setIsPlaying(false, callback: { (err) in
                if let err = err {
                    print(err)
                }
            });
            return
        }
        
        if shouldPlay {
            // not sure if this is good style, but these 2 lines are the magic behind background streaming
            let position = position_ms / 1000
            let uri = "spotify:track:" + song.spotifyID
            player.playSpotifyURI(uri, startingWith: 0, startingWithPosition: position, callback: { (error) in
                if let error = error {
                    print(error)
                }
            });
        } else {
            player.setIsPlaying(false, callback: { (err) in
                if let err = err {
                    print(err)
                }
            });
        }
    }
    
    public func resync() {
        guard let stream = Current.stream else {
            // if no stream found, shut down music player
            setPlayStatus(shouldPlay: false, topSong: nil)
            return
        }
        
        if !stream.isPlaying {
            setPlayStatus(shouldPlay: false, topSong: stream.song)
            return
        }
        
        // below here we know stream is set to playing. play music if host or if member && listen button selected
        if Current.isHost() {
            setPlayStatus(shouldPlay: true, topSong: stream.song)
        } else {
            setPlayStatus(shouldPlay: Current.listenSelected, topSong: stream.song)
        }
    }

}

