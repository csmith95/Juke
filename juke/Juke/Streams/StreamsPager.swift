//
//  StreamsPagerVC.swift
//  Juke
//
//  Created by Kojo Worai Osei on 9/20/17.
//  Copyright © 2017 csmith. All rights reserved.
//

import UIKit
import XLPagerTabStrip

class StreamsPager: ButtonBarPagerTabStripViewController, UISearchBarDelegate {
    
    @IBOutlet var searchBar: UISearchBar!
    var notificationName: String!
    
    override func viewDidLoad() {
        
        // change selected bar color
        settings.style.buttonBarBackgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0)
        settings.style.buttonBarItemBackgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0)
        settings.style.selectedBarBackgroundColor = .white
        settings.style.buttonBarItemFont = UIFont.systemFont(ofSize: 16)
        settings.style.selectedBarHeight = 2.0
        settings.style.buttonBarMinimumLineSpacing = 0
        settings.style.buttonBarItemTitleColor = .white
        settings.style.buttonBarItemsShouldFillAvailiableWidth = true
        settings.style.buttonBarLeftContentInset = 0
        settings.style.buttonBarRightContentInset = 0
       
        changeCurrentIndexProgressive = { [weak self] (oldCell: ButtonBarViewCell?, newCell: ButtonBarViewCell?, progressPercentage: CGFloat, changeCurrentIndex: Bool, animated: Bool) -> Void in
            guard changeCurrentIndex == true else { return }
            if oldCell == nil || newCell == nil { return }  // because this block fires on init
            
            //set who receives notification
            if newCell?.label.text == "All" {
                self?.notificationName = "allStreamsSearchNotification"
            } else {
                self?.notificationName = "starredStreamsSearchNotification"
            }
            self?.searchBar.text = ""
            self?.execSearchQuery()
        }
        // notification should start as MySongsSearchNotification
        self.notificationName = "starredStreamsSearchNotification"
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.hideKeyboard), name: Notification.Name("hideKeyboard"), object: nil)
        
        super.viewDidLoad()
    }
    
    override func viewControllers(for pagerTabStripController: PagerTabStripViewController) -> [UIViewController] {
        let child_1 = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "starredStreams")
        let child_2 = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "allStreams")
        return [child_1, child_2]
    }
    
    func hideKeyboard() {
        self.view.endEditing(true)
        searchBar.setShowsCancelButton(false, animated: true)
    }
    
    private func execSearchQuery() {
        if let query = searchBar.text {
            NotificationCenter.default.post(name: Notification.Name(notificationName!), object: nil, userInfo: ["query" : query])
        }
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        //print("called search bar did change")
        execSearchQuery()
    }
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        searchBar.setShowsCancelButton(true, animated: true)
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.text = ""
        execSearchQuery()
        hideKeyboard()
    }
    
    // set status bar content to white text
    override var preferredStatusBarStyle: UIStatusBarStyle { return .lightContent }
}
