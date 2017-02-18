//
//  SearchViewController.swift
//  Juke
//
//  Created by Conner Smith on 2/18/17.
//  Copyright © 2017 csmith. All rights reserved.
//

import UIKit

class SearchViewController: UIViewController, UITableViewDataSource {

    @IBOutlet weak var tableView: UITableView!
    struct TrackInfo {
        var id: String
        var artist: String
        var name: String
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.dataSource = self
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func tableView(_ tableView: UITableView,
                   numberOfRowsInSection section: Int) -> Int {
        return 0
    }
    
    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        return UITableViewCell()
    }
    
    
    func searchForWords(terms: String) -> [TrackInfo] {
        let userDefaults = UserDefaults.standard
        if let session = userDefaults.object(forKey: "spotify_sesson") {
            
            //SPTSearch
            
        } else {
            print("NO SESSION FOUND")
        }
        
        return []
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
