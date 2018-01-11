//
//  UserLibrary.swift
//  Queue It
//
//  Created by Nikhil Sharma on 7/16/17.
//  Copyright © 2017 Nikhil Sharma. All rights reserved.
//

import Foundation
import UIKit
import Alamofire

public class UserLibrary: NSObject {
    // FIELDS
    let auth = SPTAuth.defaultInstance()
    var savedTracks = [SpotifyTrack]()
    var playlists = [SpotifyPlaylist]()
    private var hasLoaded = false
    var savedTracksLoaded = false
    var playlistsLoaded = false
    var playlistTracksLoaded = false
    var loadLibCalled = false

    override init() {
        super.init()
        if(!loadLibCalled/*!savedTracksLoaded || !playlistsLoaded || !playlistTracksLoaded*/){
            print("calling load library")
            loadLibrary()
        }
    }
    
    public init(tempName: String) {
        super.init()
    }
    
    //METHODS
    
    func loadLibrary(){
        loadLibCalled = true
        print("in user lib call")
        //load user playlists
        let userPlaylists = [SpotifyPlaylist]()
        let offset = 0
        self.getUserPlaylists(userPlaylists: userPlaylists, offset: offset) { playlists in
            for element in playlists! {
                self.playlists.append(element)
            }
            if(!self.hasLoaded){
                self.loadTracksIntoPlaylist()
            }
            self.playlistsLoaded = true
            NotificationCenter.default.post(name: .playlistsLoaded, object: nil)
        }
        
        //load user tracks
        let userTracksRequest = URL.init(string: "https://api.spotify.com/v1/me/tracks")
        let offset2 = 0
        let params = [
            "limit": "50",
            "offset": "" + offset2.description,
            "market": "US"
        ]
        let userTracks = [SpotifyTrack]()
        
        self.getUserTracks(userTrackRequest: userTracksRequest!, userParams: params, userTracks: userTracks, offset: offset2) { tracks in
            print(tracks!.count)
            for element in tracks! {
                print(element.name)
                self.savedTracks.append(element)
            }
            self.savedTracksLoaded = true
            NotificationCenter.default.post(name: .songsLoaded, object: nil)
        }
    }
    
    // loads the tracks into the users playlists
    func loadTracksIntoPlaylist() {
        if(self.playlists.count == 0){
            
        } else {
            for x in 0...self.playlists.count-1 {
                let tracks = [SpotifyTrack]()
                let userPlaylistTrackRequest = URL.init(string: self.playlists[x].trackHref)
                let params1 = [
                    "offset": "0"
                ]
                self.getUserTracks(userTrackRequest: userPlaylistTrackRequest!, userParams: params1, userTracks: tracks, offset: 0, completionHandler: { playlistTracks in
                    for element13 in playlistTracks! {
                        self.playlists[x].tracks.append(element13)
                    }
                    if(x == self.playlists.count-1){
                        self.playlistTracksLoaded = true
                        NotificationCenter.default.post(name: .playlistTracksLoaded, object: nil)
                    }
                })
            }
        }
    }
    
