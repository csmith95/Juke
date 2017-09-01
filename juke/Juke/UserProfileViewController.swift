//
//  UserProfileViewController.swift
//  Juke
//
//  Created by Kojo Worai Osei on 8/25/17.
//  Copyright © 2017 csmith. All rights reserved.
//

import UIKit

class UserProfileViewController: UIViewController {
    
    var preloadedUser: Models.FirebaseUser?

    @IBOutlet weak var userImage: UIImageView!
    @IBOutlet weak var userName: UILabel!
    @IBOutlet weak var inviteToStreamBtn: UIButton!
    @IBOutlet weak var userPresenceDot: UIImageView!
    private let defaultIcon = UIImage(named: "juke_icon")!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUserProfile(user: preloadedUser!)

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    
    public func setUserProfile(user: Models.FirebaseUser) {
        userName.text = user.username
        loadUserIcon(url: user.imageURL, imageView: userImage)
        if user.online {
            userPresenceDot.image = #imageLiteral(resourceName: "green dot")
        } else {
            userPresenceDot.image = #imageLiteral(resourceName: "red dot")
        }
    }
    
    private func loadUserIcon(url: String?, imageView: UIImageView) {
        if let unwrappedUrl = url {
            imageView.af_setImage(withURL: URL(string: unwrappedUrl)!, placeholderImage: defaultIcon)
        } else {
            imageView.image = defaultIcon
        }
    }
    @IBAction func notifyInviteToStream(_ sender: Any) {
        print("called invite to stream")
        FirebaseAPI.sendNotification(receiver: preloadedUser!)
    }

}
