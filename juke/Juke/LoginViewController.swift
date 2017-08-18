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
import AVFoundation
import Firebase

class LoginViewController: UIViewController {

    @IBOutlet weak var loginButton: UIButton!
    let kClientID = "77d4489425fe464483f0934f99847c8b"
    let kCallbackURL = "juke1231://callback"
    var session:SPTSession!
    var player:AVPlayer?
    
    // firebase vars
    var ref: DatabaseReference!    
    fileprivate var _refHandle: DatabaseHandle!
    var users: [DataSnapshot]! = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let path = Bundle.main.path(forResource: "entrybkgnd", ofType: "mp4")
        player = AVPlayer(url: URL(fileURLWithPath: path!))
        let playerLayer = AVPlayerLayer(player: player)
        playerLayer.zPosition = -2
        playerLayer.frame = self.view.frame
        playerLayer.videoGravity = AVLayerVideoGravityResizeAspectFill
        self.view.layer.addSublayer(playerLayer)
        player?.seek(to: kCMTimeZero)
        
        loginButton.isHidden = true
        NotificationCenter.default.addObserver(self, selector: #selector(LoginViewController.updateAfterFirstLogin), name: NSNotification.Name("loginSuccessful"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(LoginViewController.playerItemDidReachEnd), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: player?.currentItem)
        
        // setup firebase db ref
        ref = Database.database().reference()

        
        let userDefaults = UserDefaults.standard
        //config SPTAuth default instance with tokenSwap and refresh
        SPTAuth.defaultInstance().tokenSwapURL = URL(string: "https://juketokenrefresh.herokuapp.com/swap")
        SPTAuth.defaultInstance().tokenRefreshURL = URL(string: "https://juketokenrefresh.herokuapp.com/refresh")
        
        //check if session is available everytime you launch app
        if let sessionObj = userDefaults.object(forKey: "SpotifySession") { // session available
            //print("session is available", SPTAuth.defaultInstance().session)
            let sessionDataObj = sessionObj as! Data
            let session = NSKeyedUnarchiver.unarchiveObject(with: sessionDataObj) as! SPTSession
            if !session.isValid() {
                // session is not valid so renew it
                print("not valid")
                SPTAuth.defaultInstance().renewSession(session, callback: { (error, renewedSession) in
                    if let session = renewedSession {
                        print("renewed session")
                        self.fetchSpotifyUser(accessToken: session.accessToken)
                        SPTAuth.defaultInstance().session = session
                        let sessionData = NSKeyedArchiver.archivedData(withRootObject: session)
                        userDefaults.set(sessionData, forKey: "SpotifySession")
                        userDefaults.synchronize()
                        self.session = renewedSession
                    }
                })
            } else {
                print("session is valid")
                fetchSpotifyUser(accessToken: session.accessToken)
            }
        } else {
            loginButton.isHidden = false
            player?.play()
        }
    }
    
    //if you are logging in for the first time and don't have a session that is going to be renewed
    func updateAfterFirstLogin() {
        loginButton.isHidden = true
        print("updateAfterFirstLogin")
        let userDefaults = UserDefaults.standard
        if let sessionObj = userDefaults.object(forKey: "SpotifySession") {
            let sessionDataObj = sessionObj as! Data
            let firstTimeSession = NSKeyedUnarchiver.unarchiveObject(with: sessionDataObj) as! SPTSession
            self.session = firstTimeSession
            print("Found session in first login")
            fetchSpotifyUser(accessToken: session.accessToken)
        }
    }
    
    func playerItemDidReachEnd() {
        print("Called playerItemDIdReachEnd")
        player!.seek(to: kCMTimeZero)
        player?.play()
    }

    @IBAction func loginWithSpotify(_ sender: Any) {
        let auth = SPTAuth.defaultInstance()!
        auth.clientID = kClientID
        auth.redirectURL = NSURL(string:kCallbackURL)! as URL
        auth.requestedScopes = [SPTAuthStreamingScope, SPTAuthUserLibraryReadScope, SPTAuthUserReadPrivateScope, SPTAuthUserLibraryModifyScope]
        let loginURL = SPTAuth.defaultInstance().spotifyWebAuthenticationURL()
        UIApplication.shared.open(loginURL!)
    }
    
    func fetchSpotifyUser(accessToken: String) {
        // first retrieve user object from spotify server using access token
        print("Fetching user")
        
        CurrentUser.accessToken = accessToken
        let headers: HTTPHeaders = ["Authorization": "Bearer " + accessToken]
        let url = ServerConstants.kSpotifyBaseURL + ServerConstants.kCurrentUserPath
        Alamofire.request(url, method: .get, parameters: nil, encoding: URLEncoding.default, headers: headers).validate().responseJSON {
            response in
            switch response.result {
            case .success:
                do {
                    let dictionary = response.result.value as! UnboxableDictionary
                    let spotifyUser: Models.SpotifyUser = try unbox(dictionary: dictionary)
                    self.addUserToFirebase(spotifyUser: spotifyUser)
                    print("Fetched user")
                } catch {
                    print("error unboxing spotify user: ", error)
                }
            case .failure(let error):
                print(error)
            }
        };
    }
    
    func addUserToFirebase(spotifyUser: Models.SpotifyUser) {
        ref.child("users/\(spotifyUser.spotifyID)").observeSingleEvent(of: .value, with: { (snapshot) in
            
            if snapshot.exists() {
                if var userDict = snapshot.value as? [String: Any] {
                    print(snapshot)
                    userDict["spotifyID"] = spotifyUser.spotifyID
                    CurrentUser.user = Models.FirebaseUser(dict: userDict)
                }
            } else {
                // add user if user does not exist
                var newUserDict: [String: Any?] = ["imageURL": spotifyUser.imageURL,
                                                   "tunedInto": nil,
                                                   "online": true]
                if let username = spotifyUser.username {
                    newUserDict["username"] = username
                } else {
                    newUserDict["username"] = spotifyUser.spotifyID // use spotifyID if no spotify username
                }
                self.ref.child("users").child(spotifyUser.spotifyID).setValue(newUserDict)
                newUserDict["spotifyID"] = spotifyUser.spotifyID
                CurrentUser.user = Models.FirebaseUser(dict: newUserDict)
            }
            
            // for testing right now
            var stream: [String: Any?] = [:]
            let host = Models.FirebaseMember(username: CurrentUser.user.username, imageURL: CurrentUser.user.imageURL)
            stream["host"] = host.dictionary
            stream["members"] = host.dictionary
            stream["song"] = nil
            stream["isPlaying"] = false
            CurrentUser.stream = Models.FirebaseStream(dict: stream)
            print(CurrentUser.stream)
            
            // login transition
            DispatchQueue.main.async {
                print("loginSegue")
                self.performSegue(withIdentifier: "loginSegue", sender: nil)
            }
            
        }) {(error) in
            print(error.localizedDescription)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
