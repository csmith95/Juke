//
//  QueuesController.swift
//  Juke
//
//  Created by Conner Smith on 2/18/17.
//  Copyright © 2017 csmith. All rights reserved.
//

import UIKit
import CoreLocation

class QueuesController: UIViewController, UITableViewDataSource, CLLocationManagerDelegate, UITableViewDelegate {
    
    struct Group {
        var groupName: String
        var groupID: String?
    }
    var groups: [Group] = []
    var selectedGroup: Group? = nil
    
    let locationManager = CLLocationManager()
    let kCLLocationAccuracyKilometer = 0.1
    let serverDelegate = ServerDelegate()
    let kCreateGroupQuery = "createGroup"
    let kFetchNearbyQuery = "findNearbyGroups"

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
        
        // create fields for GET request
        let fields: [String:Double] = [
            "latitude" : latitude,
            "longitude" : longitude
        ]
        let dict = NSDictionary(dictionary: fields)
        
        // issue GET request, handle response
        serverDelegate.getRequest(query: kFetchNearbyQuery, fields: dict) { (data: Data?, response: URLResponse?, error: Error?) in
            
            do {
                let json = try JSONSerialization.jsonObject(with: data!, options: JSONSerialization.ReadingOptions.allowFragments) as! NSArray
                if json.count == 0 {
                    return
                }
                
                for object in json {
                    let map = object as! NSDictionary
                    let discoveredGroup = Group(groupName: map["groupName"] as! String, groupID: map["_id"] as? String)
                    if !self.groups.contains(where: { (group) -> Bool in
                        group.groupID == discoveredGroup.groupID
                    }) {
                        self.groups.append(discoveredGroup) // group hasn't been fetched yet
                    }
                }
                
                // update UI on main thread
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
            } catch {
                print("ERROR: ", error)
            }
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: QueueTableViewCell = tableView.dequeueReusableCell(withIdentifier: "ListItem") as! QueueTableViewCell
        cell.textLabel?.text = groups[indexPath.row].groupName
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
            let newGroup = Group(groupName: textField.text!, groupID: nil)
            self.groups.append(newGroup)
            self.tableView.reloadData()
            
            // get location then register playlist w/ db inside location callback
            self.newGroupName = textField.text!
            self.locationManager.requestLocation()
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
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        let locationArray = locations as NSArray
        let locationObj = locationArray.lastObject as! CLLocation
        let coord = locationObj.coordinate
        let latitude = coord.latitude
        let longitude = coord.longitude
        
        fetchNearbyPlaylists(latitude: latitude, longitude: longitude)
        if self.newGroupName == nil {
            return
        }
        
        // create fields for POST request
        let fields: [String:String] = [
            "groupName" : self.newGroupName!,
            "latitude" : String(latitude),
            "longitude" : String(longitude)
        ]
        let dict = NSDictionary(dictionary: fields)
        
        // issue POST request, handle response
        serverDelegate.postRequest(query: kCreateGroupQuery, fields: dict) { (data: Data?, response: URLResponse?, error: Error?) in
            if self.newGroupName == nil {
                return
            }
            self.newGroupName = nil
            
            // fill cells in TableView
            do {
                let json = try JSONSerialization.jsonObject(with: data!, options: JSONSerialization.ReadingOptions.allowFragments) as! NSDictionary
                let groupName = json["groupName"] as! String
                let groupID = json["_id"] as! String
                for i in 0 ..< self.groups.count {
                    if self.groups[i].groupName == groupName {
                        self.groups[i].groupID = groupID
                        return
                    }
                }
            } catch {
                print("ERROR: ", error)
            }
        }
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
