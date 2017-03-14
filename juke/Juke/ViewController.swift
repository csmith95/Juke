//
//  ViewController.swift
//  Juke
//
//  Created by Conner Smith on 2/18/17.
//  Copyright © 2017 csmith. All rights reserved.
//

import UIKit

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
    
    func loginSuccessful() {
        let player = JamsPlayer.shared  // to kick off authentication of player before user gets to playlist page
        performSegue(withIdentifier: "loginSegue", sender: nil)
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
