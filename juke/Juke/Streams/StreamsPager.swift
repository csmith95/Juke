//
//  StreamsPagerVC.swift
//  Juke
//
//  Created by Kojo Worai Osei on 9/20/17.
//  Copyright © 2017 csmith. All rights reserved.
//

import Foundation
import XLPagerTabStrip

class StreamsPager: ButtonBarPagerTabStripViewController {
    
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
            //oldCell?.label.textColor = .black
            //newCell?.label.textColor = self?.purpleInspireColor
        }
        
//        settings.style.selectedBarBackgroundColor = UIColor.clear
//        settings.style.buttonBarItemBackgroundColor = UIColor.clear
//        changeCurrentIndexProgressive = { [weak self] (oldCell: ButtonBarViewCell?, newCell: ButtonBarViewCell?, progressPercentage: CGFloat, changeCurrentIndex: Bool, animated: Bool) -> Void in
//            guard changeCurrentIndex == true else { return }
//            //oldCell?.label.textColor = .black
//            //newCell?.label.textColor = self?.purpleInspireColor
//        }
        super.viewDidLoad()
    }
    
    override func viewControllers(for pagerTabStripController: PagerTabStripViewController) -> [UIViewController] {
        let child_1 = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "starredStreams")
        let child_2 = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "allStreams")
        return [child_1, child_2]
    }
    
}

