//
//  QueueJoinerViewController.swift
//  Queue It
//
//  Created by Nikhil Sharma on 7/16/17.
//  Copyright © 2017 Nikhil Sharma. All rights reserved.
//
// this class will use the connection already established from the connection manager to recieve
// the queue from the queue creator and to send the creator tracks to add to the queue

import Foundation
import UIKit

public class QueueJoinerViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, SPTAudioStreamingPlaybackDelegate, SPTAudioStreamingDelegate, UISearchBarDelegate {
    
    //OUTLETS
    @IBOutlet var tableview: UITableView!
    @IBOutlet var nowPlaying: UILabel!
    @IBOutlet var playPauseLabel: UIButton!
    @IBOutlet var searchBar: UISearchBar!
    @IBOutlet var tableviewLoadingCircle: UIActivityIndicatorView!
    @IBOutlet var loadingCircleView: UIView!
    @IBOutlet var shuffleLabel: UIButton!
    
    
    //ACTIONS
    @IBAction func songsPressed(_ sender: Any) {
        tableviewLoadingCircle.isHidden = true
        loadingCircleView.isHidden = true
        typeOfTableViewData = 1
        typeOfDataInView = 1
        tableviewData = userLibrary.savedTracks
        if(tableviewData.count == 0){
            tableviewLoadingCircle.isHidden = false
            loadingCircleView.isHidden = false
            tableviewLoadingCircle.startAnimating()
        }
        tableview.reloadData()
        print(userLibrary.savedTracks.count)
        for track in userLibrary.savedTracks {
            print(track.name)
        }
    }
    @IBAction func playlistsPressed(_ sender: Any) {
        tableviewLoadingCircle.isHidden = true
        loadingCircleView.isHidden = true
        typeOfTableViewData = 2
        typeOfDataInView = 2
        tableviewData = userLibrary.playlists
        if(tableviewData.count == 0){
            tableviewLoadingCircle.isHidden = false
            loadingCircleView.isHidden = false
            tableviewLoadingCircle.startAnimating()
        }
        tableview.reloadData()
    }
    @IBAction func queuePressed(_ sender: Any) {
        tableviewLoadingCircle.isHidden = true
        loadingCircleView.isHidden = true
        typeOfDataInView = 4
        typeOfTableViewData = 1
        songPlayer.upNext = self.connectionManager.playerDataToHandle.upNext
        nowPlaying.text = connectionManager.playerDataToHandle.nowPlaying.name
        tableviewData = songPlayer.theQueue
        tableview.reloadData()
    }
    @IBAction func playPausePressed(_ sender: Any) {
        connectionManager.send(action: "Play Pause Pressed", peer: self.connectionManager.session.connectedPeers)
        connectionManager.send(player: self.songPlayer, peer: self.connectionManager.session.connectedPeers)
    }
    @IBAction func nextPressed(_ sender: Any) {
        print("next pressed")
        connectionManager.send(action: "Next Pressed", peer: self.connectionManager.session.connectedPeers)
        connectionManager.send(player: self.songPlayer, peer: self.connectionManager.session.connectedPeers)
    }
    @IBAction func shufflePressed(_ sender: Any) {
        if(songPlayer.upNext.count != 0){
            songPlayer.toggleShuffleUpNext()
            if(songPlayer.upNextIsShuffled){
                DispatchQueue.main.async {
                    self.shuffleLabel.titleLabel?.text = "Shuffle: On"
                }
            } else {
                DispatchQueue.main.async {
                    self.shuffleLabel.titleLabel?.text = "Shuffle: Off"
                }
            }
            tableview.reloadData()
            connectionManager.send(action: "Shuffle Pressed", peer: self.connectionManager.session.connectedPeers)
            connectionManager.send(player: self.songPlayer, peer: self.connectionManager.session.connectedPeers)
        }
    }
    
    
    //FIELDS
    var auth = SPTAuth.defaultInstance()
    var connectionManager = ConnectionManager.init()
    var userLibrary = UserLibrary(tempName: "temp")
    var songPlayer = SongPlayer.init()
    var tableviewData = [Any]()
    // 1 = track, 2 = playlist, 3 = artist
    var typeOfTableViewData = 1
    var actionSheet = UIAlertController(title: "Title", message: "Message", preferredStyle: .actionSheet)
    var actionQueueSheet = UIAlertController(title: "Title", message: "Message", preferredStyle: .actionSheet)
    var songPressedOn = SpotifyTrack()
    // 1 = saved songs, 2 = playlists, 3 = tracks in playlist, 4 = queue, 5 = search
    var typeOfDataInView = 1
    var currentClickedOnTrack = SpotifyTrack()
    var selectedPlaylistNum = -1
    var connectedQueueName = ""
    
