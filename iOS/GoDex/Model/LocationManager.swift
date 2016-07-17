//
//  LocationManager.swift
//  GoDex
//
//  Created by Brandon Groff on 7/12/16.
//  Copyright © 2016 io.godex. All rights reserved.
//

import Foundation
import CoreLocation

protocol LocationManagerDelegate {
    func locationManagerCurrentLocationRecieved(location: CLLocation, coordinates: CLLocationCoordinate2D)
    func locationManagerUpdateError(error: NSError?, message: String?)
}

class LocationManager: NSObject, CLLocationManagerDelegate {
    
    private var clLocationManger: CLLocationManager
    
    //Nintendo HQ, USA
    static let DEFAULT_COORDINATE = CLLocationCoordinate2D(latitude: 47.6513757, longitude: -122.141262)
    
    var delegate: LocationManagerDelegate?
    
    private(set) var lastRecievedLocation: CLLocation? = nil
    
    private(set) var lastRecievedCoordinates: CLLocationCoordinate2D? = nil
    
    private override init () {
        self.clLocationManger = CLLocationManager()
        super.init()
        
        self.clLocationManger.delegate = self
        self.clLocationManger.desiredAccuracy = kCLLocationAccuracyBest
    }
    
    /**
     Run a one time check on the user's current location
     */
    func getCurrentLocation() {
        if CLLocationManager.authorizationStatus() == .NotDetermined {
            self.clLocationManger.requestWhenInUseAuthorization()
            return
        }
        
        if (CLLocationManager.locationServicesEnabled()) {
            self.clLocationManger.startUpdatingLocation()
        } else {
            self.lastRecievedCoordinates = LocationManager.DEFAULT_COORDINATE
            self.delegate?.locationManagerUpdateError(nil, message: "Location services are disabled. Please enable them in your settings")
        }
    }
    
    func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus)
    {
        if status == .AuthorizedAlways || status == .AuthorizedWhenInUse {
            self.getCurrentLocation()
        } else {
            self.delegate?.locationManagerUpdateError(nil, message: "Location services are disabled. Please enable them in your settings")
        }
    }

    
    @objc func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {
        if error.code == CLError.Denied.rawValue {
            self.delegate?.locationManagerUpdateError(nil, message: "Location services are disabled. Please enable them in your settings")
        } else {
            self.lastRecievedCoordinates = LocationManager.DEFAULT_COORDINATE
            self.delegate?.locationManagerUpdateError(error, message: "Unable to acquire current location")
        }
        self.clLocationManger.stopUpdatingLocation()
    }
    
    @objc func locationManager(manager: CLLocationManager, didUpdateToLocation newLocation: CLLocation, fromLocation oldLocation: CLLocation) {
        self.clLocationManger.stopUpdatingLocation()
        self.lastRecievedLocation =  newLocation
        self.lastRecievedCoordinates = newLocation.coordinate
        self.delegate?.locationManagerCurrentLocationRecieved(newLocation, coordinates: newLocation.coordinate)
    }
    
    // A global instance
    private static let GlobalManager: LocationManager = LocationManager()
    
    /**
     Get the global instance
     
     - returns: the shared LocationManager
     */
    class func sharedInstance() -> LocationManager {
        return LocationManager.GlobalManager
    }
}