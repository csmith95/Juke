//
//  QueuesController.swift
//  Juke
//
//  Created by Conner Smith on 2/18/17.
//  Copyright © 2017 csmith. All rights reserved.
//

import UIKit
import CoreLocation
import Alamofire

class QueuesController: UIViewController, UITableViewDataSource, CLLocationManagerDelegate, UITableViewDelegate {
    
    struct Group {
        var name: String
        var id: String?
    }
    var groups: [Group] = []
    var selectedGroup: Group? = nil
    var pendingGroupID: String? = nil
    
    let locationManager = CLLocationManager()
    let kCLLocationAccuracyKilometer = 0.1

    @IBOutlet weak var tableView: UITableView!
    var newGroupName: String?
    

    @IBAction func addItem(_ sender: Any) {
        alert()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.dataSource = self
        tableView.delegate = self
        
        // Ask for authorization from the User.
        if CLLocationManager.locationServicesEnabled() {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
            locationManager.requestWhenInUseAuthorization()
            locationManager.desiredAccuracy = kCLLocationAccuracyKilometer;

            // Set a movement threshold for new events.
            locationManager.distanceFilter = 60; // meters
        }
        
        // request location to fetch nearby playlists
        locationManager.requestLocation()
    }
    
    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        self.selectedGroup = self.groups[indexPath.row]
        return indexPath
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == "displayGroup") {
            let vc = segue.destination as! GroupController
            vc.group = self.selectedGroup
        }
    }
    
    
    func fetchNearbyPlaylists(latitude: Double, longitude: Double) {
        
        
        let params: Parameters = ["latitude": latitude, "longitude": longitude]
        Alamofire.request(ServerConstants.kJukeServerURL + ServerConstants.kFetchNearbyPath, method: .get, parameters: params).validate().responseJSON { response in
            switch response.result {
            case .success:
                let nearbyGroups = response.result.value as! NSArray
                self.groups = []    // clear groups that have already been fetched to avoid duplicate displays
                for object in nearbyGroups {
                    let map = object as! NSDictionary
                    self.groups.append(Group(name: map["groupName"] as! String, id: map["_id"] as? String))
                }
                
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
        let cell: QueueTableViewCell = tableView.dequeueReusableCell(withIdentifier: "ListItem") as! QueueTableViewCell
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
            
            let textField = alert.textFields![0]
            
            // prematurely create the group w/o ID so UI feels responsive.
            // ID field is set inside POST callback
            let newGroup = Group(name: textField.text!, id: nil)
            self.groups.append(newGroup)
            self.tableView.reloadData()
            self.newGroupName = textField.text!
            
            // create group
            let params: Parameters = ["groupName" : newGroup.name]
            Alamofire.request(ServerConstants.kJukeServerURL + ServerConstants.kCreateGroupPath, method: .post, parameters: params).validate().responseJSON { response in
                switch response.result {
                case .success:
                    let group = response.result.value as! NSDictionary
                    self.pendingGroupID = group["_id"] as? String
                    self.locationManager.requestLocation() // set group location later inside location callback
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
    
    // MARK: - CoreLocation Delegate Methods
    @nonobjc func locationManager(manager: CLLocationManager!, didFailWithError error: NSError!) {
        locationManager.stopUpdatingLocation()
        if ((error) != nil) {
            print(error)
        }
    }
    
    var pendingGroupIDLock = pthread_mutex_t()
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        let locationArray = locations as NSArray
        let locationObj = locationArray.lastObject as! CLLocation
        let coord = locationObj.coordinate
        let latitude = coord.latitude
        let longitude = coord.longitude
    
        fetchNearbyPlaylists(latitude: latitude, longitude: longitude)
        pthread_mutex_lock(&pendingGroupIDLock)
        if let groupID = self.pendingGroupID {  // update group location, if there's a pending group
            self.pendingGroupID = nil
            let params: Parameters = ["id" : groupID, "latitude": latitude, "longitude": longitude]
            Alamofire.request(ServerConstants.kJukeServerURL + ServerConstants.kUpdateLocationPath, method: .post, parameters: params).validate().responseJSON { response in
                switch response.result {
                case .success:
                    print("Set location for group ", groupID)
                case .failure(let error):
                    print(error)
                }
            }
        }
        pthread_mutex_unlock(&pendingGroupIDLock)
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("ERROR RECEIVING LOCATION UPDATE: ", error)
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
