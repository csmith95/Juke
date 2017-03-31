//
//  ViewController.swift
//  Juke
//
//  Created by Conner Smith on 2/18/17.
//  Copyright © 2017 csmith. All rights reserved.
//

import UIKit
import Alamofire
import Unbox
import RevealingSplashView

class LoginViewController: UIViewController {
    
    @IBOutlet var loginFrame: UIView!
    let kClientID = "77d4489425fe464483f0934f99847c8b"
    let kCallbackURL = "juke1231://callback"
    let connectButton: UIControl = SPTConnectButton()
    public static var currUser: Models.User? = nil
    
    
    func loginPressed(_ sender: AnyObject) {
        let auth = SPTAuth.defaultInstance()!
        auth.clientID = kClientID
        auth.redirectURL = NSURL(string:kCallbackURL) as! URL
        auth.requestedScopes = [SPTAuthStreamingScope]
        let loginURL = auth.loginURL!
        UIApplication.shared.open(loginURL)
    }
    
    func loginSuccessful(notification: NSNotification) {
        if let accessToken = notification.object as? String {
            // kick off authentication of player early
            let player = JamsPlayer.shared
            fetchSpotifyUser(accessToken: accessToken)
        }
    }
    
    func fetchSpotifyUser(accessToken: String) {
        // first retrieve user object from spotify server using access token
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
                } catch {
                    print("error unboxing spotify user: ", error)
                }
            case .failure(let error):
                print(error)
            }
        };
    }
    
    func addUserToJukeServer(spotifyUser: Models.SpotifyUser) {
        // create new user object in DB. if already exists with spotifyID, no-op
        let url = ServerConstants.kJukeServerURL + ServerConstants.kAddUser
        let params: Parameters = [
            "spotifyID": spotifyUser.spotifyID,
            "username": spotifyUser.username,
            "imageURL": spotifyUser.imageURL
        ]
        print(params)
        Alamofire.request(url, method: .post, parameters: params).validate().responseJSON { response in
            switch response.result {
            case .success:
                do {
                    let unparsedJukeUser = response.result.value as! UnboxableDictionary
                    let user: Models.User = try unbox(dictionary: unparsedJukeUser)
                    LoginViewController.currUser = user
                    DispatchQueue.main.async {
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
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self, selector: #selector(LoginViewController.loginSuccessful), name: Notification.Name("loginSuccessful"), object: nil)
        
        //Initialize a revealing Splash with with the iconImage, the initial size and the background color
        let revealingSplashView = RevealingSplashView(iconImage: UIImage(named: "JukeLogo")!, iconInitialSize: CGSize(width: 210, height: 410), backgroundColor: UIColor.clear)
        
        //Adds the revealing splash view as a sub view
        self.view.addSubview(revealingSplashView)
        
        
        if let session = retrieveSession() {
            revealingSplashView.startAnimation(){
                // post notification on main thread since it involves a segue
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: Notification.Name("loginSuccessful"), object: session.accessToken)
                }
            }
        } else {
            connectButton.frame = loginFrame.bounds
            connectButton.becomeFirstResponder()
            connectButton.addTarget(self, action: #selector(LoginViewController.loginPressed(_:)), for: UIControlEvents.touchUpInside)
            view.addSubview(connectButton)
        }

        // kick off location updates early -- currently not using location for MVP
        //        let locationManager = LocationManager.sharedInstance
    }

    func retrieveSession() -> SPTSession? {
        if let sessionObj = UserDefaults.standard.object(forKey: "SpotifySession") {
            let sessionDataObj = sessionObj as! Data
            if let session = NSKeyedUnarchiver.unarchiveObject(with: sessionDataObj) as? SPTSession {
                if session.isValid() {
                    return session
                }
            }
        }
        return nil
    }
}
