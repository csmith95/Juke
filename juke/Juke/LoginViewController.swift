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

class LoginViewController: UIViewController {

    let kClientID = "77d4489425fe464483f0934f99847c8b"
    let kCallbackURL = "juke1231://callback"
    public static var currUser: Models.User? = nil
    
    @IBOutlet weak var loginButton: UIButton!
    
    @IBAction func loginPressed(_ sender: AnyObject) {
        let auth = SPTAuth.defaultInstance()!
        auth.clientID = kClientID
        auth.redirectURL = NSURL(string:kCallbackURL) as! URL
        auth.requestedScopes = [SPTAuthStreamingScope]
        let loginURL = auth.loginURL!
        NotificationCenter.default.addObserver(self, selector: #selector(LoginViewController.loginSuccessful), name: Notification.Name("loginSuccessful"), object: nil)
        UIApplication.shared.open(loginURL)
    }
    
    func loginSuccessful(notification: NSNotification) {
        if let accessToken = notification.object as? String {
            // kick off authentication of player early
            let player = JamsPlayer.shared
            performSegue(withIdentifier: "loginSegue", sender: nil)
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
        Alamofire.request(url, method: .post, parameters: params).validate().responseJSON { response in
            do {
                let dictionary = response.result.value as! UnboxableDictionary
                let user: Models.User = try unbox(dictionary: dictionary)
                LoginViewController.currUser = user
            } catch {
                print("Error unboxing user: ", error)
            }
        };
    }
    

    override func viewDidLoad() {
        super.viewDidLoad()
        loginButton.layer.borderWidth = 1.0
        loginButton.layer.borderColor = UIColor(red:139/255.0, green:245/255.0, blue:119/255.0, alpha: 1.0).cgColor
        loginButton.layer.cornerRadius = 15
        // kick off location updates early -- currently not using location for MVP
//        let locationManager = LocationManager.sharedInstance
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