    override public func viewDidLoad() {

        // delegate song player
        self.songPlayer.player.delegate = self
        self.songPlayer.player.playbackDelegate = self
        self.setUpActionSheets()
        
        //keyboard dismiss with tap
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(QueueJoinerViewController.dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
        
        // notification center
        NotificationCenter.default.addObserver(self, selector: #selector(handlePlayerData), name: .playerDataRecieved, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleActionData), name: .actionDataRecieved, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(reloadTableData), name: .reload, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(reloadTableData), name: .songsLoaded, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(reloadTableData), name: .playlistsLoaded, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(reloadTableData), name: .playlistTracksLoaded, object: nil)
        
        tableviewLoadingCircle.isHidden = true
        loadingCircleView.isHidden = true
        
        
    }
    
    override public func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        UIApplication.shared.statusBarStyle = .lightContent
    }
    
    override public var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    func setUpActionSheets(){
        //Action Sheet
        actionSheet.addAction(UIAlertAction(title: "Play Now", style: UIAlertActionStyle.default, handler: { callback in
            self.nowPlaying.text = self.currentClickedOnTrack.name
            self.songPlayer.nowPlaying = self.currentClickedOnTrack
            self.connectionManager.send(action: "Play Now", peer: self.connectionManager.session.connectedPeers)
            self.connectionManager.send(player: self.songPlayer, peer: self.connectionManager.session.connectedPeers)
        }))
        actionSheet.addAction(UIAlertAction(title: "Add To Queue", style: UIAlertActionStyle.default, handler: { callback in
            self.songPlayer.theQueue.append(self.currentClickedOnTrack)
            if(self.typeOfDataInView == 4){
                self.tableviewData = self.songPlayer.theQueue
                self.tableview.reloadData()
            }
            self.connectionManager.send(action: "Add To Queue", peer: self.connectionManager.session.connectedPeers)
            self.connectionManager.send(player: self.songPlayer, peer: self.connectionManager.session.connectedPeers)
        }))
        actionSheet.addAction(UIAlertAction(title: "Play Next", style: UIAlertActionStyle.default, handler: { callback in
            if(self.songPlayer.theQueue.count == 0){
                self.songPlayer.theQueue.append(self.currentClickedOnTrack)
            } else {
                let count = self.songPlayer.theQueue.count - 1
                self.songPlayer.theQueue.append(SpotifyTrack())
                for x in 0...count {
                    let y = count - x
                    self.songPlayer.theQueue[y+1] = self.songPlayer.theQueue[y]
                }
                self.songPlayer.theQueue[0] = self.currentClickedOnTrack
            }
            if(self.typeOfDataInView == 4){
                self.tableviewData = self.songPlayer.theQueue
                self.tableview.reloadData()
            }
            self.nowPlaying.text = self.currentClickedOnTrack.name
            self.connectionManager.send(action: "Play Next", peer: self.connectionManager.session.connectedPeers)
            self.connectionManager.send(player: self.songPlayer, peer: self.connectionManager.session.connectedPeers)
        }))
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel, handler: nil))
        
