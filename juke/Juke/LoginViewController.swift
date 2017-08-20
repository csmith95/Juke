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
        
        // setup intro background vid
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
        
        Current.accessToken = accessToken
        let headers: HTTPHeaders = ["Authorization": "Bearer " + accessToken]
        let url = ServerConstants.kSpotifyBaseURL + ServerConstants.kCurrentUserPath
        Alamofire.request(url, method: .get, parameters: nil, encoding: URLEncoding.default, headers: headers).validate().responseJSON {
            response in
            switch response.result {
            case .success:
                do {
                    let dictionary = response.result.value as! UnboxableDictionary
                    let spotifyUser: Models.SpotifyUser = try unbox(dictionary: dictionary)
                    self.fetchFirebaseUser(spotifyUser: spotifyUser)
                    print("Fetched user")
                } catch {
                    print("error unboxing spotify user: ", error)
                }
            case .failure(let error):
                print(error)
            }
        };
    }
    
    func fetchFirebaseUser(spotifyUser: Models.SpotifyUser) {
        ref.child("users/\(spotifyUser.spotifyID)").observeSingleEvent(of: .value, with: { (snapshot) in
            if snapshot.exists() {
                if var userDict = snapshot.value as? [String: Any?] {
                    userDict["spotifyID"] = spotifyUser.spotifyID
                    Current.user = Models.FirebaseUser(dict: userDict)
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
                // write to firebase DB
                self.ref.child("users").child(spotifyUser.spotifyID).setValue(newUserDict)
                newUserDict["spotifyID"] = spotifyUser.spotifyID
                Current.user = Models.FirebaseUser(dict: newUserDict)
            }
            
            // now that current user is set, fetch the user's stream object
            self.fetchFirebaseStream()
            
        }) {(error) in
            print(error.localizedDescription)
        }
    }
    
    private func fetchFirebaseStream() {
        guard let tunedInto = Current.user.tunedInto else {
            createNewStream()
            return
        }
        
        self.ref.child("streams/\(tunedInto)").observeSingleEvent(of: .value, with : { (snapshot) in
            if let streamDict = snapshot.value as? [String: Any] {
                guard let stream = Models.FirebaseStream(snapshot: snapshot) else { return }
                Current.stream = stream
                // after stream assigned, addFirebaseHandlers
                FirebaseAPI.addListeners()
                
                // login transition
                DispatchQueue.main.async {
                    self.performSegue(withIdentifier: "loginSegue", sender: nil)
                }
            } else {
                self.createNewStream()
            }
        }) {error in print(error.localizedDescription)}
    }
    
    func createNewStream() {
        // if no stream exists, create empty one for user
        let host = Models.FirebaseMember(username: Current.user.username, imageURL: Current.user.imageURL)
        Current.stream = Models.FirebaseStream(host: host)
        Current.user.tunedInto = Current.stream.streamID
        
        // write to firebase
        self.ref.child("streams/\(Current.stream.streamID)").setValue(Current.stream.firebaseDict) // create stream in firebase
        self.ref.child("/users/\(Current.user.spotifyID)/tunedInto").setValue(Current.stream.streamID) // show that user is tuned into this stream
        
        // after stream assigned, addFirebaseHandlers
        FirebaseAPI.addListeners()
        
        // login transition
        DispatchQueue.main.async {
            self.performSegue(withIdentifier: "loginSegue", sender: nil)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
