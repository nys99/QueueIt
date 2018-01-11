//
//  SongPlayer.swift
//  Queue It
//
//  Created by Nikhil Sharma on 7/16/17.
//  Copyright © 2017 Nikhil Sharma. All rights reserved.
//

import UIKit
import Alamofire
import Foundation

public class SongPlayer: NSObject, NSCoding {
    //FIELDS
    private let auth = SPTAuth.defaultInstance()
    var player: SPTAudioStreamingController = SPTAudioStreamingController.sharedInstance()
    var theQueue: [SpotifyTrack]
    var queueIsShuffled = false
    var unShuffledQueue: [SpotifyTrack]
    var upNext: [SpotifyTrack]
    var nowPlaying: SpotifyTrack
    var upNextIsShuffled = false
    var unshuffledUpNext: [SpotifyTrack]
    var isPlaying = false
    
    
    required convenience public init(coder decoder: NSCoder){
        self.init()
        self.player = SPTAudioStreamingController.sharedInstance()
        self.theQueue = decoder.decodeObject(forKey: "theQueue") as! [SpotifyTrack]
        self.upNext = decoder.decodeObject(forKey: "upNext") as! [SpotifyTrack]
        self.nowPlaying = decoder.decodeObject(forKey: "nowPlaying") as! SpotifyTrack
        self.unshuffledUpNext = decoder.decodeObject(forKey: "unshuffledUpNext") as! [SpotifyTrack]
        self.unShuffledQueue = decoder.decodeObject(forKey: "unShuffledQueue") as! [SpotifyTrack]
        self.queueIsShuffled = decoder.decodeBool(forKey: "queueIsShuffled")
        self.upNextIsShuffled = decoder.decodeBool(forKey: "upNextIsShuffled")
        self.isPlaying = decoder.decodeBool(forKey: "isPlaying")
    }
    
    convenience init(theQueue: [SpotifyTrack], upNext: [SpotifyTrack], nowPlaying: SpotifyTrack,upNextIsShuffled: Bool, unshuffledUpNext: [SpotifyTrack], isPlaying: Bool,queueIsShuffled: Bool, unshuffledQueue: [SpotifyTrack]){
        self.init()
        self.player = SPTAudioStreamingController.sharedInstance()
        self.theQueue = theQueue
        self.upNext = upNext
        self.nowPlaying = nowPlaying
        self.upNextIsShuffled = upNextIsShuffled
        self.unshuffledUpNext = unshuffledUpNext
        self.isPlaying = isPlaying
        self.unShuffledQueue = unshuffledQueue
        self.queueIsShuffled = queueIsShuffled
    }
    
    public func encode(with aCoder: NSCoder) {
        aCoder.encode(theQueue, forKey:"theQueue")
        aCoder.encode(upNext, forKey:"upNext")
        aCoder.encode(nowPlaying, forKey:"nowPlaying")
        aCoder.encode(upNextIsShuffled, forKey:"upNextIsShuffled")
        aCoder.encode(unshuffledUpNext, forKey:"unshuffledUpNext")
        aCoder.encode(queueIsShuffled, forKey:"queueIsShuffled")
        aCoder.encode(unShuffledQueue, forKey:"unShuffledQueue")
        aCoder.encode(isPlaying, forKey:"isPlaying")
    }
    
    override init(){
        self.player = SPTAudioStreamingController.sharedInstance()
        self.theQueue = [SpotifyTrack]()
        self.upNext = [SpotifyTrack]()
        self.nowPlaying = SpotifyTrack()
        self.upNextIsShuffled = false
        self.unshuffledUpNext = [SpotifyTrack]()
        self.isPlaying = false
        self.unShuffledQueue = [SpotifyTrack]()
        self.queueIsShuffled = false
        super.init()
    }
    
    //METHODS
    func playSong(track: SpotifyTrack){
        player.playSpotifyURI(track.URI, startingWith: 0, startingWithPosition: 0, callback: { error in
            if(error == nil){
                print("track is playing")
                self.nowPlaying = track
            } else {
                print("error in playing song")
                print(error!)
            }
        })
    }
    
    func togglePlay(){
        if(player.playbackState.isPlaying){
            player.setIsPlaying(false, callback: { error in
                if(error == nil){
                    print("track is paused")
                    //self.isPlaying = false
                } else {
                    print("error error in pausing song")
                    print(error!)
                }
            })
        } else {
            player.setIsPlaying(true, callback: { error in
                if(error == nil){
                    print("track is now playing")
                    //self.isPlaying = true
                } else {
                    print("error in playing song (play pause toggle")
                    print(error!)
                }
            })
        }
    }
    
    func skipTrack(completionHandler: @escaping (Error?) -> ()){
        if(theQueue.count == 0){
            if(upNext.count != 0){
                player.playSpotifyURI(upNext[0].URI, startingWith: 0, startingWithPosition: 0, callback: { error in
                    if(error == nil){
                        print("next track from upnext is playing")
                        self.nowPlaying = self.upNext[0]
                        self.upNext.remove(at: 0)
                        completionHandler(nil)
                    } else {
                        print("error in skipping with upnext")
                        completionHandler(error)
                    }
                })
            } else {
                print("no tracks to skip")
            }
        } else {
            player.playSpotifyURI(theQueue[0].URI, startingWith: 0, startingWithPosition: 0, callback: { error in
                if(error == nil){
                    self.nowPlaying = self.theQueue[0]
                    self.theQueue.remove(at: 0)
                    completionHandler(nil)
                } else {
                    print("error in skipping with the queue")
                    completionHandler(error)
                }
            })
        }
    }
    
    func queueSong(track: SpotifyTrack){
        theQueue.append(track)
    }
    
    func playNext(track: SpotifyTrack){
        if(theQueue.count == 0){
            theQueue.append(track)
        } else {
            let count = theQueue.count - 1
            theQueue.append(SpotifyTrack())
            for x in 0...count {
                let y = count - x
                theQueue[y+1] = theQueue[y]
            }
            theQueue[0] = track
        }
    }
    
    func toggleShuffleUpNext(){
        if(upNextIsShuffled){
            upNext = unshuffledUpNext
            upNextIsShuffled = false
        } else {
            unshuffledUpNext = upNext
            upNext.shuffle()
            upNextIsShuffled = true
        }
    }
    
    func toggleShuffleQueue(){
        if(queueIsShuffled){
            theQueue = unShuffledQueue
            queueIsShuffled = false
        } else {
            unShuffledQueue = theQueue
            theQueue.shuffle()
            queueIsShuffled = true
        }
    }
}

extension MutableCollection where Index == Int {
    /// Shuffle the elements of `self` in-place.
    mutating func shuffle() {
        // empty and single-element collections don't shuffle
        if count < 2 { return }
        
        for i in startIndex ..< endIndex - 1 {
            let j = Int(arc4random_uniform(UInt32(endIndex - i))) + i
            if i != j {
                self.swapAt(i, j)
            }
        }
    }
}