        //Queue Action Sheet
        actionQueueSheet.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel, handler: nil))
        actionQueueSheet.addAction(UIAlertAction(title: "Remove From Queue", style: UIAlertActionStyle.default, handler: { callback in
            for x in 0...self.songPlayer.theQueue.count-1 {
                if(self.songPlayer.theQueue[x].isEqual(self.currentClickedOnTrack)){
                    self.songPlayer.theQueue.remove(at: x)
                    break
                }
            }
            self.tableviewData = self.songPlayer.theQueue
            self.tableview.reloadData()
            self.connectionManager.send(action: "Removed From Queue", peer: self.connectionManager.session.connectedPeers)
            self.connectionManager.send(player: self.songPlayer, peer: self.connectionManager.session.connectedPeers)
        }))
    }

    public func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    //returns the amount of cells
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if(self.typeOfDataInView == 4){
            return self.tableviewData.count + self.songPlayer.upNext.count + 1
        }
        return self.tableviewData.count
    }
    
    //populates cells with names
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "tableviewCell", for: indexPath)
        if(typeOfDataInView == 4){
            if(indexPath.item == tableviewData.count){
                (cell as! MyCustomCell).songTitle.text = ""
                (cell as! MyCustomCell).artistName.text = ""
                cell.textLabel?.text = "Up Next Tracks"
            } else if(indexPath.item > tableviewData.count){
                cell.textLabel?.text = ""
                (cell as! MyCustomCell).songTitle.text = (songPlayer.upNext[indexPath.item-tableviewData.count-1] ).name
                var artistNames = ""
                for artist in (songPlayer.upNext[indexPath.item-tableviewData.count-1] ).artists {
                    artistNames.append(artist + ", ")
                }
                (cell as! MyCustomCell).artistName.text = artistNames
            } else {
                cell.textLabel?.text = ""
                (cell as! MyCustomCell).songTitle.text = (tableviewData[indexPath.item] as! SpotifyTrack).name
                var artistNames = ""
                for artist in (tableviewData[indexPath.item] as! SpotifyTrack).artists {
                    artistNames.append(artist + ", ")
                }
                (cell as! MyCustomCell).artistName.text = artistNames
            }
        } else if(typeOfTableViewData == 1){
            cell.textLabel?.text = ""
            (cell as! MyCustomCell).songTitle.text = (tableviewData[indexPath.item] as! SpotifyTrack).name
            var artistNames = ""
            for artist in (tableviewData[indexPath.item] as! SpotifyTrack).artists {
                artistNames.append(artist + ", ")
            }
            (cell as! MyCustomCell).artistName.text = artistNames
        } else if(typeOfTableViewData == 2){
            (cell as! MyCustomCell).songTitle.text = (tableviewData[indexPath.item] as! SpotifyPlaylist).name
            (cell as! MyCustomCell).artistName.text = ""
            cell.textLabel?.text = ""
        }
        cell.textLabel?.textColor = UIColor.white
        return cell
    }
    
    //reacts to touches on cells
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableview.deselectRow(at: indexPath, animated: true)
        if(typeOfDataInView == 2){
            tableviewLoadingCircle.stopAnimating()
            typeOfDataInView = 3
            typeOfTableViewData = 1
            selectedPlaylistNum = indexPath.item
            songPlayer.upNext = (tableviewData[indexPath.item] as! SpotifyPlaylist).tracks
            tableviewData = (tableviewData[indexPath.item] as! SpotifyPlaylist).tracks
            if(tableviewData.count == 0){
                tableviewLoadingCircle.startAnimating()
                tableviewLoadingCircle.isHidden = false
                loadingCircleView.isHidden = false
            }
            tableview.reloadData()
        } else if(typeOfDataInView == 4) {
            if(songPlayer.theQueue.count == indexPath.item){
                if(indexPath.item == 0){
                    return
                }
            }
            if(indexPath.item > tableviewData.count){
                actionQueueSheet.title = songPlayer.upNext[indexPath.item-tableviewData.count-1].name
                actionSheet.title = songPlayer.upNext[indexPath.item-tableviewData.count-1].name
                var artistNames = ""
                for artist in songPlayer.upNext[indexPath.item-tableviewData.count-1].artists {
                    artistNames.append(artist + ", ")
                }
                currentClickedOnTrack = songPlayer.upNext[indexPath.item-tableviewData.count-1]
                actionSheet.message = artistNames
                actionQueueSheet.message = artistNames
            } else {
                actionQueueSheet.title = (tableviewData[indexPath.item] as! SpotifyTrack).name
                actionSheet.title = (tableviewData[indexPath.item] as! SpotifyTrack).name
                var artistNames = ""
                for artist in (tableviewData[indexPath.item] as! SpotifyTrack).artists {
                    artistNames.append(artist + ", ")
                }
                currentClickedOnTrack = tableviewData[indexPath.item] as! SpotifyTrack
                actionSheet.message = artistNames
                actionQueueSheet.message = artistNames
            }
            if(indexPath.item > songPlayer.theQueue.count-1){
                self.present(actionSheet, animated: true, completion: nil)
            } else {
                self.present(actionQueueSheet, animated: true, completion: nil)
            }
        } else {
            actionSheet.title = (tableviewData[indexPath.item] as! SpotifyTrack).name
            var artistNames = ""
            for artist in (tableviewData[indexPath.item] as! SpotifyTrack).artists {
                artistNames.append(artist + ", ")
            }
            currentClickedOnTrack = tableviewData[indexPath.item] as! SpotifyTrack
            actionSheet.message = artistNames
            self.present(actionSheet, animated: true, completion: nil)
        }
    }
    
    //send connections manager back and forth
    override public func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "backToJoinQueue" {
            let ExchangeViewData = segue.destination as! JoinQueueViewController
            ExchangeViewData.connectionManager = connectionManager
            ExchangeViewData.tempUserLib = userLibrary
            print("userlib")
            for list in userLibrary.playlists {
                print(list.name)
            }
            for track in userLibrary.savedTracks {
                print(track.name)
            }
            ExchangeViewData.connectedQueueName = connectedQueueName
            print("back to join")
        }
    }
    
    //reload data table for data send to q
    func reloadTableData(_ notification: Notification) {
            if(self.typeOfDataInView == 1){
                tableviewData = self.userLibrary.savedTracks
            } else if(self.typeOfDataInView == 2){
                tableviewData = self.userLibrary.playlists
            } else if(self.typeOfDataInView == 3){
                tableviewData = self.userLibrary.playlists[selectedPlaylistNum].tracks
            }
        DispatchQueue.main.async {
            self.tableviewLoadingCircle.stopAnimating()
            self.tableviewLoadingCircle.isHidden = true
            self.loadingCircleView.isHidden = true
            self.tableview.reloadData()
        }
    }
    
    func handlePlayerData(_ notification: Notification) {
        DispatchQueue.main.async {
            
        }
    }
    
    func handleActionData(_ notification: Notification) {
        let action = self.connectionManager.actionDataToHandle
        if(action == "Queue Pressed"){
            print("queue pressed")
            DispatchQueue.main.async {
                self.songPlayer.upNext = self.connectionManager.playerDataToHandle.upNext
                self.tableview.reloadData()
            }
        } else if(action == "Play Pause Pressed"){
            print("play pause pressed")
            DispatchQueue.main.async {
                if(self.connectionManager.playerDataToHandle.isPlaying){
                    self.playPauseLabel.titleLabel?.text = "Pause"
                } else {
                    self.playPauseLabel.titleLabel?.text = "Play"
                }
            }
        } else if(action == "Next Pressed"){
            print("next pressed")
            DispatchQueue.main.async {
                if(self.typeOfDataInView == 4){
                    self.tableviewData = self.connectionManager.playerDataToHandle.theQueue
                    self.songPlayer.upNext = self.connectionManager.playerDataToHandle.upNext
                    self.tableview.reloadData()
                }
                self.nowPlaying.text = self.connectionManager.playerDataToHandle.nowPlaying.name
            }
        } else if(action == "Shuffle Pressed"){
            print("shuffle Pressed")
            self.songPlayer.upNext = self.connectionManager.playerDataToHandle.upNext
            if(self.connectionManager.playerDataToHandle.upNextIsShuffled){
                DispatchQueue.main.async {
                    self.shuffleLabel.titleLabel?.text = "Shuffle: On"
                    self.tableview.reloadData()
                }
            } else {
                DispatchQueue.main.async {
                    self.shuffleLabel.titleLabel?.text = "Shuffle: Off"
                    self.tableview.reloadData()
                }
            }
        } else if(action == "Play Now"){
            print("play now")
            if(self.typeOfDataInView == 4){
                DispatchQueue.main.async {
                    self.tableviewData = self.connectionManager.playerDataToHandle.theQueue
                    self.tableview.reloadData()
                }
            }
            DispatchQueue.main.async {
                self.nowPlaying.text = self.connectionManager.playerDataToHandle.nowPlaying.name
            }
        } else if(action == "Add To Queue"){
            print("add to queue")
            if(self.typeOfDataInView == 4){
                DispatchQueue.main.async {
                    self.tableviewData = self.connectionManager.playerDataToHandle.theQueue
                    self.tableview.reloadData()
                }
            }
            DispatchQueue.main.async {
                self.songPlayer.theQueue = self.connectionManager.playerDataToHandle.theQueue
            }
        } else if(action == "Play Next"){
            print("play next")
            if(self.typeOfDataInView == 4){
                DispatchQueue.main.async {
                    self.tableviewData = self.connectionManager.playerDataToHandle.theQueue
                    self.tableview.reloadData()
                }
            }
            DispatchQueue.main.async {
                self.songPlayer.theQueue = self.connectionManager.playerDataToHandle.theQueue
            }
        } else if(action == "Send Queue"){
            print("q recieved")
            self.songPlayer.theQueue = self.connectionManager.playerDataToHandle.theQueue
            self.songPlayer.upNext = self.connectionManager.playerDataToHandle.upNext
            DispatchQueue.main.async {
                self.nowPlaying.text = self.connectionManager.playerDataToHandle.nowPlaying.name
            }
            if(self.typeOfDataInView == 4){
                DispatchQueue.main.async {
                    self.tableviewData = self.connectionManager.playerDataToHandle.theQueue
                    self.tableview.reloadData()
                }
            }
        } else if(action == "Removed From Queue"){
            print("removed from queue")
            self.songPlayer.theQueue = self.connectionManager.playerDataToHandle.theQueue
            DispatchQueue.main.async {
                if(self.typeOfDataInView == 4){
                    self.tableviewData = self.connectionManager.playerDataToHandle.theQueue
                    self.tableview.reloadData()
                }
            }
        }
    
    }
    
    func dismissKeyboard() {
        view.endEditing(true)
        self.tableview.isUserInteractionEnabled = true
    }
    
    public func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        view.endEditing(true)
    }
    
    public func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        userLibrary.searchForTrack(searchText: searchText) { searchResults in
            self.typeOfDataInView = 5
            self.typeOfTableViewData = 1
            self.tableviewData = searchResults!
            self.tableview.reloadData()
            self.tableview.isUserInteractionEnabled = false
        }
    }

}
