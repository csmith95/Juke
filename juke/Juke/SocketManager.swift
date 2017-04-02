//
//  SocketManager.swift
//  Juke
//
//  Created by Conner Smith on 3/14/17.
//  Copyright © 2017 csmith. All rights reserved.
//

import Foundation
import SocketIO

class SocketManager: NSObject {
    
    static let sharedInstance = SocketManager()
    let socket = SocketIOClient(socketURL: URL(string: ServerConstants.kJukeServerURL)!)
    
    override private init() {
        super.init()
        socket.on("connect") { data, ack in
            print("socket connected")
            self.updateUserTunedIntoGroup(user_id: "abc", group_id: "def")
        }
        
        self.socket.on("disconnect") { data, ack in
            print("socket disconnected")
        }
        socket.on("random") { data, ack in
            print("received random!")
        }
    }
    
    public func openConnection() {
        socket.connect()
    }
    
    public func closeConnection() {
        socket.disconnect()
    }
    
    public func updateUserTunedIntoGroup(user_id: String, group_id: String) {
        socket.emit("joinedGroup", ["user_id": user_id, "group_id": group_id])
    }
    
    public func updateSongPositionChanged(streamID: String, position: Double) {
        socket.emit("songPositionChanged", ["streamID": streamID, "position": position])
    }
    
    
    public func updateSongEnded(group_id: String) {
        socket.emit("songEnded", ["group_id": group_id])
    }
    
}
