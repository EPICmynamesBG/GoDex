//
//  RequestManager.swift
//  GoDex
//
//  Created by Brandon Groff on 7/12/16.
//  Copyright © 2016 io.godex. All rights reserved.
//

import Foundation
import MapKit

protocol RequestManagerDelegate {
    func RequestManagerError(error: NSError?, withMessage message: String?)
    func RequestManagerPokemonListRecieved(pokemonArray: Array<Pokemon>)
    func RequestManagerCatchSubmitted()
    func RequestManagerLookupResults(results: Array<CLLocationCoordinate2D>?)
}

/// A class for simple API network requests
class RequestManager {
    
    private var session = NSURLSession.sharedSession()
    
    var delegate: RequestManagerDelegate?
    
    private var BASE_URL: String = ""
    
    private let DEFAULT_TIMEOUT = 5.0
    
    private var timeoutTimer: NSTimer?
    
    private var currentDatatask: NSURLSessionDataTask?
    
    init() {
        
    }
    
    /**
     Private: Throw an error to the delegate on the main operation queue
     
     - parameter error:   optional error
     - parameter message: optional description of the error
     */
    private func throwError(error: NSError?, withMessage message: String?) {
        NSOperationQueue.mainQueue().addOperationWithBlock { 
            self.delegate?.RequestManagerError(error, withMessage: message)
        }
    }
    
    /**
     Send a GET request to get the array of all pokemon
     */
    func getPokemonList() {
        let url = NSURL(string: BASE_URL + "/{endpoint}")!
        if self.currentDatatask != nil {
            self.currentDatatask?.cancel()
        }
        self.currentDatatask = session.dataTaskWithURL(url) { (data:NSData?, response:NSURLResponse?, error:NSError?) in
            if error == nil {
                //process the request, fire appropriate delegate
            } else {
                self.throwError(error, withMessage: "Unable to fetch the pokemon list")
            }
            self.currentDatatask = nil
        }
        self.startTheRequest()
    }
    
    /**
     Send a POST request to the database submitting catch data
     
     - parameter pokemon:     the caught pokemon
     - parameter coordinates: the user's current location
     */
    func submitACatch(pokemon: Pokemon, coordinates: CLLocationCoordinate2D) {
        let url = NSURL(string: BASE_URL + "/{endpoint}")!
        let request = NSMutableURLRequest(URL: url)
        
        let json: [String: AnyObject] = [
            "pokemon_id": pokemon.id,
            "geo_lat" : coordinates.latitude,
            "geo_long" : coordinates.longitude
        ]
        
        var jsonData: NSData? = nil
        do {
            jsonData = try NSJSONSerialization.dataWithJSONObject(json, options: NSJSONWritingOptions.PrettyPrinted)
            // here "jsonData" is the dictionary encoded in JSON data
        } catch let error as NSError {
            print(error)
        }
        if (jsonData == nil) {
            self.delegate?.RequestManagerError(nil, withMessage: "Unable to parse Dictionary to JSON")
            return
        }
        
        request.HTTPBody = jsonData
        request.HTTPMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if self.currentDatatask != nil {
            self.currentDatatask?.cancel()
        }
        self.currentDatatask = session.dataTaskWithRequest(request) { (data:NSData?, response:NSURLResponse?, error:NSError?) in
            if error == nil {
                //success
            } else {
                self.throwError(error, withMessage: "An error occured submitting your catch")
            }
            self.currentDatatask = nil
        }
        self.startTheRequest()
    }
    
    /**
     Get location data for the selected pokemon
     
     - parameter pokemon: the query pokemon
     */
    func pokemonLookup(pokemon: Pokemon) {
        let url = NSURL(string: BASE_URL + "/\(pokemon.id)")!
        self.currentDatatask = session.dataTaskWithURL(url) { (data: NSData?, response:NSURLResponse?, error:NSError?) in
            if error == nil {
                //success, process
            } else {
                self.throwError(error, withMessage: "An error occured fetching location results for \(pokemon.name)")
            }
            self.currentDatatask = nil
        }
        self.startTheRequest()
    }
    
    /**
     Start the datatask with a custom timeout timer
     */
    private func startTheRequest() {
        if (self.timeoutTimer !== nil) {
            self.timeoutTimer?.fire()
            self.timeoutTimer?.invalidate()
        }
        self.timeoutTimer = NSTimer.scheduledTimerWithTimeInterval(DEFAULT_TIMEOUT, target: self, selector: #selector(self.requestTimeout), userInfo: nil, repeats: false)
        self.currentDatatask?.resume()
    }
    
    /**
     Fired by the custom timeout timer
     */
    @objc private func requestTimeout() {
        self.currentDatatask?.cancel()
        self.currentDatatask = nil
        self.timeoutTimer?.invalidate()
        self.timeoutTimer = nil
    }
    
}