    // get user playlists
    func getUserPlaylists(userPlaylists: [SpotifyPlaylist], offset: Int, completionHandler: @escaping
        ([SpotifyPlaylist]?) -> ()) {
        print("we are inside the call block")
        var userPlaylistsTemp = [SpotifyPlaylist]()
        let tempOffset = offset+50
        
        let userPlaylistHeader: HTTPHeaders = [
            "Authorization": "Bearer " + auth!.session.accessToken!,
            ]
        let userPlaylistRequest = URL.init(string: "https://api.spotify.com/v1/me/playlists")
        let params = [
            "limit": "50",
            "offset": "" + offset.description,
            ]
        
        Alamofire.request(userPlaylistRequest!, parameters: params, headers: userPlaylistHeader).responseJSON { (response) in
            do {
                let serialized = try JSONSerialization.jsonObject(with: response.data! as Data)
                if let dictionary = serialized as? [String: Any] {
                    for (key, value) in dictionary {
                        if(key == "next"){
                            if value is String {
                                self.getUserPlaylists(userPlaylists: userPlaylistsTemp, offset: tempOffset, completionHandler: { playlists in
                                    completionHandler(playlists)
                                })
                            }
                        }
                        if(key == "items"){
                            if let playlists = value as? [Any] {
                                for playlist in playlists {
                                    if let list = playlist as? [String: Any]{
                                        var name1 = ""
                                        var id1 = ""
                                        var uri1 = ""
                                        var hrefs1 = ""
                                        for (key1, value1) in list {
                                            if(key1 == "name"){
                                                name1 = value1 as! String
                                            } else if(key1 == "id"){
                                                id1 = value1 as! String
                                            } else if(key1 == "uri"){
                                                uri1 = value1 as! String
                                            } else if(key1 == "tracks"){
                                                if let trackInfo = value1 as? [String: Any]{
                                                    for (key2, value2) in trackInfo{
                                                        if(key2 == "href"){
                                                            hrefs1 = value2 as! String
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                        
                                        let playlist = SpotifyPlaylist.init(id: id1, uri: uri1, name: name1, hrefs: hrefs1)
                                        userPlaylistsTemp.append(playlist)
                                    }
                                }
                            }
                        }
                    }
                }
                completionHandler(userPlaylistsTemp)
            } catch is Error {
                print("playlist error")
                completionHandler(nil)
            }
        }
    }
    
    // get the users saved tracks
    func getUserTracks(userTrackRequest: URL, userParams: [String: String], userTracks: [SpotifyTrack], offset: Int, completionHandler: @escaping ([SpotifyTrack]?) -> ()) {
        print("getting user tracks")
        var userTracksTemp = userTracks
        var offsetTemp = offset
        
        let userSavedTrackHeader: HTTPHeaders = [
            "Authorization": "Bearer " + auth!.session.accessToken!,
            ]
        
        var userTracksRequestTemp = URL.init(string: "https://api.spotify.com/v1/me/tracks")
        userTracksRequestTemp = userTrackRequest
        
        let params = [
            "limit": "50",
            "offset": "" + offsetTemp.description,
            "market": "US"
        ]
        
        offsetTemp = offset+50
        
        
        Alamofire.request(userTracksRequestTemp!, parameters: params, headers: userSavedTrackHeader).responseJSON { (response) in
            switch response.result.isSuccess
            {
            case true :
                do {
                    let serialized = try JSONSerialization.jsonObject(with: response.data! as Data)
                    if let dictionary = serialized as? [String: Any] {
                        for (key, value) in dictionary {
                            if(key == "next"){
                                if value is String {
                                    self.getUserTracks(userTrackRequest: userTracksRequestTemp!, userParams: params, userTracks: userTracksTemp, offset: offsetTemp){ tracks in
                                        completionHandler(tracks)
                                    }
                                }
                            }
                            if(key == "items"){
                                if let songs = value as? [Any] {
                                    for song in songs {
                                        if let track = song as? [String: Any]{
                                            for (key1, value1) in track {
                                                if(key1 == "track"){
                                                    if let x = value1 as? [String: Any] {
                                                        var name = ""
                                                        var uri = ""
                                                        var id = ""
                                                        var album = ""
                                                        var artists = [""]
                                                        for (key2, value2) in x {
                                                            if(key2 == "name"){
                                                                name = value2 as! String
                                                            } else if(key2 == "uri"){
                                                                if(value2 as? NSNull != nil){
                                                                    name = "local track"
                                                                } else {
                                                                    uri = value2 as! String
                                                                }
                                                            } else if(key2 == "id"){
                                                                if(value2 as? NSNull != nil){
                                                                    id = "local track"
                                                                } else {
                                                                    id = value2 as! String
                                                                }
                                                            } else if(key2 == "album"){
                                                                if let albumInfo = value2 as? [String: Any]{
                                                                    for (key3, value3) in albumInfo {
                                                                        if(key3 == "name"){
                                                                            album = value3 as! String
                                                                        }
                                                                    }
                                                                }
                                                            } else if(key2 == "artists"){
                                                                if let artistArray = value2 as? [Any]{
                                                                    for (obj) in artistArray {
                                                                        if let artistInfo = obj as? [String: Any]{
                                                                            for (key4, value4) in artistInfo {
                                                                                if(key4 == "name"){
                                                                                    artists.append(value4 as! String)
                                                                                }
                                                                            }
                                                                        }
                                                                    }
                                                                }
                                                            }
                                                            
                                                        }
                                                        
                                                        artists.remove(at: 0)
                                                        let newTrack = SpotifyTrack.init(id: id, uri: uri, name: name, album: album, artists: artists)
                                                        userTracksTemp.append(newTrack)
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                    completionHandler(userTracksTemp)
                    
                } catch is Error {
                    completionHandler(nil)
                    print("error in loading tracks")
                }
            case false :
                print("error in loading tracks failed request")
            }
        }
    }
    
    //possible bug make completion handle not return func
    func searchForTrack(searchText: String, completionHandler: @escaping
        ([SpotifyTrack]?) -> ()) {
        var userSearchResults = [SpotifyTrack]()
        let keywords = searchText
        var finalKeywords = keywords.replacingOccurrences(of: " ", with: "+")
        //finalKeywords.insert("\"", at: finalKeywords.startIndex)
        //finalKeywords.insert("\"", at: finalKeywords.endIndex)
        let searchURL = "https://api.spotify.com/v1/search?q=\(finalKeywords)&type=track&limit=50"
        let searchHeader : HTTPHeaders = [
            "Authorization" : "Bearer " + (auth?.session.accessToken.description)!
        ]
        Alamofire.request(URL(string: searchURL)!, headers: searchHeader).responseJSON(completionHandler: {
            searchResults in
            print(searchResults.debugDescription)
            do {
                let results = try SPTSearch.searchResults(from: searchResults.data, with: searchResults.response, queryType: SPTSearchQueryType.queryTypeTrack)
                if(results.items != nil){
                    for element in results.items as! [SPTPartialTrack] {
                        var artists = [String]()
                        for element12 in element.artists {
                            let element13 = element12 as! SPTPartialArtist
                            artists.append(element13.name)
                        }
                        let track = SpotifyTrack.init(id: element.identifier, uri: "spotify:track:" + element.identifier, name: element.name, album: element.album.name, artists: artists)
                        userSearchResults.append(track)
                    }
                }
                completionHandler(userSearchResults)
            } catch is Error {
                print("search Error")
                completionHandler(nil)
            }
        })
    }
    
    /*
    func searchForArtists(){
        searchURL = "https://api.spotify.com/v1/search?q=\(finalKeywords)&type=artist"
        Alamofire.request(URL(string: searchURL)!, headers: searchHeader).responseJSON(completionHandler: {
            searchResults in
            do {
                let results = try SPTSearch.searchResults(from: searchResults.data, with: searchResults.response, queryType: SPTSearchQueryType.queryTypeArtist)
                if(results.items != nil){
                    self.userArtistSearchResults.removeAll()
                    for element in results.items as! [SPTPartialArtist] {
                        self.userArtistSearchResults.append(element)
                    }
                }
                self.tableview.reloadData()
            } catch is Error {
                print("search Error")
            }
            
        })
    }
     */
    
}

extension Notification.Name {
    static let songsLoaded = Notification.Name("songsLoaded")
    static let playlistsLoaded = Notification.Name("playlistsLoaded")
    static let playlistTracksLoaded = Notification.Name("playlistTracksLoaded")
}



