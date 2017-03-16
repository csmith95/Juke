//
//  GroupsController.swift
//  Juke
//
//  Created by Conner Smith on 2/18/17.
//  Copyright © 2017 csmith. All rights reserved.
//

import UIKit
import CoreLocation
import Alamofire

class GroupsController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    struct Group {
        var name: String
        var id: String
        var owner_spotify_id: String
    }
    var groups: [Group] = []
    var selectedGroup: Group? = nil
    let locationManager = LocationManager.sharedInstance

    @IBOutlet weak var tableView: UITableView!
    var newGroupName: String?
    

    @IBAction func addItem(_ sender: Any) {
        alert()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        fetchNearbyPlaylists()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.dataSource = self
        tableView.delegate = self
    }
    
    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        objc_sync_enter(self.groups)
        self.selectedGroup = self.groups[indexPath.row]
        objc_sync_exit(self.groups)
        return indexPath
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == "displayGroup") {
            let vc = segue.destination as! GroupController
            vc.group = self.selectedGroup
        }
    }
    
    func fetchNearbyPlaylists() {
        let params: Parameters = ["latitude": self.locationManager.getLat(), "longitude": self.locationManager.getLong()]
        Alamofire.request(ServerConstants.kJukeServerURL + ServerConstants.kFetchNearbyPath, method: .get, parameters: params).validate().responseJSON { response in
            switch response.result {
            case .success:
                let nearbyGroups = response.result.value as! NSArray
                objc_sync_enter(self.groups)
                self.groups = []    // clear groups that have already been fetched to avoid duplicate displays
                for object in nearbyGroups {
                    let map = object as! NSDictionary
                    self.groups.append(Group(name: map["groupName"] as! String, id: map["_id"] as! String, owner_spotify_id: map["owner_spotify_id"] as! String))
                }
                objc_sync_exit(self.groups)
                
                // update UI on main thread
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
            case .failure(let error):
                print(error)
            }
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ListItem") as! GroupsTableViewCell
        cell.textLabel?.text = groups[indexPath.row].name
        return cell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return groups.count
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func alert() {
        let alert = UIAlertController(title: "", message: "Please name your new playlist.", preferredStyle: .alert)
        
        alert.addTextField {
            (textfield: UITextField) in
            textfield.placeholder = "Enter group name"
        }
        
        let add = UIAlertAction(title: "Add", style: .default) {
            (action) in
            
            let name = alert.textFields![0].text!
            
            // create group
            let params: Parameters = ["groupName" : name, "latitude": self.locationManager.getLat(), "longitude": self.locationManager.getLong(), "owner_spotify_id": ViewController.currSpotifyID]
            Alamofire.request(ServerConstants.kJukeServerURL + ServerConstants.kCreateGroupPath, method: .post, parameters: params).validate().responseJSON { response in
                switch response.result {
                case .success:
                    if let group = response.result.value as? NSDictionary {
                        let newGroup = Group(name: group["groupName"] as! String, id: group["_id"] as! String, owner_spotify_id: group["owner_spotify_id"] as! String)
                        objc_sync_enter(self.groups)
                        self.groups.append(newGroup)
                        objc_sync_exit(self.groups)
                        // update UI on main thread
                        DispatchQueue.main.async {
                            self.tableView.reloadData()
                        }
                    }
                case .failure(let error):
                    print(error)
                }
            }
        }
        
        let cancel = UIAlertAction(title: "Cancel", style: .cancel)
        alert.addAction(add)
        alert.addAction(cancel)
        present(alert, animated: true, completion: nil)
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // might need this function later to handle moving playlists (ex: car)
//    func updateLocation() {
//        objc_sync_enter(pendingGroupID)
//        if let groupID = self.pendingGroupID {  // update group location, if there's a pending group
//            self.pendingGroupID = nil
//            let params: Parameters = ["id" : groupID, "latitude": latitude, "longitude": longitude]
//            Alamofire.request(ServerConstants.kJukeServerURL + ServerConstants.kUpdateLocationPath, method: .post, parameters: params).validate().responseJSON { response in
//                switch response.result {
//                case .success:
//                    print("Set location for group ", groupID)
//                case .failure(let error):
//                    print(error)
//                }
//            }
//        }
//        objc_sync_exit(pendingGroupID)
//    }
}
