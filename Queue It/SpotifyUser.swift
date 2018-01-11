//
//  SpotifyUser.swift
//  Simple Track Playback
//
//  Created by Nikhil Sharma on 6/3/17.
//  Copyright © 2017 Your Company. All rights reserved.
//

import Foundation

public class SpotifyUser {
    // feilds
    
    var displayName: String = ""
    var userName: String = ""
    
    init?(json: [String: Any]) {
         if let dictionary = json as? [String: Any] {
             for (key, value) in dictionary {
             // access all key / value pairs in dictionary
                if(key == "id"){
                    self.userName = value as! String
                } 
             }
         }
    }
}
