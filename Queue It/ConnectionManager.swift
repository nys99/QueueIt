//
//  ConnectionManager.swift
//  Queue It
//
//  Created by Nikhil Sharma on 7/16/17.
//  Copyright © 2017 Nikhil Sharma. All rights reserved.
//
//
// this class should be able to advertise the device services and browse nearby devices that are
// advertised. the advertising should be encrypted so not to pick up other devices advertising
//
// the methods should be to send data like an track or arrar of tracks
// the class should also create a notification of something that is called when data is recieved
// be able to accept connections coming from other devices
//

import Foundation
import UIKit
import MultipeerConnectivity

protocol ConnectionManagerDelegate {
    
    func connectedDevicesChanged(manager : ConnectionManager, connectedDevices: [String])
    func colorChanged(manager : ConnectionManager, colorString: String)
    
}

public class ConnectionManager: NSObject {
    // FEILDS
    // array of connected peers
        // class already has
    // array of nearby devices
    var nearbyPeers: [MCPeerID]
    let serviceAdvertiser : MCNearbyServiceAdvertiser
    let serviceBrowser : MCNearbyServiceBrowser
    private let serviceType = "example-connect"
    var myPeerId = MCPeerID(displayName: UIDevice.current.name)
    var delegate : ConnectionManagerDelegate?
    var playerDataToHandle: SongPlayer = SongPlayer.init()
    var actionDataToHandle: String = ""
    var isQueueCreator = false
    var session: MCSession
    var connectedQueue: MCPeerID
    
    override init(){
        self.session = MCSession(peer: myPeerId, securityIdentity: nil, encryptionPreference: .required)
        self.serviceAdvertiser = MCNearbyServiceAdvertiser(peer: myPeerId, discoveryInfo: nil, serviceType: serviceType)
        self.serviceBrowser = MCNearbyServiceBrowser(peer: myPeerId, serviceType: serviceType)
        self.nearbyPeers = [MCPeerID]()
        self.connectedQueue = MCPeerID(displayName: "queue")
        super.init()

        self.session.delegate = self
        self.serviceAdvertiser.delegate = self
        self.serviceBrowser.delegate = self

    }
    
    deinit {
        self.serviceAdvertiser.stopAdvertisingPeer()
        self.serviceBrowser.stopBrowsingForPeers()
        self.session.disconnect()
    }
    
    // METHODS
    // method to send data to PeerID
    func send(player: SongPlayer, peer: [MCPeerID]){
        print("player sent")
        do{
            try self.session.send(NSKeyedArchiver.archivedData(withRootObject: player), toPeers: peer, with: .reliable)
        } catch is Error {
            print("unable to send track")
        }
    }
    func send(action: String, peer: [MCPeerID]){
        print("action sent")
        do{
            try self.session.send(NSKeyedArchiver.archivedData(withRootObject: action), toPeers: peer, with: .reliable)
        } catch is Error {
            print("unable to send track")
        }
    }
    
    // method that somehow handles the data recieved data
    func handleRecievedData(data: Data){
        if let player = NSKeyedUnarchiver.unarchiveObject(with: data) as? SongPlayer {
            self.playerDataToHandle = player
            self.playerDataToHandle.player = SPTAudioStreamingController.sharedInstance()
            print("player data handled")
            NotificationCenter.default.post(name: .playerDataRecieved, object: nil)
        } else if let action = NSKeyedUnarchiver.unarchiveObject(with: data) as? String {
            self.actionDataToHandle = action
            print("action data handled")
            NotificationCenter.default.post(name: .actionDataRecieved, object: nil)
        }
        
        
    }
    // method to connect to peer
    func invitePeerToConnect(peer: MCPeerID, browser: MCNearbyServiceBrowser){
        browser.invitePeer(peer, to: self.session, withContext: nil, timeout: 10)
    }
    // method to disconnect from peer
    func disconnectFromPeer(peer: MCPeerID){
        self.session.cancelConnectPeer(peer)
    }
    func disconnectFromAll(){
        self.session.disconnect()
    }
    func resetConnectedQueue(){
        connectedQueue = MCPeerID.init(displayName: "njrhchkdn")
    }

}

extension ConnectionManager : MCNearbyServiceAdvertiserDelegate {
    
    public func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Error) {
        NSLog("%@", "didNotStartAdvertisingPeer: \(error)")
    }
    
    public func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        NSLog("%@", "didReceiveInvitationFromPeer \(peerID)")
        invitationHandler(true, self.session)
    }
    
}

extension ConnectionManager : MCNearbyServiceBrowserDelegate {
    
    public func browser(_ browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: Error) {
        NSLog("%@", "didNotStartBrowsingForPeers: \(error)")
    }
    
    public func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        NSLog("%@", "foundPeer: \(peerID)")
        if(!nearbyPeers.contains(peerID)){
            nearbyPeers.append(peerID)
        }
        NotificationCenter.default.post(name: .reloadQueues, object: nil)
        if(peerID == connectedQueue){
            invitePeerToConnect(peer: peerID, browser: self.serviceBrowser)
        }
    }
    
    public func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        NSLog("%@", "lostPeer: \(peerID)")
        if(nearbyPeers.count != 0){
            for x in 0...nearbyPeers.count-1 {
                if(nearbyPeers[x].isEqual(peerID)){
                    print("in here")
                    nearbyPeers.remove(at: x)
                    break
                }
            }
        }
        NotificationCenter.default.post(name: .reloadQueues, object: nil)
    }
    
}

extension ConnectionManager : MCSessionDelegate {
    
    public func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        NSLog("%@", "peer \(peerID) didChangeState: \(state.rawValue)")
        self.delegate?.connectedDevicesChanged(manager: self, connectedDevices:
            session.connectedPeers.map{$0.displayName})
        NotificationCenter.default.post(name: .reload, object: nil)
        if(state.rawValue == 0){
            if(peerID == connectedQueue){
                invitePeerToConnect(peer: peerID, browser: self.serviceBrowser)
                NotificationCenter.default.post(name: .connectedToQueue, object: nil)
            }
        } else if(state.rawValue == 2){
            connectedQueue = peerID
            NotificationCenter.default.post(name: .connectedToQueue, object: nil)
        }
        if(session.connectedPeers.count == 8){
            serviceAdvertiser.stopAdvertisingPeer()
        }
    }
    
    public func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        NSLog("%@", "didReceiveData: \(data)")
        self.handleRecievedData(data: data)
    }
    
    public func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        NSLog("%@", "didReceiveStream")
    }
    
    public func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        NSLog("%@", "didStartReceivingResourceWithName")
    }
    
    public func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
        NSLog("%@", "didFinishReceivingResourceWithName")
    }
    
}

extension Notification.Name {
    static let reload = Notification.Name("reload")
    static let reloadQueues = Notification.Name("reloadQueues")
    static let playerDataRecieved = Notification.Name("playerDataReceived")
    static let actionDataRecieved = Notification.Name("actionDataReceived")
    static let connectedToQueue = Notification.Name("connectedToQueue")
}
