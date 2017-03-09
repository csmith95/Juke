//
//  GroupController.swift
//  Juke
//
//  Created by Conner Smith on 2/23/17.
//  Copyright © 2017 csmith. All rights reserved.
//

import UIKit
import Alamofire

class GroupController: UITableViewController {
    
    let kServerBaseURL = "http://myjukebx.herokuapp.com/"
    let kFetchSongsPath = "/fetchSongs"

    var navBarTitle: String? {
        get {
            return self.navigationItem.title
        }
        set (newValue) {
            self.navigationItem.title = newValue
        }
    }
    
    var group: QueuesController.Group?
    let jamsPlayer = JamsPlayer.sharedInstance
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navBarTitle = group?.name
        fetchSongs()
    }

    @IBAction func searchButtonPressed(_ sender: AnyObject) {
        performSegue(withIdentifier: "searchSegue", sender: sender)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == "searchSegue") {
            let vc = segue.destination as! SearchTableViewController
            vc.group = self.group
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 0
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return 0
    }
    
    
    // fetch songs and trigger table reload
    func fetchSongs() {
        
        Alamofire.request(URL(string: kServerBaseURL + kFetchSongsPath)!, method: .get, parameters: ["group_id":self.group?.id]).responseJSON { response in
            
         print(response)
            
        }
        
//        // issue GET request, handle response
//        serverDelegate.getRequest(path: kFetchNearbyPath, fields: dict) { (data: Data?, response: URLResponse?, error: Error?) in
//            
//            do {
//                let json = try JSONSerialization.jsonObject(with: data!, options: JSONSerialization.ReadingOptions.allowFragments) as! NSArray
//                if json.count == 0 {
//                    return
//                }
//                
//                for object in json {
//                    let map = object as! NSDictionary
//                    let discoveredGroup = Group(name: map["groupName"] as! String, id: map["_id"] as? String)
//                    if !self.groups.contains(where: { (group) -> Bool in
//                        group.id == discoveredGroup.id
//                    }) {
//                        self.groups.append(discoveredGroup) // group hasn't been fetched yet
//                    }
//                }
//                
//                // update UI on main thread
//                DispatchQueue.main.async {
//                    self.tableView.reloadData()
//                }
//            } catch {
//                print("ERROR: ", error)
//            }
//        }
    }

}
