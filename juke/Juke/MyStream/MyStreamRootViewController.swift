//
//  MyStreamRootViewController.swift
//  Juke
//
//  Created by Conner Smith on 9/13/17.
//  Copyright © 2017 csmith. All rights reserved.
//

import UIKit

class MyStreamRootViewController: UIViewController {

    @IBOutlet var createNewStreamContainerView: UIView!
    @IBOutlet var myStreamContainerView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(MyStreamRootViewController.transitionChildViews), name: Notification.Name("userStreamChanged"), object: nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func transitionChildViews() {
        if Current.stream != nil {
            print("not nil")
            UIView.animate(withDuration: 0.5, animations: {
                self.myStreamContainerView.alpha = 1
                self.createNewStreamContainerView.alpha = 0
            })
        } else {
            print("nil")
            UIView.animate(withDuration: 0.5, animations: {
                self.createNewStreamContainerView.alpha = 1
                self.myStreamContainerView.alpha = 0
            })
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        transitionChildViews()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // set status bar text to white
    override var preferredStatusBarStyle: UIStatusBarStyle { return .lightContent }
}
