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
    
    private var BASE_URL: String = "http://api.godex.io:8080/api"
    
    private let DEFAULT_TIMEOUT = 5.0
    
    private var timeoutTimer: NSTimer?
    
    private var currentDatatask: NSURLSessionDataTask?
    
    private let uuid = UIDevice.currentDevice().identifierForVendor?.UUIDString

    
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
        let url = NSURL(string: BASE_URL + "/AllPokemon/Enabled")!
        
        if self.currentDatatask != nil {
            self.currentDatatask?.cancel()
            self.timeoutTimer?.invalidate()
            self.timeoutTimer = nil
        }
        
        self.currentDatatask = session.dataTaskWithURL(url) { (data:NSData?, response:NSURLResponse?, error:NSError?) in
            if error == nil {
                let json = self.dataToJson(data)
                
                if json.count > 0 {
                    if json[0]["error"] != nil {
                        self.throwError(nil, withMessage: json[0]["error"] as? String)
                        self.requestComplete()
                        return
                    }
                }
                
                let pokeArr = Pokemon.arrayFromJsonData(json)
                Pokemon.Pokedex = pokeArr
                self.delegate?.RequestManagerPokemonListRecieved(pokeArr)
            } else {
                self.throwError(error, withMessage: "Unable to fetch the pokemon list")
            }
            self.requestComplete()
        }
        self.startTheRequest()
    }
    
    /**
     Send a POST request to the database submitting catch data
     
     - parameter pokemon:     the caught pokemon
     - parameter coordinates: the user's current location
     */
    func submitACatch(pokemon: Pokemon, coordinates: CLLocationCoordinate2D) {
        if (uuid == nil) {
            self.delegate?.RequestManagerError(nil, withMessage: "A device UUID is required to post a sighting")
            return
        }
        
        let concatStringUrl = BASE_URL + "/CaughtPokemon/\(uuid!)/\(pokemon.id)/\(coordinates.latitude)/\(coordinates.longitude)"
        
        let url = NSURL(string: concatStringUrl)!
        let request = NSMutableURLRequest(URL: url)
        request.HTTPMethod = "POST"
        
        if self.currentDatatask != nil {
            self.currentDatatask?.cancel()
            self.timeoutTimer?.invalidate()
            self.timeoutTimer = nil
        }
        self.currentDatatask = session.dataTaskWithRequest(request) { (data:NSData?, response:NSURLResponse?, error:NSError?) in
            if error == nil {
                //success
                let json = self.dataToJson(data)
                
                if json.count > 0 {
                    if json[0]["error"] != nil {
                        self.throwError(nil, withMessage: json[0]["error"] as? String)
                    }
                    else {
                        NSOperationQueue.mainQueue().addOperationWithBlock({
                            self.delegate?.RequestManagerCatchSubmitted()
                        })
                    }
                    self.requestComplete()
                    return
                } else {
                    NSOperationQueue.mainQueue().addOperationWithBlock({
                        self.delegate?.RequestManagerCatchSubmitted()
                    })
                }
                
            } else {
                self.throwError(error, withMessage: "An error occured submitting your catch. Try again")
            }
            self.requestComplete()
        }
        self.startTheRequest()
    }
    
    /**
     Get location data for the selected pokemon
     
     - parameter pokemon: the query pokemon
     */
    func pokemonPinsLookup(pokemon: Pokemon) {
        //GET
        let url = NSURL(string: BASE_URL + "/CaughtPokemon/\(pokemon.id)")!
        
        if self.currentDatatask != nil {
            self.currentDatatask?.cancel()
            self.timeoutTimer?.invalidate()
            self.timeoutTimer = nil
        }
        self.currentDatatask = session.dataTaskWithURL(url) { (data: NSData?, response:NSURLResponse?, error:NSError?) in
            if error == nil {
                let json = self.dataToJson(data)
                
                if json.count > 0 {
                    if json[0]["error"] != nil {
                        self.throwError(nil, withMessage: json[0]["error"] as? String)
                        self.requestComplete()
                        return
                    }
                }
                
                var coorArray: [CLLocationCoordinate2D] = [CLLocationCoordinate2D]()
                for dict in json {
                    let lat = dict["geo_lat"] as! Double
                    let lon = dict["geo_long"] as! Double
                    let coor = CLLocationCoordinate2D(latitude: lat, longitude: lon)
                    coorArray.append(coor)
                }
                if (coorArray.count == 0){
                    NSOperationQueue.mainQueue().addOperationWithBlock({
                        self.delegate?.RequestManagerLookupResults(nil)
                    })
                } else {
                    NSOperationQueue.mainQueue().addOperationWithBlock({
                        self.delegate?.RequestManagerLookupResults(coorArray)
                    })
                }
            } else {
                self.throwError(error, withMessage: "An error occured fetching location results for \(pokemon.name)")
            }
            self.requestComplete()
        }
        self.startTheRequest()
    }
    
    /**
     Start the datatask with a custom timeout timer
     */
    private func startTheRequest() {
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
        if (self.timeoutTimer !== nil) {
            self.timeoutTimer?.invalidate()
        }
        self.timeoutTimer = NSTimer.scheduledTimerWithTimeInterval(DEFAULT_TIMEOUT, target: self, selector: #selector(self.requestTimeout), userInfo: nil, repeats: false)
        self.currentDatatask?.resume()
    }
    
    /**
     Clear the datatask and stop the activity indicator
     */
    private func requestComplete() {
        UIApplication.sharedApplication().networkActivityIndicatorVisible = false
        self.currentDatatask = nil
        self.timeoutTimer?.invalidate()
        self.timeoutTimer = nil
    }
    
    /**
     Fired by the custom timeout timer
     */
    @objc private func requestTimeout() {
        UIApplication.sharedApplication().networkActivityIndicatorVisible = false
        self.currentDatatask?.cancel()
        self.currentDatatask = nil
        self.timeoutTimer?.invalidate()
        self.timeoutTimer = nil
    }
    
    /**
     Parse url response NSData to a json styled object
     
     - parameter data: network NSData?
     
     - returns: a json Dictionary
     */
    private func dataToJson(data: NSData?) -> Array<Dictionary<String, AnyObject>> {
        var json: Array<Dictionary<String, AnyObject>> = Array<Dictionary<String, AnyObject>>()
        if (data == nil){
            return json
        }
        
        do {
            json = try NSJSONSerialization.JSONObjectWithData(data!, options: .AllowFragments) as! Array<Dictionary<String, AnyObject>>
        } catch {
            self.throwError(nil, withMessage: "Error parsing data to JSON")
        }
        return json
    }
    
}