//
//  QueuesController.swift
//  Juke
//
//  Created by Conner Smith on 2/18/17.
//  Copyright © 2017 csmith. All rights reserved.
//

import UIKit
import CoreLocation

class QueuesController: UIViewController, UITableViewDataSource, CLLocationManagerDelegate {
    
    var items: [String] = ["Hello World", "dkgakjdsg"]
    let locationManager = CLLocationManager()
    let kCLLocationAccuracyKilometer = 0.1

    @IBOutlet weak var tableView: UITableView!

    @IBAction func addItem(_ sender: Any) {
        alert()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.dataSource = self
        
        // Ask for authorization from the User.
        if CLLocationManager.locationServicesEnabled() {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
            locationManager.requestWhenInUseAuthorization()
            locationManager.desiredAccuracy = kCLLocationAccuracyKilometer;

            // Set a movement threshold for new events.
            locationManager.distanceFilter = 60; // meters
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell:QueueTableViewCell = tableView.dequeueReusableCell(withIdentifier: "ListItem") as! QueueTableViewCell
        cell.textLabel?.text = items[indexPath.row]
        return cell
    }
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func alert() {
        let alert = UIAlertController(title: "", message: "Please name your new playlist.", preferredStyle: .alert)
        
        alert.addTextField {
            (textfield: UITextField) in
            textfield.placeholder = "Enter name"
        }
        
        let add = UIAlertAction(title: "Add", style: .default) {
            (action) in
            let textfield = alert.textFields![0]
            self.items.append(textfield.text!)
            self.tableView.reloadData()
            
            // TODO: get location, register playlist w/ db
            self.locationManager.requestLocation()
            print("REQUESTED LOCATION")
        }
        
        let cancel = UIAlertAction(title: "Cancel", style: .cancel) {
            (action) in
            print("hi")
        }
        
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
        print("LONG: ", coord.longitude)
        print("LAT: ", coord.latitude)
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
