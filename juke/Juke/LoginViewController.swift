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

class LoginViewController: UIViewController {

    @IBOutlet weak var loginButton: UIButton!
    let kClientID = "77d4489425fe464483f0934f99847c8b"
    let kCallbackURL = "juke1231://callback"
    var session:SPTSession!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loginButton.isHidden = true
        NotificationCenter.default.addObserver(self, selector: #selector(LoginViewController.updateAfterFirstLogin), name: NSNotification.Name("loginSuccessful"), object: nil)
        
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
                    print(renewedSession)
                    if let session = renewedSession {
                        print("renewed session")
                        SPTAuth.defaultInstance().session = session
                        let sessionData = NSKeyedArchiver.archivedData(withRootObject: session)
                        userDefaults.set(sessionData, forKey: "SpotifySession")
                        userDefaults.synchronize()
                        
                        self.session = renewedSession
                        //fetch user
                        self.fetchSpotifyUser(accessToken: session.accessToken)
                    }
                })
            } else {
                print("session is valid")
                fetchSpotifyUser(accessToken: session.accessToken)
            }
        } else {
            loginButton.isHidden = false
        }
    }
    
    //if you are logging in for the first time and don't have a session that is going to be renewed
    func updateAfterFirstLogin() {
        loginButton.isHidden = true
        print("updateAfterFirstLogin")
        let userDefaults = UserDefaults.standard
        if let sessionObj = userDefaults.object(forKey: "SpotifySession") {
            print("Found session in first login")
            let sessionDataObj = sessionObj as! Data
            let firstTimeSession = NSKeyedUnarchiver.unarchiveObject(with: sessionDataObj) as! SPTSession
            self.session = firstTimeSession
            //fetch user
            fetchSpotifyUser(accessToken: session.accessToken)
        }
    }

    @IBAction func loginWithSpotify(_ sender: Any) {
        let auth = SPTAuth.defaultInstance()!
        auth.clientID = kClientID
        auth.redirectURL = NSURL(string:kCallbackURL)! as URL
        auth.requestedScopes = [SPTAuthStreamingScope]
        let loginURL = auth.loginURL!
        UIApplication.shared.open(loginURL)
    }
    
    func fetchSpotifyUser(accessToken: String) {
        // first retrieve user object from spotify server using access token
        print("Fetching user")
        let headers: HTTPHeaders = ["Authorization": "Bearer " + accessToken]
        let url = ServerConstants.kSpotifyBaseURL + ServerConstants.kCurrentUserPath
        Alamofire.request(url, method: .get, parameters: nil, encoding: URLEncoding.default, headers: headers).validate().responseJSON {
            response in
            switch response.result {
            case .success:
                do {
                    let dictionary = response.result.value as! UnboxableDictionary
                    let spotifyUser: Models.SpotifyUser = try unbox(dictionary: dictionary)
                    self.addUserToJukeServer(spotifyUser: spotifyUser)
                    print("Fetched user")
                } catch {
                    print("error unboxing spotify user: ", error)
                }
            case .failure(let error):
                print(error)
            }
        };
    }
    
    func addUserToJukeServer(spotifyUser: Models.SpotifyUser) {
        // create new user object in DB. if already exists with spotifyID, returns user object
        let url = ServerConstants.kJukeServerURL + ServerConstants.kAddUser
        let params: Parameters = [
            "spotifyID": spotifyUser.spotifyID,
            "username": (spotifyUser.username != nil) ? spotifyUser.username! : "",
            "imageURL": (spotifyUser.imageURL != nil) ? spotifyUser.imageURL! : ""
        ]
        
        Alamofire.request(url, method: .post, parameters: params).validate().responseJSON { response in
            switch response.result {
            case .success:
                do {
                    let unparsedJukeUser = response.result.value as! UnboxableDictionary
                    let user: Models.User = try unbox(dictionary: unparsedJukeUser)
                    CurrentUser.user = user
                    DispatchQueue.main.async {
                        print("loginSegue")
                        self.performSegue(withIdentifier: "loginSegue", sender: nil)
                    }
                } catch {
                    print("Error unboxing user: ", error)
                }
            case .failure(let error):
                print("Error adding user to database: ", error)
            }
        };
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
