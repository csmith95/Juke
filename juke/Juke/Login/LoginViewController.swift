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

class LoginViewController: UIViewController {

    @IBOutlet weak var loginButton: UIButton!
//    var session:SPTSession!
    var ref: DatabaseReference!
    let loginController: SpotifyLoginController = SpotifyLoginController()

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        loginButton.isHidden = true

        ref = Database.database().reference()
        
        let userDefaults = UserDefaults.standard
        //config SPTAuth default instance with tokenSwap and refresh
        SPTAuth.defaultInstance().tokenSwapURL = URL(string: "https://juketokenrefresh.herokuapp.com/swap")
        SPTAuth.defaultInstance().tokenRefreshURL = URL(string: "https://juketokenrefresh.herokuapp.com/refresh")
        
        //check if session is available everytime you launch app
        if let sessionObj = userDefaults.object(forKey: "SpotifySession") { // session available
            let sessionDataObj = sessionObj as! Data
            let session = NSKeyedUnarchiver.unarchiveObject(with: sessionDataObj) as! SPTSession
            if !session.isValid() {
                // session is not valid so renew it
                SPTAuth.defaultInstance().renewSession(session, callback: { (error, renewedSession) in
                    if let session = renewedSession {
                        Current.accessToken = session.accessToken
                        self.fetchSpotifyUser()
                        SPTAuth.defaultInstance().session = session
                        let sessionData = NSKeyedArchiver.archivedData(withRootObject: session)
                        userDefaults.set(sessionData, forKey: "SpotifySession")
                        userDefaults.synchronize()
                    }
                })
            } else {
                Current.accessToken = session.accessToken
                fetchSpotifyUser()
            }
        } else {
            loginButton.isHidden = false
        }
    }

    @IBAction func loginWithSpotify(_ sender: Any) {
        self.present(loginController, animated: true) {
            self.loginController.login() {
                self.loginButton.isHidden = true
                self.fetchSpotifyUser()
            }
        }
    }
    
    func fetchSpotifyUser() {
        // first retrieve user object from spotify server using access token
        print("Fetching user")
        
        let accessToken = Current.accessToken
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
                    self.ref.child("users/\(spotifyUser.spotifyID)/online").setValue(true)
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
                // set firebase messaging token
                let token = Messaging.messaging().fcmToken
                print("FCM token: \(token ?? "")")
                newUserDict["fcmToken"] = token
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
            if let stream = Models.FirebaseStream(snapshot: snapshot) {
                Current.stream = stream

                // after stream assigned, addFirebaseHandlers
                // MARK - why are you adding listeners here instead of elsewhere?
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
        FirebaseAPI.createNewStream(removeFromCurrentStream: false) // no current stream to leave
        
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
