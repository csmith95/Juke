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
        mpic.nowPlayingInfo = [String: AnyObject]()
        UIApplication.shared.beginReceivingRemoteControlEvents()
        MPRemoteCommandCenter.shared().playCommand.addTarget {event in
            guard let _ = Current.stream else { return .commandFailed }
            if Current.isHost() {
                Current.stream?.isPlaying = true
                FirebaseAPI.setPlayStatus(status: true)   // update db
            }
            Current.listenSelected = true
            self.jamsPlayer.setPlayStatus(shouldPlay: Current.stream!.isPlaying && Current.listenSelected, topSong: Current.stream?.song)
            return .success
        }
        
        MPRemoteCommandCenter.shared().pauseCommand.addTarget {event in
            guard let _ = Current.stream else { return .commandFailed }
            if Current.isHost() {
                Current.stream?.isPlaying = false
                FirebaseAPI.setPlayStatus(status: false)   // update db
            }
            Current.listenSelected = false
            self.jamsPlayer.setPlayStatus(shouldPlay: Current.stream!.isPlaying && Current.listenSelected, topSong: Current.stream?.song)
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
            mpic.nowPlayingInfo?[MPNowPlayingInfoPropertyPlaybackRate] = stream.isPlaying
            mpic.nowPlayingInfo?[MPNowPlayingInfoPropertyElapsedPlaybackTime] = jamsPlayer.position_ms/1000
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
        case .SetProgress:
            var current = mpic.nowPlayingInfo
            current![MPNowPlayingInfoPropertyElapsedPlaybackTime] = jamsPlayer.position_ms/1000
            mpic.nowPlayingInfo = current
        default:
            return
        }
    }
}
