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
        
        self.socket.on("disconnect") { data, ack in
            print("socket disconnected")
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
        socket.emitWithAck("joinStream", ["userID": userID, "streamID": streamID]).timingOut(after: 3) { data in
            if data.count == 0 {
                return
            }
            if let unparsedStream = data[0] as? UnboxableDictionary {
                callback(unparsedStream)
            }
        }
    }
    
    public func updateSongPositionChanged(streamID: String, position: Double) {
        socket.emit("songPositionChanged", ["streamID": streamID, "position": position])
    }
    
    
    public func updateSongEnded(group_id: String) {
        socket.emit("songEnded", ["group_id": group_id])
    }
    
}
