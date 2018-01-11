//
//  SpotifyPlaylist.swift
//  Simple Track Playback
//
//  Created by Nikhil Sharma on 6/10/17.
//  Copyright © 2017 Your Company. All rights reserved.
//

import Foundation

public class SpotifyPlaylist {
    var ID: String = ""
    var URI: String = ""
    var name: String = ""
    var tracks: [SpotifyTrack] = []
    var trackHref: String = ""
    
    init(id: String, uri: String, name: String, tracks: [SpotifyTrack]){
        ID = id
        URI = uri
        self.name = name
        self.tracks = tracks
    }
    
    init(id: String, uri: String, name: String, hrefs: String){
        ID = id
        URI = uri
        self.name = name
        self.trackHref = hrefs
    }

    init(){
        ID = ""
        URI = ""
        name = ""
        trackHref = ""
        tracks = [SpotifyTrack]()
    }
}
