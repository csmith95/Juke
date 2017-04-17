//
//  SocketManager.swift
//  Juke
//
//  Created by Conner Smith on 3/14/17.
//  Copyright © 2017 csmith. All rights reserved.
//

import Foundation
import SocketIO
import Unbox

class SocketManager: NSObject {
    
    static let sharedInstance = SocketManager()
    let socket = SocketIOClient(socketURL: URL(string: ServerConstants.kJukeServerURL)!)
    
    override private init() {
        super.init()
        socket.on("connect") { data, ack in
            print("socket connected")
        }
        
        socket.on("disconnect") { data, ack in
            print("socket disconnected")
        }
        
        socket.on("ownerSongStatusChanged") { data, ack in
            self.ownerSongStatusChanged(data: data, ack: ack)
        }
        
        socket.on("refreshStream") { data, ack in
            if data.count == 0 {
                return
            }
            
            print("socket manager received refresh stream")
            if let tunedInto = data[0] as? String {
                if tunedInto == "NO ACK" {
                    return
                }
                NotificationCenter.default.post(name: Notification.Name("refreshStream"), object: tunedInto);
            }
        }
    }
    
    public func openConnection() {
        socket.connect()
    }
    
    public func closeConnection() {
        socket.disconnect()
    }
    
    public func joinStream(userID: String, streamID: String, callback: @escaping (UnboxableDictionary) -> (Void)) {
        print("joinStream emitted")
        socket.emitWithAck("joinStream", ["userID": userID, "streamID": streamID]).timingOut(after: 2) { data in
            if data.count == 0 {
                return
            }
            if let unparsedStream = data[0] as? UnboxableDictionary {
                callback(unparsedStream)
            }
        }
    }
    
    public func songPositionChanged(songID: String, position: Double) {
        print("song position changed")
        socket.emit("songPositionChanged", ["songID": songID, "progress": position])
    }
    
    public func songPlayStatusChanged(streamID: String, songID: String, progress: Double, isPlaying: Bool) {
        print("song play status changed")
        socket.emit("songPlayStatusChanged", ["streamID": streamID, "songID":  songID, "progress": progress, "isPlaying": isPlaying])
    }
    
    public func songEnded(streamID: String) {
        print("songEnded emitted")
        socket.emit("songEnded", ["streamID": streamID])
    }
    
    public func joinSocketRoom(streamID: String) {
        print("joinSocketRoom emitted")
        socket.emitWithAck("joinRoom", ["streamID": streamID]).timingOut(after: 2) { data in
            print("Received joinSocketRoom ACK: ", data)
        }
    }
    
    public func visitStream(streamID: String) {
        print("visitStream emitted")
        socket.emitWithAck("visitStream", ["streamID": streamID]).timingOut(after: 2) { data in
            print("Received visitStream ACK: ", data)
            if data.count == 0 {
                return
            }
            
            if let newStream = data[0] as? NSDictionary {
                NotificationCenter.default.post(name: Notification.Name("refreshStream"), object: newStream);
            }
        }
    }
    
    public func leaveSocketRoom(streamID: String, visitor: Bool) {
        print("leaveSocketRoom emitted")
        var room = streamID
        if visitor {
            room += "V"
        }
        socket.emitWithAck("leaveRoom", ["streamID": room]).timingOut(after: 2) { data in
            print("Received leaveSocketRoom ACK: ", data)
        }
    }
    
    public func splitFromStream(userID: String) {
        print("splitFromStream emitted")
        socket.emitWithAck("splitFromStream", ["userID": userID]).timingOut(after: 3) { data in
            print("Received splitFromStream ACK: ", data);
            if data.count == 0 {
                return
            }
            
            if let first = data[0] as? String {
                if first == "NO ACK" {
                    return;
                }
                NotificationCenter.default.post(name: Notification.Name("refreshMyStream"), object: nil);
            }
        }
    }
    
    private func ownerSongStatusChanged(data: [Any], ack: SocketAckEmitter) {
        if data.count == 0 {
            return;
        }
        
        print("owner song status changed")
        if let values = data[0] as? NSDictionary {
            NotificationCenter.default.post(name: Notification.Name("syncPositionWithOwner"), object: values)
        }
    }
    
}
