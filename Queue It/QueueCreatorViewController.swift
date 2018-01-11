//
//  QueueCreaterViewController.swift
//  Queue It
//
//  Created by Nikhil Sharma on 7/16/17.
//  Copyright © 2017 Nikhil Sharma. All rights reserved.
//
// this class will use the connection already established from the connection manager to send
// the queue to the queue joiners and to recieve the joiners tracks to add to the queue

import Foundation
import UIKit
import AVFoundation

public class QueueCreatorViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, SPTAudioStreamingPlaybackDelegate, SPTAudioStreamingDelegate, UISearchBarDelegate  {
    
    //REMOVE COMMAS IN ARTIST NAMES**************
    //FIX PLAY PAUSE BUTTON
    
    //OUTLETS
    @IBOutlet var tableview: UITableView!
    @IBOutlet var nowPlaying: UILabel!
    @IBOutlet var playPauseLabel: UIButton!
    @IBOutlet var searchBar: UISearchBar!
    @IBOutlet var loadingCircleView: UIView!
    @IBOutlet var loadingCircle: UIActivityIndicatorView!
    @IBOutlet var shuffleLabel: UIButton!
    
    //ACTIONS
    @IBAction func playlistPressed(_ sender: Any) {
        loadingCircle.isHidden = true
        loadingCircleView.isHidden = true
        typeOfTableViewData = 2
        typeOfDataInView = 2
        tableviewData = userLibrary.playlists
        if(tableviewData.count == 0){
            loadingCircle.isHidden = false
            loadingCircleView.isHidden = false
            loadingCircle.startAnimating()
        }
        tableview.reloadData()
        
    }
    @IBAction func songsPressed(_ sender: Any) {
        loadingCircle.isHidden = true
        loadingCircleView.isHidden = true
        typeOfTableViewData = 1
        typeOfDataInView = 1
        self.connectionManager.send(player: self.songPlayer, peer: self.connectionManager.session.connectedPeers)
        self.connectionManager.send(action: "Queue Pressed", peer: self.connectionManager.session.connectedPeers)
        tableviewData = userLibrary.savedTracks
        if(tableviewData.count == 0){
            loadingCircle.isHidden = false
            loadingCircleView.isHidden = false
            loadingCircle.startAnimating()
        }
        tableview.reloadData()
    }
    @IBAction func queuePressed(_ sender: Any) {
        loadingCircle.isHidden = true
        loadingCircleView.isHidden = true
        typeOfDataInView = 4
        typeOfTableViewData = 1
        tableviewData = songPlayer.theQueue
        tableview.reloadData()
    }
    @IBAction func shufflePressed(_ sender: Any) {
        if(songPlayer.theQueue.count == 0){
            for x in 0...self.shuffleActionSheet.actions.count-1 {
                if(self.shuffleActionSheet.actions[x].title == "Shuffle Queue"){
                    self.shuffleActionSheet.actions[x].isEnabled = false
                }
            }
        }
        self.typeOfDataInView = 4
        present(shuffleActionSheet, animated: true, completion: nil)
    }
    @IBAction func playPausePressed(_ sender: Any) {
        songPlayer.togglePlay()
    }
    @IBAction func nextPressed(_ sender: Any) {
        songPlayer.skipTrack(){ error in
            if(self.typeOfDataInView == 4){
                self.tableviewData = self.songPlayer.theQueue
                self.tableview.reloadData()
            }
            self.nowPlaying.text = self.songPlayer.nowPlaying.name
            self.playPauseLabel.titleLabel?.text = "Pause"
            self.connectionManager.send(player: self.songPlayer, peer: self.connectionManager.session.connectedPeers)
            self.connectionManager.send(action: "Next Pressed", peer: self.connectionManager.session.connectedPeers)
        }
    }
    
