//
//  SpotifyTrack.swift
//  Simple Track Playback
//
//  Created by Nikhil Sharma on 6/6/17.
//  Copyright © 2017 Your Company. All rights reserved.
//

import Foundation
import UIKit
import Alamofire

public class SpotifyTrack: NSObject, NSCoding {
    
    var ID: String
    var URI: String
    var name: String
    var album: String
    var artists: [String]
    
    required convenience public init(coder decoder: NSCoder) {
        self.init()
        self.ID = decoder.decodeObject(forKey: "ID") as! String
        self.URI = decoder.decodeObject(forKey: "URI") as! String
        self.name = decoder.decodeObject(forKey: "name") as! String
        self.album = decoder.decodeObject(forKey: "album") as! String
        self.artists = decoder.decodeObject(forKey: "artists") as! [String]
        
    }
    
    convenience init(ID: String, URI: String, name: String, album: String, artists: [String]) {
        self.init()
        self.ID = ID
        self.URI = URI
        self.name = name
        self.album = album
        self.artists = artists
    }
    
    public func encode(with aCoder: NSCoder) {
        aCoder.encode(name, forKey: "name")
        aCoder.encode(ID, forKey:"ID")
        aCoder.encode(album, forKey:"album")
        aCoder.encode(artists, forKey:"artists")
        aCoder.encode(URI, forKey:"URI")
        
        
    }
    
    init(id: String, uri: String, name: String, album: String, artists: [String]){
        ID = id
        URI = uri
        self.name = name
        self.album = album
        self.artists = artists
    }
    
    override init(){
        ID = ""
        URI = ""
        name = ""
        album = ""
        artists = [""]
    }
    
    
    
    
}
