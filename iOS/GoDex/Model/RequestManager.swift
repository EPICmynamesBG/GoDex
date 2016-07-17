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
    func RequestManagerLookupResults(results: [CLLocationCoordinate2D]?, pokeArr: Array<Pokemon>?)
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
                self.throwError(error, withMessage: "We weren't able to load the Pokemon list")
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
            self.delegate?.RequestManagerError(nil, withMessage: "")
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
    func pokemonPinsLookup(pokemon: Pokemon?) {
        //GET
        var url = NSURL(string: BASE_URL + "/CaughtPokemon")!
        if (pokemon != nil){
            url = NSURL(string: BASE_URL + "/CaughtPokemon/\(pokemon!.id)")!
        }
        
        
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
                
                let pokeArr = Pokemon.arrayFromJsonData(json)
                var coorArray: [CLLocationCoordinate2D] = [CLLocationCoordinate2D]()
                for dict in json {
                    let lat = dict["geo_lat"] as! Double
                    let lon = dict["geo_long"] as! Double
                    let coor = CLLocationCoordinate2D(latitude: lat, longitude: lon)
                    coorArray.append(coor)
                }
                if (coorArray.count == 0){
                    NSOperationQueue.mainQueue().addOperationWithBlock({
                        self.delegate?.RequestManagerLookupResults(nil, pokeArr: nil)
                    })
                } else {
                    NSOperationQueue.mainQueue().addOperationWithBlock({
                        self.delegate?.RequestManagerLookupResults(coorArray, pokeArr: pokeArr)
                    })
                }
            } else {
                if (pokemon != nil){
                    self.throwError(error, withMessage: "Uh-oh, something went wrong trying to find \(pokemon!.name)")

                } else {
                    self.throwError(error, withMessage: "Uh-oh, something went wrong")

                }
            }
            self.requestComplete()
        }
        self.startTheRequest()
    }
    
    /**
     send Anonymous Feedback
     
     - parameter feedback:  the feedback text
     - parameter onSuccess: function to run on success
     - parameter onError:   function to run on error
     */
    func sendFeedback(feedback: String, onSuccess: ((Array<Dictionary<String, AnyObject>>) -> Void)?, onError: ((NSError?, String?) -> Void)?) {
        
        let stringUrl = BASE_URL + "/Feedback"
        
        let url = NSURL(string: stringUrl)!
        let request = NSMutableURLRequest(URL: url)
        let bodyJson = [
            "feedback": feedback
        ]
        do {
            let jsonData = try NSJSONSerialization.dataWithJSONObject(bodyJson, options: .PrettyPrinted)
            request.HTTPBody = jsonData
        } catch {
            onError?(nil, "Looks lke your feedback got lost in transit. Try submitting your feedback again later, we'd really like to hear it!")
            return
        }
        request.HTTPMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if self.currentDatatask != nil {
            self.currentDatatask?.cancel()
            self.timeoutTimer?.invalidate()
            self.timeoutTimer = nil
        }
        self.currentDatatask = session.dataTaskWithRequest(request) { (data:NSData?, response:NSURLResponse?, error:NSError?) in
            if error == nil {
                //success
                let json = self.dataToJson(data)
                onSuccess?(json)
            } else {
                onError?(error, "Looks lke your feedback got lost in transit. Try submitting your feedback again later, we'd really like to hear it!")
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
        
        if (Pokemon.Pokedex == nil) {
            let url = NSURL(string: BASE_URL + "/AllPokemon/Enabled")!
            let temp = session.dataTaskWithURL(url) { (data:NSData?, response:NSURLResponse?, error:NSError?) in
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
                    self.timeoutTimer = NSTimer.scheduledTimerWithTimeInterval(self.DEFAULT_TIMEOUT, target: self, selector: #selector(self.requestTimeout), userInfo: nil, repeats: false)
                    self.currentDatatask?.resume()
                } else {
                    self.throwError(error, withMessage: "We weren't able to load the Pokemon list")
                }
                self.requestComplete()
            }
            temp.resume()
        } else {
            self.timeoutTimer = NSTimer.scheduledTimerWithTimeInterval(DEFAULT_TIMEOUT, target: self, selector: #selector(self.requestTimeout), userInfo: nil, repeats: false)
            self.currentDatatask?.resume()
        }
        
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
            self.throwError(nil, withMessage: "Darn server, we've got some bad data here")
        }
        return json
    }
    
}