    //FIELDS
    var auth = SPTAuth.defaultInstance()
    var connectionManager = ConnectionManager.init()
    var userLibrary = UserLibrary(tempName: "temp")
    var songPlayer = SongPlayer.init()
    var tableviewData = [Any]()
    // 1 = track, 2 = playlist, 3 = artist, 4 = up next names
    var typeOfTableViewData = 1
    var actionSheet = UIAlertController(title: "Title", message: "Message", preferredStyle: .actionSheet)
    var actionQueueSheet = UIAlertController(title: "Title", message: "Message", preferredStyle: .actionSheet)
    var actionUpNextSheet = UIAlertController(title: "Title", message: "Message", preferredStyle: .actionSheet)
    var shuffleActionSheet = UIAlertController(title: "Title", message: "Message", preferredStyle: .actionSheet )
    var songPressedOn = SpotifyTrack()
    // 1 = saved songs, 2 = playlists, 3 = tracks in playlist, 4 = queue, 5 = search, 6 = Up Next Selection
    var typeOfDataInView = 1
    var currentClickedOnTrack = SpotifyTrack()
    var currentClickedOnPlaylist = ""
    var selectedPlaylistNum = -1
    
    //METHODS
    override public func viewDidLoad() {
        print("userlib")
        for list in userLibrary.playlists {
            print(list.name)
        }
        for track in userLibrary.savedTracks {
            print(track.name)
        }
        if(!self.songPlayer.player.initialized){
            self.songPlayer.player = SPTAudioStreamingController.sharedInstance()
            self.songPlayer.player.delegate = self
            self.songPlayer.player.playbackDelegate = self
            do{
                try self.songPlayer.player.start(withClientId: self.auth?.clientID)
            } catch is Error {
                print("fack")
            }
            if(self.auth?.session.isValid())!{
                self.songPlayer.player.login(withAccessToken: self.auth?.session.accessToken!)
            }
        } else {
            self.nowPlaying.text = songPlayer.nowPlaying.name
        }
        self.setUpActionSheets()
        
        //keyboard dismiss with tap
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(QueueJoinerViewController.dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
        
        NotificationCenter.default.addObserver(self, selector: #selector(handlePlayerData), name: .playerDataRecieved, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleActionData), name: .actionDataRecieved, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(reloadTableData), name: .reload, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(reloadTableDataCircle), name: .songsLoaded, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(reloadTableDataCircle), name: .playlistsLoaded, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(reloadTableDataCircle), name: .playlistTracksLoaded, object: nil)
        activateAudioSession()
        
        loadingCircle.isHidden = true
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
        // Action Sheet
        actionSheet.addAction(UIAlertAction(title: "Play Now", style: UIAlertActionStyle.default, handler: { callback in
            self.songPlayer.player.playSpotifyURI(self.currentClickedOnTrack.URI, startingWith: 0, startingWithPosition: 0, callback: { error in
                if(error != nil){
                    print(error)
                }
            })
            self.songPlayer.nowPlaying = self.currentClickedOnTrack
            self.nowPlaying.text = self.currentClickedOnTrack.name
            self.connectionManager.send(player: self.songPlayer, peer: self.connectionManager.session.connectedPeers)
            self.connectionManager.send(action: "Play Now", peer: self.connectionManager.session.connectedPeers)
        }))
        actionSheet.addAction(UIAlertAction(title: "Add To Queue", style: UIAlertActionStyle.default, handler: { callback in
            self.songPlayer.theQueue.append(self.currentClickedOnTrack)
            if(self.typeOfDataInView == 4){
                self.tableviewData = self.songPlayer.theQueue
                self.tableview.reloadData()
            }
            self.songPlayer.unShuffledQueue = self.songPlayer.theQueue
            self.songPlayer.queueIsShuffled = false
            for x in 0...self.shuffleActionSheet.actions.count-1 {
                if(self.shuffleActionSheet.actions[x].title == "Shuffle Queue"){
                    self.shuffleActionSheet.actions[x].isEnabled = true
                } else if(self.shuffleActionSheet.actions[x].title == "Unshuffle Queue"){
                    self.shuffleActionSheet.actions[x].isEnabled = false
                }
            }
            self.connectionManager.send(player: self.songPlayer, peer: self.connectionManager.session.connectedPeers)
            self.connectionManager.send(action: "Add To Queue", peer: self.connectionManager.session.connectedPeers)
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
            self.songPlayer.unShuffledQueue = self.songPlayer.theQueue
            self.songPlayer.queueIsShuffled = false
            for x in 0...self.shuffleActionSheet.actions.count-1 {
                if(self.shuffleActionSheet.actions[x].title == "Shuffle Queue"){
                    self.shuffleActionSheet.actions[x].isEnabled = true
                } else if(self.shuffleActionSheet.actions[x].title == "Unshuffle Queue"){
                    self.shuffleActionSheet.actions[x].isEnabled = false
                }
            }
            self.connectionManager.send(player: self.songPlayer, peer: self.connectionManager.session.connectedPeers)
            self.connectionManager.send(action: "Play Next", peer: self.connectionManager.session.connectedPeers)
        }))
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel, handler: nil))
        
        //Queue Action Sheet
        actionQueueSheet.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel, handler: nil))
        actionQueueSheet.addAction(UIAlertAction(title: "Remove From Queue", style: UIAlertActionStyle.default, handler: { callback in
            print(self.currentClickedOnTrack.name)
            for x in 0...self.songPlayer.theQueue.count-1 {
                if(self.songPlayer.theQueue[x].isEqual(self.currentClickedOnTrack)){
                    self.songPlayer.theQueue.remove(at: x)
                    break
                }
            }
            self.tableviewData = self.songPlayer.theQueue
            self.tableview.reloadData()
            self.songPlayer.unShuffledQueue = self.songPlayer.theQueue
            self.songPlayer.queueIsShuffled = false
            for x in 0...self.shuffleActionSheet.actions.count-1 {
                if(self.shuffleActionSheet.actions[x].title == "Shuffle Queue"){
                    self.shuffleActionSheet.actions[x].isEnabled = true
                } else if(self.shuffleActionSheet.actions[x].title == "Unshuffle Queue"){
                    self.shuffleActionSheet.actions[x].isEnabled = false
                }
            }
            self.connectionManager.send(player: self.songPlayer, peer: self.connectionManager.session.connectedPeers)
            self.connectionManager.send(action: "Removed From Queue", peer: self.connectionManager.session.connectedPeers)
        }))
        
        //Up Next Action Sheet
        actionUpNextSheet.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel, handler: nil))
        actionUpNextSheet.addAction(UIAlertAction(title: "Select Up Next", style: UIAlertActionStyle.default, handler: { callback in
            if(self.currentClickedOnPlaylist == "Saved Songs"){
                self.songPlayer.upNext = self.userLibrary.savedTracks
            } else {
                for playlist in self.userLibrary.playlists {
                    if(self.currentClickedOnPlaylist == playlist.name){
                        self.songPlayer.upNext = playlist.tracks
                    }
                }
            }
            self.typeOfDataInView = 4
            self.typeOfTableViewData = 1
            self.tableviewData = self.songPlayer.theQueue
            self.tableview.reloadData()
            self.connectionManager.send(player: self.songPlayer, peer: self.connectionManager.session.connectedPeers)
            self.connectionManager.send(action: "Send Queue", peer: self.connectionManager.session.connectedPeers)
        }))
        shuffleActionSheet.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel, handler: nil))
        shuffleActionSheet.addAction(UIAlertAction(title: "Shuffle Up Next", style: UIAlertActionStyle.default, handler: { callback in
            //shuffle up next
            if(self.songPlayer.upNext.count != 0){
                self.songPlayer.toggleShuffleUpNext()
                self.tableview.reloadData()
                self.connectionManager.send(player: self.songPlayer, peer: self.connectionManager.session.connectedPeers)
                self.connectionManager.send(action: "Shuffle Pressed", peer: self.connectionManager.session.connectedPeers)
            }
            for x in 0...self.shuffleActionSheet.actions.count-1 {
                if(self.shuffleActionSheet.actions[x].title == "Shuffle Up Next"){
                    self.shuffleActionSheet.actions[x].isEnabled = false
                } else if(self.shuffleActionSheet.actions[x].title == "Unshuffle Up Next"){
                    self.shuffleActionSheet.actions[x].isEnabled = true
                }
            }
        }))
        shuffleActionSheet.addAction(UIAlertAction(title: "Unshuffle Up Next", style: UIAlertActionStyle.default, handler: { callback in
            if(self.songPlayer.upNext.count != 0){
                self.songPlayer.toggleShuffleUpNext()
                self.tableview.reloadData()
                self.connectionManager.send(player: self.songPlayer, peer: self.connectionManager.session.connectedPeers)
                self.connectionManager.send(action: "Shuffle Pressed", peer: self.connectionManager.session.connectedPeers)
            }
            for x in 0...self.shuffleActionSheet.actions.count-1 {
                if(self.shuffleActionSheet.actions[x].title == "Shuffle Up Next"){
                    self.shuffleActionSheet.actions[x].isEnabled = true
                } else if(self.shuffleActionSheet.actions[x].title == "Unshuffle Up Next"){
                    self.shuffleActionSheet.actions[x].isEnabled = false
                }
            }
        }))
        shuffleActionSheet.addAction(UIAlertAction(title: "Shuffle Queue", style: UIAlertActionStyle.default, handler: { callback in
            if(self.songPlayer.theQueue.count != 0){
                self.songPlayer.toggleShuffleQueue()
                if(self.typeOfDataInView == 4){
                    self.tableviewData = self.songPlayer.theQueue
                }
                self.tableview.reloadData()
                self.connectionManager.send(player: self.songPlayer, peer: self.connectionManager.session.connectedPeers)
                self.connectionManager.send(action: "Shuffle Pressed", peer: self.connectionManager.session.connectedPeers)
            }
            for x in 0...self.shuffleActionSheet.actions.count-1 {
                if(self.shuffleActionSheet.actions[x].title == "Shuffle Queue"){
                    self.shuffleActionSheet.actions[x].isEnabled = false
                } else if(self.shuffleActionSheet.actions[x].title == "Unshuffle Queue"){
                    self.shuffleActionSheet.actions[x].isEnabled = true
                }
            }
        }))
        shuffleActionSheet.addAction(UIAlertAction(title: "Unshuffle Queue", style: UIAlertActionStyle.default, handler: { callback in
            if(self.songPlayer.theQueue.count != 0){
                self.songPlayer.toggleShuffleQueue()
                if(self.typeOfDataInView == 4){
                    self.tableviewData = self.songPlayer.theQueue
                }
                self.tableview.reloadData()
                self.connectionManager.send(player: self.songPlayer, peer: self.connectionManager.session.connectedPeers)
                self.connectionManager.send(action: "Shuffle Pressed", peer: self.connectionManager.session.connectedPeers)
            }
            for x in 0...self.shuffleActionSheet.actions.count-1 {
                if(self.shuffleActionSheet.actions[x].title == "Shuffle Queue"){
                    self.shuffleActionSheet.actions[x].isEnabled = true
                } else if(self.shuffleActionSheet.actions[x].title == "Unshuffle Queue"){
                    self.shuffleActionSheet.actions[x].isEnabled = false
                }
            }
        }))
        for x in 0...self.shuffleActionSheet.actions.count-1 {
            if(self.shuffleActionSheet.actions[x].title == "Unshuffle Up Next"){
                self.shuffleActionSheet.actions[x].isEnabled = false
            } else if(self.shuffleActionSheet.actions[x].title == "Unshuffle Queue"){
                self.shuffleActionSheet.actions[x].isEnabled = false
            }
        }
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
        if(typeOfTableViewData == 4){
            if(indexPath.item == 0){
                (cell as! MyCustomCell).songTitle.text = ""
                (cell as! MyCustomCell).artistName.text = ""
                cell.textLabel?.textColor = UIColor.white
                cell.textLabel?.text = "Up Next Selections"
            } else {
                (cell as! MyCustomCell).songTitle.text = tableviewData[indexPath.item-1] as! String
                (cell as! MyCustomCell).artistName.text = ""
                cell.textLabel?.text = ""
            }
        } else if(typeOfDataInView == 4){
            if(indexPath.item == tableviewData.count){
                (cell as! MyCustomCell).songTitle.text = ""
                (cell as! MyCustomCell).artistName.text = ""
                cell.textLabel?.textColor = UIColor.white
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
        
       return cell

    }
    
    //reacts to touches on cells
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableview.deselectRow(at: indexPath, animated: true)
        if(typeOfDataInView == 6){
            if(indexPath.item != 0){
                actionUpNextSheet.title = tableviewData[indexPath.item-1] as! String
                actionUpNextSheet.message = ""
                currentClickedOnPlaylist = tableviewData[indexPath.item-1] as! String
                self.present(actionUpNextSheet, animated: true, completion: nil)
            }
        } else if(typeOfDataInView == 2){
            loadingCircle.stopAnimating()
            typeOfDataInView = 3
            typeOfTableViewData = 1
            self.connectionManager.send(player: self.songPlayer, peer: self.connectionManager.session.connectedPeers)
            self.connectionManager.send(action: "Queue Pressed", peer: self.connectionManager.session.connectedPeers)
            tableviewData = (tableviewData[indexPath.item] as! SpotifyPlaylist).tracks
            if(tableviewData.count == 0){
                loadingCircle.startAnimating()
                loadingCircle.isHidden = false
                loadingCircleView.isHidden = false
            }
            tableview.reloadData()
        } else if(typeOfDataInView == 4) {
            // select up next code
            if(indexPath.item == songPlayer.theQueue.count){
                //clicked on up next
                typeOfDataInView = 6
                tableviewData = ["Saved Songs"]
                for list in userLibrary.playlists {
                    tableviewData.append(list.name)
                }
                typeOfTableViewData = 4
                tableview.reloadData()
            } else if(indexPath.item > tableviewData.count){
                actionQueueSheet.title = songPlayer.upNext[indexPath.item-tableviewData.count-1].name
                actionSheet.title = songPlayer.upNext[indexPath.item-tableviewData.count-1].name
                var artistNames = ""
                for artist in songPlayer.upNext[indexPath.item-tableviewData.count-1].artists {
                    artistNames.append(artist + ", ")
                }
                currentClickedOnTrack = songPlayer.upNext[indexPath.item-tableviewData.count-1]
                actionQueueSheet.message = artistNames
                actionSheet.message = artistNames
            } else {
                if(indexPath.item < tableviewData.count){
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
            }
            if(songPlayer.theQueue.count == 0 && indexPath.item == 0){
                
            } else if(songPlayer.theQueue.count == indexPath.item){
                
            } else if(indexPath.item > songPlayer.theQueue.count-1){
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
    
    override public func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "backToQueueCreate" {
            let ExchangeViewData = segue.destination as! CreateQueueViewController
            connectionManager.resetConnectedQueue()
            ExchangeViewData.connectionManager = connectionManager
            ExchangeViewData.tempSongPlayer = songPlayer
            ExchangeViewData.tempUserLib = userLibrary
            print("userlib")
            for list in userLibrary.playlists {
                print(list.name)
            }
            for track in userLibrary.savedTracks {
                print(track.name)
            }
            print("back to create")
        }
    }

    func reloadTableDataCircle(_ notification: Notification) {
        if(self.typeOfDataInView == 1){
            tableviewData = self.userLibrary.savedTracks
        } else if(self.typeOfDataInView == 2){
            tableviewData = self.userLibrary.playlists
        } else if(self.typeOfDataInView == 3){
            tableviewData = self.userLibrary.playlists[selectedPlaylistNum].tracks
        }
        DispatchQueue.main.async {
            self.loadingCircle.stopAnimating()
            self.loadingCircle.isHidden = true
            self.loadingCircleView.isHidden = true
            self.tableview.reloadData()
        }

    }
    
    func reloadTableData(_ notification: Notification) {
        DispatchQueue.main.async {
            print("sending queue")
            self.connectionManager.send(player: self.songPlayer, peer: self.connectionManager.session.connectedPeers)
            self.connectionManager.send(action: "Send Queue", peer: self.connectionManager.session.connectedPeers)
        }
    }
    
    func handlePlayerData(_ notification: Notification) {
        DispatchQueue.main.async {
            let action = self.connectionManager.actionDataToHandle
            if(action == "Queue Pressed"){
                
            } else if(action == "Play Pause Pressed"){
                self.songPlayer.togglePlay()
                if(self.connectionManager.session.connectedPeers.count > 1){
                    self.connectionManager.send(player: self.songPlayer, peer: self.connectionManager.session.connectedPeers)
                    self.connectionManager.send(action: "Play Pause Pressed", peer: self.connectionManager.session.connectedPeers)
                }
            } else if(action == "Next Pressed"){
                self.songPlayer.skipTrack(){ error in
                    if(self.typeOfDataInView == 4){
                        self.tableviewData = self.songPlayer.theQueue
                        self.tableview.reloadData()
                    }
                    print(self.songPlayer.nowPlaying.name)
                    self.nowPlaying.text = self.songPlayer.nowPlaying.name
                    self.playPauseLabel.titleLabel?.text = "Pause"
                    if(self.connectionManager.session.connectedPeers.count >= 1){
                        self.connectionManager.send(player: self.songPlayer, peer: self.connectionManager.session.connectedPeers)
                        self.connectionManager.send(action: "Next Pressed", peer: self.connectionManager.session.connectedPeers)
                    }
                }
            } else if(action == "Shuffle Pressed"){
                print("we here")
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
                let nowPlayingTrack = self.connectionManager.playerDataToHandle.nowPlaying
                self.songPlayer.playSong(track: nowPlayingTrack)
                self.songPlayer.nowPlaying = nowPlayingTrack
                self.nowPlaying.text = nowPlayingTrack.name
                if(self.connectionManager.session.connectedPeers.count > 1){
                    self.connectionManager.send(player: self.songPlayer, peer: self.connectionManager.session.connectedPeers)
                    self.connectionManager.send(action: "Play Now", peer: self.connectionManager.session.connectedPeers)
                }
            } else if(action == "Add To Queue"){
                print("appending qd track")
                let queuedTrack = self.connectionManager.playerDataToHandle.theQueue[self.connectionManager.playerDataToHandle.theQueue.count-1]
                if(queuedTrack != self.songPlayer.theQueue.last){
                    self.songPlayer.theQueue.append(queuedTrack)
                    if(self.typeOfDataInView == 4){
                        self.tableviewData = self.songPlayer.theQueue
                        self.tableview.reloadData()
                    }
                }
                if(self.connectionManager.session.connectedPeers.count > 1){
                    self.connectionManager.send(player: self.songPlayer, peer: self.connectionManager.session.connectedPeers)
                    self.connectionManager.send(action: "Add To Queue", peer: self.connectionManager.session.connectedPeers)
                }
            } else if(action == "Play Next"){
                let nextTrack = self.connectionManager.playerDataToHandle.theQueue[0]
                if(nextTrack != self.songPlayer.theQueue.first){
                    self.songPlayer.playNext(track: nextTrack)
                    if(self.typeOfDataInView == 4){
                        self.tableviewData = self.songPlayer.theQueue
                        self.tableview.reloadData()
                    }
                }
                if(self.connectionManager.session.connectedPeers.count > 1){
                    self.connectionManager.send(player: self.songPlayer, peer: self.connectionManager.session.connectedPeers)
                    self.connectionManager.send(action: "Play Next", peer: self.connectionManager.session.connectedPeers)
                }
            } else if(action == "Request Queue"){
                print("q requested")
                self.connectionManager.send(player: self.songPlayer, peer: self.connectionManager.session.connectedPeers)
                self.connectionManager.send(action: "Send Queue", peer: self.connectionManager.session.connectedPeers)
            } else if(action == "Removed From Queue"){
                self.songPlayer.theQueue = self.connectionManager.playerDataToHandle.theQueue
                DispatchQueue.main.async {
                    if(self.typeOfDataInView == 4){
                        self.tableviewData = self.connectionManager.playerDataToHandle.theQueue
                        self.tableview.reloadData()
                    }
                }
                if(self.connectionManager.session.connectedPeers.count > 1){
                    self.connectionManager.send(player: self.songPlayer, peer: self.connectionManager.session.connectedPeers)
                    self.connectionManager.send(action: "Removed From Queue", peer: self.connectionManager.session.connectedPeers)
                }
            }
        }
    }
    
    func handleActionData(_ notification: Notification) {
        DispatchQueue.main.async {
            
        }
    }
    
    public func audioStreamingDidLogin(_ audioStreaming: SPTAudioStreamingController!) {

    }

    public func audioStreaming(_ audioStreaming: SPTAudioStreamingController!, didReceiveError error: Error!) {

    }
    
    public func audioStreaming(_ audioStreaming: SPTAudioStreamingController!, didChangePlaybackStatus isPlaying: Bool) {
        if(isPlaying){
            playPauseLabel.titleLabel?.text = "Pause"
            songPlayer.isPlaying = true
            activateAudioSession()
        } else {
            playPauseLabel.titleLabel?.text = "Play"
            songPlayer.isPlaying = false
        }
        connectionManager.send(player: self.songPlayer, peer: self.connectionManager.session.connectedPeers)
        connectionManager.send(action: "Play Pause Pressed", peer: self.connectionManager.session.connectedPeers)
    }
    
    public func audioStreaming(_ audioStreaming: SPTAudioStreamingController!, didStopPlayingTrack trackUri: String!) {
        print("track finished")
        if(songPlayer.theQueue.count != 0){
            songPlayer.player.playSpotifyURI(songPlayer.theQueue[0].URI, startingWith: 0, startingWithPosition: 0, callback: { error in
                if(error != nil){
                    print(error)
                } else {
                    DispatchQueue.main.async {
                        self.nowPlaying.text = self.songPlayer.theQueue[0].name
                        self.songPlayer.nowPlaying = self.songPlayer.theQueue[0]
                        self.songPlayer.theQueue.remove(at: 0)
                        self.tableviewData = self.songPlayer.theQueue
                        self.tableview.reloadData()
                        self.connectionManager.send(player: self.songPlayer, peer: self.connectionManager.session.connectedPeers)
                        self.connectionManager.send(action: "Next Pressed", peer: self.connectionManager.session.connectedPeers)
                    }
                }
            })
        } else if(songPlayer.upNext.count != 0){
            songPlayer.player.playSpotifyURI(songPlayer.upNext[0].URI, startingWith: 0, startingWithPosition: 0, callback: { error in
                if(error != nil){
                    print(error)
                }
                DispatchQueue.main.async {
                    self.nowPlaying.text = self.songPlayer.upNext[0].name
                    self.songPlayer.nowPlaying = self.songPlayer.upNext[0]
                    self.songPlayer.upNext.remove(at: 0)
                    self.tableview.reloadData()
                    self.connectionManager.send(player: self.songPlayer, peer: self.connectionManager.session.connectedPeers)
                    self.connectionManager.send(action: "Next Pressed", peer: self.connectionManager.session.connectedPeers)
                }
                
            })
        }
    }
    
    func activateAudioSession() {
        do{
            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch is Error {
            print("something went wrong with audio sesh")
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

