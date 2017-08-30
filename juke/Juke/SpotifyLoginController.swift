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
    let kClientId = "77d4489425fe464483f0934f99847c8b"
    let kCallbackURL = "juke1231://callback"
    var completion: (_ session: SPTSession)->Void = { (session: SPTSession) in }
    
    override func loadView() {
        super.loadView()
        self.webView.frame = self.view.bounds
        self.webView.isUserInteractionEnabled = true
        self.view = self.webView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.webView.delegate = self
    }
    
    func login(completion: @escaping((_ session: SPTSession)->Void)) {
        self.completion = completion
        var loginURL: NSURL = SPTAuth.defaultInstance().loginURLForClientId(kClientId,
                                                                            declaredRedirectURL: NSURL(string: kCallbackURL),
                                                                            scopes: [SPTAuthStreamingScope, SPTAuthPlaylistReadPrivateScope, SPTAuthUserReadPrivateScope])
        let request: NSURLRequest = NSURLRequest(URL: loginURL, cachePolicy: NSURLRequest.CachePolicy.ReloadIgnoringLocalCacheData, timeoutInterval: 10)
        self.webView.loadRequest(request as URLRequest)
    }
    
    func webView(webView: UIWebView, shouldStartLoadWithRequest request: NSURLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        let url: NSURL = request.URL
        if (SPTAuth.defaultInstance().canHandleURL(url, withDeclaredRedirectURL: NSURL(string:kCallbackURL))) {
            SPTAuth.defaultInstance().handleAuthCallbackWithTriggeredAuthURL(url, tokenSwapServiceEndpointAtURL: NSURL(string: kTokenSwapServiceURL)) { (error, session) -> Void in
                if (error != nil) {
                    println("Auth error: \(error.localizedDescription)")
                    return
                }
                self.dismissViewControllerAnimated(true) {
                    self.completion(session: session)
                }
            }
        }
        return true
    }
    
}
