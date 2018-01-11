//
//  LoginViewController.swift
//  Queue It
//
//  Created by Nikhil Sharma on 7/21/17.
//  Copyright © 2017 Nikhil Sharma. All rights reserved.
//

import Foundation
import UIKit

public class LoginViewController: UIViewController, SFSafariViewControllerDelegate {
    
    var auth = SPTAuth.defaultInstance()

    @IBAction func loginPressed(_ sender: UIButton) {
    }
    
    override public func viewDidLoad() {
        self.auth?.clientID = "285df9f6c9d34e90999ecff007646c71"
        self.auth?.redirectURL =  URL(string:"queue-it://callback")
        self.auth?.sessionUserDefaultsKey = "current session"
        self.auth?.requestedScopes = [SPTAuthStreamingScope, SPTAuthUserLibraryReadScope, SPTAuthPlaylistReadPrivateScope]
        self.startAuthenticationFlow()

    }
    
    func startAuthenticationFlow(){
        if (self.auth?.session.isValid())! {
            
        } else {
            print("here")
            let authURL = self.auth?.spotifyWebAuthenticationURL()
            let svc = SFSafariViewController(url: authURL!, entersReaderIfAvailable: true)
            self.present(svc, animated: true, completion: nil)
            svc.delegate = self
        }
    }

}
