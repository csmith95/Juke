//
//  MyStreamRootViewController.swift
//  Juke
//
//  Created by Conner Smith on 9/13/17.
//  Copyright © 2017 csmith. All rights reserved.
//

import UIKit

final class MyStreamRootViewController: UIViewController {
    
    var currentControllerID = ""
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    // init child view controllers
    private lazy var emptyStreamViewController: EmptyStreamViewController = {
        // Load Storyboard
        let storyboard = UIStoryboard(name: "Main", bundle: Bundle.main)

        // Instantiate View Controller
        var viewController = storyboard.instantiateViewController(withIdentifier: "EmptyStreamViewController") as! EmptyStreamViewController
        
        return viewController
    }()
    
    private lazy var myStreamController: MyStreamController = {
        // Load Storyboard
        let storyboard = UIStoryboard(name: "Main", bundle: Bundle.main)
        
        // Instantiate View Controller
        var viewController = storyboard.instantiateViewController(withIdentifier: "MyStreamController") as! MyStreamController
        
        return viewController
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // whenever top song changes or user stream changes, see if this tab should animate
        // to/from empty controller to/from my stream controller
        NotificationCenter.default.addObserver(self, selector: #selector(MyStreamRootViewController.updateChildViews), name: Notification.Name("updateMyStreamView"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(MyStreamRootViewController.updateChildViews), name: Notification.Name("changedStreams"), object: nil)
        updateChildViews()
    }
    
    func updateChildViews() {
        var toRemove: UIViewController!
        var toAdd: UIViewController!
        if Current.stream == nil || Current.stream!.song == nil {
            toRemove = myStreamController
            toAdd = emptyStreamViewController
        } else {
            toRemove = emptyStreamViewController
            toAdd = myStreamController
        }
    
        if currentControllerID == toAdd.restorationIdentifier! {
            return  // never animate to the same controller
        }
        currentControllerID = toAdd.restorationIdentifier!
        
        toRemove.willMove(toParentViewController: nil)
        self.addChildViewController(toAdd)
        self.view.addSubview(toAdd.view)
        toAdd.view.alpha = 0
        toAdd.view.layoutIfNeeded()
        
        // animate transition
        UIView.animate(withDuration: 0.5, animations: {
            toAdd.view.alpha = 1
            toRemove.view.alpha = 0
        },
        completion: { finished in
                toRemove.view.removeFromSuperview()
                toRemove.removeFromParentViewController()
                toAdd.didMove(toParentViewController: self)
        })
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // set status bar text to white
    override var preferredStatusBarStyle: UIStatusBarStyle { return .lightContent }
}
