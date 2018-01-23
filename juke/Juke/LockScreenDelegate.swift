//
//  LockScreenDelegate.swift
//  Juke
//
//  Created by Conner Smith on 9/29/17.
//  Copyright © 2017 csmith. All rights reserved.
//

import Foundation
import MediaPlayer

class LockScreenDelegate: NSObject {
    
    // object for interacting with Apple API
    private let mpic = MPNowPlayingInfoCenter.default()
    
    
    // audio player
    private let jamsPlayer = JamsPlayer.shared

    public func setUpNowPlayingInfoCenter() {
        print("init")
        mpic.nowPlayingInfo = [String: AnyObject]()
        UIApplication.shared.beginReceivingRemoteControlEvents()
        MPRemoteCommandCenter.shared().previousTrackCommand.isEnabled = false
        
//        if Current.isHost() {
//            MPRemoteCommandCenter.shared().playCommand.isEnabled = true
//            MPRemoteCommandCenter.shared().nextTrackCommand.isEnabled = true
//        } else {
//            MPRemoteCommandCenter.shared().playCommand.isEnabled = false
//            MPRemoteCommandCenter.shared().nextTrackCommand.isEnabled = false
//        }
        
        
        MPRemoteCommandCenter.shared().playCommand.addTarget {event in
            guard let _ = Current.stream else { return .commandFailed }
            if Current.isHost() {
                Current.stream?.isPlaying = true
                FirebaseAPI.setPlayStatus(status: true)   // update db
                var current = self.mpic.nowPlayingInfo
                current![MPNowPlayingInfoPropertyPlaybackRate] = Current.stream?.isPlaying
                current![MPNowPlayingInfoPropertyElapsedPlaybackTime] = self.jamsPlayer.position_ms/1000
                self.mpic.nowPlayingInfo = current
            }
            Current.listenSelected = true
            self.jamsPlayer.setPlayStatus(shouldPlay: Current.stream!.isPlaying && Current.listenSelected, topSong: Current.stream?.song)
            NotificationCenter.default.post(name: Notification.Name("firebaseEventLockScreen"), object: FirebaseAPI.FirebaseEvent.PlayStatusChanged)
            return .success
        }
        
        MPRemoteCommandCenter.shared().pauseCommand.isEnabled = true
        MPRemoteCommandCenter.shared().pauseCommand.addTarget {event in
            guard let _ = Current.stream else { return .commandFailed }
            if Current.isHost() {
                Current.stream?.isPlaying = false
                FirebaseAPI.setPlayStatus(status: false)   // update db
                var current = self.mpic.nowPlayingInfo
                current![MPNowPlayingInfoPropertyPlaybackRate] = Current.stream?.isPlaying
                current![MPNowPlayingInfoPropertyElapsedPlaybackTime] = self.jamsPlayer.position_ms/1000
                self.mpic.nowPlayingInfo = current
            }
            Current.listenSelected = false
            self.jamsPlayer.setPlayStatus(shouldPlay: Current.stream!.isPlaying && Current.listenSelected, topSong: Current.stream?.song)
            NotificationCenter.default.post(name: Notification.Name("firebaseEventLockScreen"), object: FirebaseAPI.FirebaseEvent.TopSongChanged)
            return .success
        }
        
        MPRemoteCommandCenter.shared().nextTrackCommand.addTarget {event in
            
            NotificationCenter.default.post(name: Notification.Name("songFinished"), object: nil)
            return .success
        }
    
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.firebaseEventHandler), name: Notification.Name("firebaseEventLockScreen"), object: nil)
    }
    
    func firebaseEventHandler(notification: NSNotification) {
        guard let stream = Current.stream, let song = stream.song else {
            mpic.nowPlayingInfo = [String: AnyObject]()
            return
        }
        guard let event = notification.object as? FirebaseAPI.FirebaseEvent else { print("error"); return }
        switch event {
        case .PlayStatusChanged:
            var current = mpic.nowPlayingInfo
            current![MPNowPlayingInfoPropertyPlaybackRate] = stream.isPlaying
            current![MPNowPlayingInfoPropertyElapsedPlaybackTime] = jamsPlayer.position_ms/1000
            mpic.nowPlayingInfo = current
        case .TopSongChanged:
            var current = mpic.nowPlayingInfo
            current![MPMediaItemPropertyTitle] = song.songName
            current![MPMediaItemPropertyArtist] = song.artistName
            current![MPMediaItemPropertyPlaybackDuration] = song.duration/1000
            current![MPNowPlayingInfoPropertyElapsedPlaybackTime] = jamsPlayer.position_ms/1000
            mpic.nowPlayingInfo = current
            ImageCache.downloadLockScreenAlbumArtImage(url: song.coverArtURL) { (image) in
                guard let image = image else { return }
                let mySize = CGSize(width: 400, height: 400)
                let albumArt = MPMediaItemArtwork(boundsSize:mySize) { sz in
                    return image.imageScaled(to: mySize)
                }
                var current = self.mpic.nowPlayingInfo
                current![MPMediaItemPropertyArtwork] = albumArt
                self.mpic.nowPlayingInfo = current
            }
        default:
            return
        }
    }
}
