//
//  LoginViewController.swift
//  Juke
//
//  Created by Kojo Worai Osei on 4/1/17.
//  Copyright © 2017 csmith. All rights reserved.
//

import UIKit
import Alamofire
import Unbox
import Firebase
import Crashlytics

class LoginViewController: UIViewController {

    @IBOutlet weak var skipTutorialButton: UIButton!
    
    @IBOutlet weak var loginButton: UIButton!
    let spotifyLoginController: SpotifyLoginController = SpotifyLoginController()
    let lockScreenDelegate = LockScreenDelegate()
    
    let activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .whiteLarge)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        lockScreenDelegate.setUpNowPlayingInfoCenter()
        spotifyLoginController.setSpotifyAppCredentials()  // set credentials before trying to fetch session
        if let session = SessionManager.fetchSession() {
            if session.isValid() {
                self.fetchSpotifyUser()
            } else {
                SessionManager.refreshSession() { success in
                    if success {
                        self.fetchSpotifyUser()
                    } else {
                        print("uh oh. refreshing session failed")
                    }
                }
            }
        } else {
            self.loginButton.isHidden = false
        }
    }

    @IBAction func loginWithSpotify(_ sender: Any) {
        print("in login with spotify")
        self.present(spotifyLoginController, animated: true) {
            print("in login controller")
            self.activityIndicator.center = self.view.center
            self.activityIndicator.startAnimating()
            self.view.addSubview(self.activityIndicator)
            self.spotifyLoginController.login() {
                self.loginButton.isHidden = true
                self.fetchSpotifyUser()
            }
        }
    }
    
    func logUserToCrashlytics() {
        guard let user = Current.user else { print("error logging user to crashlytics"); return }
        Crashlytics.sharedInstance().setUserName(user.username)
        Crashlytics.sharedInstance().setUserIdentifier(user.spotifyID)
    }
    
    func fetchSpotifyUser() {
        SessionManager.executeWithToken { (token) in
            guard let token = token else { return }
            let headers: HTTPHeaders = ["Authorization": "Bearer " + token]
            let url = Constants.kSpotifyBaseURL + Constants.kCurrentUserPath
            print("fetching spotify user")
            Alamofire.request(url, method: .get, parameters: nil, encoding: URLEncoding.default, headers: headers).validate().responseJSON {
                response in
                switch response.result {
                case .success:
                    do {
                        print("fetched spotify user")
                        let dictionary = response.result.value as! UnboxableDictionary
                        let spotifyUser: Models.SpotifyUser = try unbox(dictionary: dictionary)
                        FirebaseAPI.loginUser(spotifyUser: spotifyUser) { success in
                            print("logged in firebase user")
                            if success {
                                self.logUserToCrashlytics()
                                JamsPlayer.shared.login()   // session has been set, so set up audio player
                                
                                // dispatch onboarding seque
                                DispatchQueue.main.async {
                                    if Current.user?.onboard == true {
                                        self.performSegue(withIdentifier: "loginSegue", sender: nil)
                                    } else {
                                        self.performSegue(withIdentifier: "onBoardSegue", sender: nil)
                                    }
                                }
                            } else {
                                print("error logging in firebase user -- that's life in the city")
                            }
                        }
                    } catch {
                        print("error unboxing spotify user: ", error)
                    }
                case .failure(let error):
                    print(error)
                }
            }
        }
    }
    

    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // set status bar text to white
    override var preferredStatusBarStyle: UIStatusBarStyle { return .lightContent }
}
