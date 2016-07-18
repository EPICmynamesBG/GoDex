//
//  LocationManager.swift
//  GoDex
//
//  Created by Brandon Groff on 7/12/16.
//  Copyright © 2016 io.godex. All rights reserved.
//

import Foundation
import CoreLocation

/**
 *  @author io.godex, 16-07-18 09:07
 *
 *  A Delegate for LocationManager
 */
protocol LocationManagerDelegate {
    func locationManagerCurrentLocationRecieved(location: CLLocation, coordinates: CLLocationCoordinate2D)
    func locationManagerUpdateError(error: NSError?, message: String?)
}

/// Simplified usage of CLLocationManager
class LocationManager: NSObject, CLLocationManagerDelegate {
    
    /// built in CoreLocation LacationManager object
    private var clLocationManger: CLLocationManager
    
    //Nintendo HQ, USA
    static let DEFAULT_COORDINATE = CLLocationCoordinate2D(latitude: 47.6513757, longitude: -122.141262)
    
    var delegate: LocationManagerDelegate?
    
    /// The last recieved CLLocation
    private(set) var lastRecievedLocation: CLLocation? = nil
    
    /// The last recieved Location Coordinates
    private(set) var lastRecievedCoordinates: CLLocationCoordinate2D? = nil
    
    /**
     Location Manager object initializer
     
     - author: io.godex
     - date: 16-07-18 09:07
     
     - returns: self (LocationManager)
     */
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
    
    /**
     CLLocationManagerDelegate function - called whenever the authorization status
     changes. Calls getCurrentLocation when allowed
     
     - author: io.godex
     - date: 16-07-18 09:07
     
     - parameter manager: the CLLocationManager
     - parameter status:  the app's location usage authorization
     */
    func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus)
    {
        if status == .AuthorizedAlways || status == .AuthorizedWhenInUse {
            self.getCurrentLocation()
        } else {
            self.delegate?.locationManagerUpdateError(nil, message: "Location services are disabled. Please enable them in your settings")
        }
    }

    /**
     CLLocationManagerDelegate function - called when an error occurs getting
     the current location
     
     - author: io.godex
     - date: 16-07-18 09:07
     
     - parameter manager: the CLLocationManager
     - parameter error:   the occured error
     */
    @objc func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {
        if error.code == CLError.Denied.rawValue {
            self.delegate?.locationManagerUpdateError(nil, message: "Location services are disabled. Please enable them in your settings")
        } else {
            self.lastRecievedCoordinates = LocationManager.DEFAULT_COORDINATE
            self.delegate?.locationManagerUpdateError(error, message: "Unable to acquire current location")
        }
        self.clLocationManger.stopUpdatingLocation()
    }
    
    /**
     CLLocationManagerDelegate function - called when the location is successfully recieved
     
     - author: io.godex
     - date: 16-07-18 09:07
     
     - parameter manager:     the CLLocationManager
     - parameter newLocation: the new CLLocation
     - parameter oldLocation: the old CLLocation
     */
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