//
//  CreateQueueViewController.swift
//  Queue It
//
//  Created by Nikhil Sharma on 7/16/17.
//  Copyright © 2017 Nikhil Sharma. All rights reserved.
//
// this class needs to use and instance of connections manager to advertise its service and
// connect to devices that want to join the queue
// 

import Foundation
import UIKit
import MultipeerConnectivity
import AVFoundation

public class CreateQueueViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet var connectedDevicesTableView: UITableView!
    @IBOutlet var queueNameTextField: UITextField!
    
    var connectionManager = ConnectionManager.init()
    var tempSongPlayer: SongPlayer?
    var tempUserLib: UserLibrary?
    
    override public func viewDidLoad() {
        connectionManager.isQueueCreator = true
        connectionManager.serviceAdvertiser.startAdvertisingPeer()
        connectedDevicesTableView.reloadData()
        NotificationCenter.default.addObserver(self, selector: #selector(reloadTableData), name: .reload, object: nil)
        queueNameTextField.text = connectionManager.session.myPeerID.displayName
        // changing queue name
        queueNameTextField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(QueueJoinerViewController.dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
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
    
    //returns the amount of cells
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return connectionManager.session.connectedPeers.count
    }
    
    //populates cells with names
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "connectedPeerCell", for: indexPath)
        cell.textLabel?.textColor = UIColor.white
        cell.textLabel?.text = connectionManager.session.connectedPeers[indexPath.item].displayName
        return cell
    }
    
    //reacts to touches on cells
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        connectedDevicesTableView.deselectRow(at: indexPath, animated: true)
    }
    
    // reload from notification
    func reloadTableData(_ notification: Notification) {
        DispatchQueue.main.async {
            self.connectedDevicesTableView.reloadData()
        }
    }
    
    // text field changed
    func textFieldDidChange(_ textField: UITextField) {
        // changing queue name
        if(textField.text != ""){
            connectionManager.myPeerId = MCPeerID.init(displayName: textField.text!)
        }
    }
    
    func dismissKeyboard() {
        view.endEditing(true)
    }
    
    override public func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if(segue.identifier == "showCreateLibrary") {
            let ExchangeViewData = segue.destination as! QueueCreatorViewController
            ExchangeViewData.connectionManager = connectionManager
            if(tempSongPlayer != nil){  
                ExchangeViewData.songPlayer = tempSongPlayer!
            }
            ExchangeViewData.userLibrary = tempUserLib!
            print("userlib")
            for list in tempUserLib!.playlists {
                print(list.name)
            }
            for track in tempUserLib!.savedTracks {
                print(track.name)
            }
            print("to create lib")
        } else if(segue.identifier == "backToMenu"){
            let ExchangeViewData = segue.destination as! MenuViewController
            ExchangeViewData.userLibrary = tempUserLib!
            self.connectionManager.session.disconnect()
            self.connectionManager.disconnectFromAll()
            self.connectionManager.serviceAdvertiser.stopAdvertisingPeer()
            deactivateAudioSession()
            print("back to menu")
        }
    }
    
    func deactivateAudioSession() {
        try? AVAudioSession.sharedInstance().setActive(false)
    }
}
