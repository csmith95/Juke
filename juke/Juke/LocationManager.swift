//
//  LocationManager.swift
//  Juke
//
//  Created by Conner Smith on 3/15/17.
//  Copyright © 2017 csmith. All rights reserved.
//

import Foundation
import CoreLocation

class LocationManager: NSObject, CLLocationManagerDelegate {
    
    public static let sharedInstance = LocationManager()
    private let locationManager = CLLocationManager()
    private let kCLLocationAccuracyKilometer = 0.1
    private var lat: Double = 0.0
    private var long: Double = 0.0
    
    private override init() {
        super.init()
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
    
    public func getLat() -> Double {
        return lat
    }
    
    public func getLong() -> Double {
        return long
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let locationArray = locations as NSArray
        let locationObj = locationArray.lastObject as! CLLocation
        let coord = locationObj.coordinate
        self.lat = coord.latitude
        self.long = coord.longitude
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("ERROR RECEIVING LOCATION UPDATE: ", error)
    }
    
    @nonobjc func locationManager(manager: CLLocationManager!, didFailWithError error: NSError!) {
        locationManager.stopUpdatingLocation()
        if ((error) != nil) {
            print(error)
        }
    }
}
