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
    let allStreamsSource = StreamsDataSource()
    let starredStreamsSource = StarredStreamsDataSource()
    var streamsSource: CustomDataSource?
    var notificationName: String?
    
    let purpleInspireColor = UIColor(red:0.13, green:0.03, blue:0.25, alpha:1.0)
    
    override func viewDidLoad() {
        // change selected bar color
        settings.style.buttonBarBackgroundColor = .clear
        settings.style.buttonBarItemBackgroundColor = .clear
        settings.style.selectedBarBackgroundColor = .white
        //settings.style.buttonBarItemFont = .boldSystemFont(ofSize: 14)
        settings.style.selectedBarHeight = 2.0
        settings.style.buttonBarMinimumLineSpacing = 0
        settings.style.buttonBarItemTitleColor = .white
        settings.style.buttonBarItemsShouldFillAvailiableWidth = true
        settings.style.buttonBarLeftContentInset = 0
        settings.style.buttonBarRightContentInset = 0
        changeCurrentIndexProgressive = { [weak self] (oldCell: ButtonBarViewCell?, newCell: ButtonBarViewCell?, progressPercentage: CGFloat, changeCurrentIndex: Bool, animated: Bool) -> Void in
            guard changeCurrentIndex == true else { return }
            //print("NEW LABELLLLLLLLLLLLLLLLLL", newCell?.label.text)
            if newCell?.label.text == "All" {
                //set who receives notification
                self?.notificationName = "allStreamsSearchNotification"
                self?.searchBar.text = ""

                self?.execSearchQuery()

            } else {
                //set who receives notification
                self?.notificationName = "starredStreamsSearchNotification"
                self?.searchBar.text = ""
                self?.execSearchQuery()

            }
        }
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
    
    
    
    
    
}

