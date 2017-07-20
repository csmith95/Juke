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
import PKHUD
import Alamofire

struct CurrSocket {
    static var socketid = ""
}


class SocketManager: NSObject {
    
    static let sharedInstance = SocketManager()
    let socket = SocketIOClient(socketURL: URL(string: ServerConstants.kJukeServerURL)!,
                                config: [.voipEnabled(true), .reconnects(true)])
    
    override private init() {
        super.init()
        socket.on("connect") { data, ack in
            print("socket connected: ", self.socket.sid!)
            
            // only set socketID for current user after connection opened
            CurrSocket.socketid = self.socket.sid!
            let url = ServerConstants.kJukeServerURL + ServerConstants.kSetSocketID
            let params: Parameters = [
                "_id": CurrentUser.user.id,
                "socketID": CurrSocket.socketid
            ]
            Alamofire.request(url, method: .post, parameters: params)
        }
        
        socket.on("disconnect") { data, ack in
            print("socket disconnected")
        }
        
        socket.on("ownerSongStatusChanged") { data, ack in
            self.ownerSongStatusChanged(data: data, ack: ack)
        }
        
        socket.on("refreshStream") { data, ack in
            print("socket manager received refresh stream signal")
            NotificationCenter.default.post(name: Notification.Name("refreshStream"), object: nil);
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
        socket.emit("songPositionChanged", ["songID": songID, "progress": position])
    }
    
    public func songPlayStatusChanged(streamID: String, songID: String, progress: Double, isPlaying: Bool) {
        socket.emit("songPlayStatusChanged", ["streamID": streamID, "songID":  songID, "progress": progress, "isPlaying": isPlaying])
    }
    
    public func addSong(params: Dictionary<String, Any>) {
        socket.emitWithAck("addSong", params).timingOut(after: 3) { data in
            print("received ack");
            NotificationCenter.default.post(name: Notification.Name("refreshStream"), object: nil);
        }
    }
    
    public func songEnded(streamID: String) {
        socket.emit("songEnded", ["streamID": streamID])
    }
    
    public func joinSocketRoom(streamID: String) {
        print("joinSocketRoom emitted")
        socket.emitWithAck("joinRoom", ["streamID": streamID]).timingOut(after: 2) { data in
            print("Received joinSocketRoom ACK: ", data)
        }
    }
    
    public func visitStream(streamID: String) {
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
        HUD.show(.progress)
        socket.emitWithAck("splitFromStream", ["userID": userID]).timingOut(after: 3) { data in
            HUD.flash(.success, delay: 1.0)
            NotificationCenter.default.post(name: Notification.Name("refreshStream"), object: nil);
        }
    }
    
    public func popSong(data: [Any]) {
        if let streamID = data[0] as? String {
            socket.emit("popSong", ["streamID": streamID])
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
    
    public func clearStream() {
        socket.emitWithAck("clearStream", ["streamID": CurrentUser.stream.streamID]).timingOut(after: 3) { data in
            NotificationCenter.default.post(name: Notification.Name("refreshStream"), object: nil);
        }
    }
    
}
