//
//  ViewController.swift
//  Juke
//
//  Created by Conner Smith on 2/18/17.
//  Copyright © 2017 csmith. All rights reserved.
//

import UIKit
import Alamofire

class ViewController: UIViewController {

    let kClientID = "77d4489425fe464483f0934f99847c8b"
    let kCallbackURL = "juke1231://callback"
    
    @IBOutlet weak var loginButton: UIButton!
    
    @IBAction func loginPressed(_ sender: AnyObject) {
        let auth = SPTAuth.defaultInstance()!
        auth.clientID = kClientID
        auth.redirectURL = NSURL(string:kCallbackURL) as! URL
        auth.requestedScopes = [SPTAuthStreamingScope]
        let loginURL = auth.loginURL!
        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.loginSuccessful), name: Notification.Name("loginSuccessful"), object: nil)
        UIApplication.shared.open(loginURL)
    }
    
    func loginSuccessful(notification: NSNotification) {
        if let accessToken = notification.object as? String {
            // kick off authentication of player before user gets to playlist page
            let player = JamsPlayer.shared
            performSegue(withIdentifier: "loginSegue", sender: nil)
            fetchSpotifyUser(accessToken: accessToken)
        }
    }
    
    func fetchSpotifyUser(accessToken: String) {
        // first retrieve user object from spotify server using access token
        let headers: HTTPHeaders = ["Authorization": "Bearer " + accessToken]
        let url = ServerConstants.kSpotifyBaseURL + ServerConstants.kCurrentUserPath
        // first retrieve user object from spotify server using access token
        Alamofire.request(url, method: .get, parameters: nil, encoding: URLEncoding.default, headers: headers).validate().responseJSON {
            response in
            switch response.result {
            case .success:
                if let user = response.result.value as? NSDictionary {
                    // update juke server. if user with spotify_id already exists, no-op
                    self.updateJukeServer(user: user)
                }
            case .failure(let error):
                print(error)
            }
        };
    }
    
    func updateJukeServer(user: NSDictionary) {
        if let spotify_id = user["id"] as? String {
            let url = ServerConstants.kJukeServerURL + ServerConstants.kAddUser
            let params: Parameters = ["spotify_id": spotify_id]
            Alamofire.request(url, method: .post, parameters: params).validate().responseJSON { response in
                switch response.result {
                case .success:
                    if let response = response.result.value as? NSDictionary {
                        print("Added user: ", response)
                    }
                case .failure(let error):
                    print(error)
                }
            };
        }
    }
    

    override func viewDidLoad() {
        super.viewDidLoad()
        loginButton.layer.borderWidth = 1.0
        loginButton.layer.borderColor = UIColor(red:139/255.0, green:245/255.0, blue:119/255.0, alpha: 1.0).cgColor
        loginButton.layer.cornerRadius = 15
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
