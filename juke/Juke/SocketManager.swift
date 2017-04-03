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
    
    public func songPositionChanged(streamID: String, songID: String, position: Double) {
        socket.emit("songPositionChanged", ["streamID": streamID, "songID": songID, "progress": position])
    }
    
    public func songPlayStatusChanged(streamID: String, progress: Double, isPlaying: Bool) {
        socket.emit("songPlayStatusChanged", ["streamID": streamID, "progress": progress, "isPlaying": isPlaying])
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
    
    private func ownerSongStatusChanged(data: [Any], ack: SocketAckEmitter) {
        if data.count == 0 {
            return;
        }
        
        if let values = data[0] as? NSDictionary {
            NotificationCenter.default.post(name: Notification.Name("syncPositionWithOwner"), object: values)
        }
    }
    
}
