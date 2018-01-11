//
//  MenuViewController.swift
//  Queue It
//
//  Created by Nikhil Sharma on 7/19/17.
//  Copyright © 2017 Nikhil Sharma. All rights reserved.
//

import Foundation
import UIKit
import StoreKit
import MediaPlayer

public class MenuViewController: UIViewController, SFSafariViewControllerDelegate {
    var auth = SPTAuth.defaultInstance()
    var userLibrary = UserLibrary.init(tempName: "temp")
    let applicationMusicPlayer = MPMusicPlayerController.applicationMusicPlayer()

    override public func viewDidLoad() {
        if(!userLibrary.playlistsLoaded || !userLibrary.playlistTracksLoaded || !userLibrary.savedTracksLoaded){
            userLibrary = UserLibrary.init()
        }
        appleMusicRequestPermission()
    }
    
    func appleMusicRequestPermission() {
        
        SKCloudServiceController.requestAuthorization { (status:SKCloudServiceAuthorizationStatus) in
            
            switch status {
                
            case .authorized:
                
                
                print("All good - the user tapped 'OK', so you're clear to move forward and start playing.")
                
            case .denied:
                
                print("The user tapped 'Don't allow'. Read on about that below...")
                
            case .notDetermined:
                
                print("The user hasn't decided or it's not clear whether they've confirmed or denied.")
                
            case .restricted:
                
                print("User may be restricted; for example, if the device is in Education mode, it limits external Apple Music usage. This is similar behaviour to Denied.")

            }
        }
    }
    
    override public func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        UIApplication.shared.statusBarStyle = .lightContent
    }
    
    override public var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    func startAuthenticationFlow(){
        if (self.auth?.session.isValid())! {

        } else {
            let authURL = self.auth?.spotifyWebAuthenticationURL()
            let svc = SFSafariViewController(url: authURL!, entersReaderIfAvailable: true)
            self.present(svc, animated: true, completion: nil)
            svc.delegate = self
        }
    }
    
    func audioStreamingDidLogin(_ audioStreaming: SPTAudioStreamingController!) {
        self.safariViewControllerDidFinish(self.presentingViewController as! SFSafariViewController)
    }
    
    public func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
        controller.dismiss(animated: true, completion: nil)
    }
    
    override public func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        print(segue.identifier)
        if (segue.identifier == "showCreateController") {
            let ExchangeViewData = segue.destination as! CreateQueueViewController
            ExchangeViewData.tempUserLib = userLibrary
            print("userlib")
            for list in userLibrary.playlists {
                print(list.name)
            }
            for track in userLibrary.savedTracks {
                print(track.name)
            }
            print("to create control")
        } else if(segue.identifier == "showJoinController"){
            let ExchangeViewData = segue.destination as! JoinQueueViewController
            ExchangeViewData.tempUserLib = userLibrary
            print("to join control")
        }
        
    }
    
}
