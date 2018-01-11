//
//  JoinQueueViewController.swift
//  Queue It
//
//  Created by Nikhil Sharma on 7/16/17.
//  Copyright © 2017 Nikhil Sharma. All rights reserved.
//
// this class needs to use an instance of connection manager to browse the nearby services being
// advertised and then connect to the nearby service

import Foundation
import UIKit
import MultipeerConnectivity

public class JoinQueueViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet var queuesToConnectTableView: UITableView!
    @IBOutlet var connectedQueueLabel: UILabel!
    
    var connectionManager = ConnectionManager.init()
    var tempUserLib: UserLibrary?
    var connectedQueueName = ""
    
    override public func viewDidLoad() {
        connectedQueueLabel.text = connectedQueueName
        connectionManager.isQueueCreator = false
        connectionManager.serviceBrowser.startBrowsingForPeers()
        queuesToConnectTableView.reloadData()
        NotificationCenter.default.addObserver(self, selector: #selector(reloadTableData), name: .reloadQueues, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(connectedToQueue), name: .connectedToQueue, object: nil)

    }
    
    override public func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        UIApplication.shared.statusBarStyle = .lightContent
    }
    
    override public var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    public func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func connectedToQueue(){
        DispatchQueue.main.async {
            if(self.connectionManager.session.connectedPeers.count == 0){
                self.connectedQueueLabel.text = ""
            } else {
                self.connectedQueueLabel.text = "Connected to: " + self.connectionManager.connectedQueue.displayName
            }
        }
    }
    //returns the amount of cells
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return connectionManager.nearbyPeers.count
    }
    
    //populates cells with names
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "availableQCell", for: indexPath)
        cell.textLabel?.textColor = UIColor.white
        cell.textLabel?.text = connectionManager.nearbyPeers[indexPath.item].displayName
        return cell
    }
    
    //reacts to touches on cells
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        queuesToConnectTableView.deselectRow(at: indexPath, animated: true)
        connectionManager.invitePeerToConnect(peer: connectionManager.nearbyPeers[indexPath.item], browser: connectionManager.serviceBrowser)
    }
    
    // reload from notification
    func reloadTableData(_ notification: Notification) {
        print("reload table data")
        DispatchQueue.main.async {
            self.queuesToConnectTableView.reloadData()
        }
        for peer in connectionManager.nearbyPeers {
            print(peer)
        }
    }
    
    override public func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showJoinLibrary" {
            let ExchangeViewData = segue.destination as! QueueJoinerViewController
            ExchangeViewData.connectionManager = connectionManager
            ExchangeViewData.connectedQueueName = connectedQueueLabel.text!
            ExchangeViewData.userLibrary = tempUserLib!
            print("userlib")
            for list in tempUserLib!.playlists {
                print(list.name)
            }
            for track in tempUserLib!.savedTracks {
                print(track.name)
            }
            print("to show lib")
        } else if(segue.identifier == "backToMenu"){
            let ExchangeViewData = segue.destination as! MenuViewController
            ExchangeViewData.userLibrary = tempUserLib!
            connectionManager.resetConnectedQueue()
            connectionManager.session.disconnect()
            connectionManager.disconnectFromAll()
            connectionManager.serviceBrowser.stopBrowsingForPeers()
            connectionManager.serviceAdvertiser.stopAdvertisingPeer()
            print("back to menu")
        }

    }

}
