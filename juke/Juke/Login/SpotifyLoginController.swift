//
//  SpotifyLoginController.swift
//  Juke
//
//  Created by Conner Smith on 8/30/17.
//  Copyright © 2017 csmith. All rights reserved.
//

import UIKit

class SpotifyLoginController: UIViewController, UIWebViewDelegate {
    
    let webView: UIWebView = UIWebView(frame: CGRect.zero)
    let kClientID = Constants.kClientID
    let kCallbackURL = URL(string: Constants.kCallbackURL)!
    let kTokenSwapURL = URL(string: Constants.kTokenSwapURL)!
    let kTokenRefreshURL = URL(string: Constants.kTokenRefreshURL)
    var completion: ()->Void = { }
    
    public func setSpotifyAppCredentials() {
        let auth = SPTAuth.defaultInstance()!
        auth.clientID = kClientID
        auth.redirectURL = kCallbackURL
        auth.tokenSwapURL = kTokenSwapURL
        auth.tokenRefreshURL = kTokenRefreshURL
        auth.requestedScopes = [SPTAuthStreamingScope, SPTAuthUserLibraryReadScope, SPTAuthUserLibraryModifyScope, SPTAuthPlaylistReadPrivateScope]
    }
    
    override func loadView() {
        super.loadView()
        self.webView.frame = self.view.bounds
        self.webView.isUserInteractionEnabled = true
        self.view = self.webView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.webView.delegate = self
        NotificationCenter.default.addObserver(self, selector: #selector(loginSuccessful), name: NSNotification.Name("loginSuccessful"), object: nil)
    }
    
    func login(completion: @escaping(()->Void)) {
        self.completion = completion
        let loginURL = SPTAuth.defaultInstance().spotifyWebAuthenticationURL()!
        let request = URLRequest(url: loginURL, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData, timeoutInterval: 10)
        self.webView.loadRequest(request)
    }
    
    func loginSuccessful() {
        self.dismiss(animated: true) {
            self.completion()   // run the handler passed in by login view controller
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
}
