//
//  RequestManager.swift
//  GoDex
//
//  Created by Brandon Groff on 7/12/16.
//  Copyright © 2016 io.godex. All rights reserved.
//

import Foundation
import MapKit

/**
 *  @author io.godex, 16-07-18 13:07
 *
 *  A delegate for handling Network Request results
 */
protocol RequestManagerDelegate {
    func RequestManagerError(error: NSError?, withMessage message: String?)
    func RequestManagerPokemonListRecieved(pokemonArray: Array<Pokemon>)
    func RequestManagerCatchSubmitted()
    func RequestManagerLookupResults(results: [CLLocationCoordinate2D]?, pokeArr: Array<Pokemon>?)
}

/// A class for simple API network requests
class RequestManager {
    
    /// The global NSURLSession object
    private var session = NSURLSession.sharedSession()
    
    var delegate: RequestManagerDelegate?
    
    /// The APIs base url
    private var BASE_URL: String = "http://api.godex.io:8080/api"
    
    /// The default timeout for a request
    private let DEFAULT_TIMEOUT = 5.0
    
    /// The timer that manages the custom timeout
    private var timeoutTimer: NSTimer?
    
    /// The current network request in action
    private var currentDatatask: NSURLSessionDataTask?
    
    /// This device's ID
    private let uuid = UIDevice.currentDevice().identifierForVendor?.UUIDString

    /**
     Simple Enum for determining Network Request type
     
     - author: io.godex
     - date: 16-07-18 09:07
     
     - GET:    a GET request type
     - POST:   a POST request type
     - PUT:    a PUT request type
     - DELETE: a DELETE request type
     */
    private enum RequestType: String {
        case GET = "GET"
        case POST = "POST"
        case PUT = "PUT"
        case DELETE = "DELETE"
        
        static func ToString() -> String {
            return self.RawValue() 
        }
    }
    
    
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
        let url = BASE_URL + "/AllPokemon/Enabled"
        print("HERE")
        self.sendRequestWithOptions(.GET, withURL: url, withBodyData: nil, onSuccess: { (json) in
            print("HERE2")
            let pokeArr = Pokemon.arrayFromJsonData(json)
            Pokemon.Pokedex = pokeArr
            NSOperationQueue.mainQueue().addOperationWithBlock({ 
                self.delegate?.RequestManagerPokemonListRecieved(pokeArr)
            })
        }) { (error:NSError?) in
            print(error?.code, error?.domain)
            self.throwError(error, withMessage: "We weren't able to load the Pokemon list")
        }
    }
    
//    /**
//     Send a GET request to get the array of all pokemon
//     */
//    func getPokemonListThenPerformAction(action: () -> Void) {
//        let url = BASE_URL + "/AllPokemon/Enabled"
//        
//        self.sendRequestWithOptions(.GET, withURL: url, withBodyData: nil, onSuccess: { (json) in
//            let pokeArr = Pokemon.arrayFromJsonData(json)
//            Pokemon.Pokedex = pokeArr
//            action()
//            NSOperationQueue.mainQueue().addOperationWithBlock({
//                self.delegate?.RequestManagerPokemonListRecieved(pokeArr)
//            })
//        }) { (error:NSError?) in
//            self.throwError(error, withMessage: "We weren't able to load the Pokemon list")
//        }
//    }
    
   
    
    /**
     Send a POST request to the database submitting catch data
     
     - parameter pokemon:     the caught pokemon
     - parameter coordinates: the user's current location
     */
    func submitACatch(pokemon: Pokemon, coordinates: CLLocationCoordinate2D) {
        if (uuid == nil) {
            self.delegate?.RequestManagerError(nil, withMessage: "Where's the UUID?")
            return
        }
        
        let concatStringUrl = BASE_URL + "/CaughtPokemon/\(uuid!)/\(pokemon.id)/\(coordinates.latitude)/\(coordinates.longitude)"
        
        self.sendRequestWithOptions(.POST, withURL: concatStringUrl, withBodyData: nil, onSuccess: { (json) in
            NSOperationQueue.mainQueue().addOperationWithBlock({
                self.delegate?.RequestManagerCatchSubmitted()
            })
        }) { (error:NSError?) in
                self.throwError(error, withMessage: "An error occured submitting your catch. Try again")
        }
        
    }
    
    /**
     Get location data for the selected pokemon
     
     - parameter pokemon: the query pokemon
     */
    func pokemonPinsLookup(pokemon: Pokemon?) {
        //GET
        var url = BASE_URL + "/CaughtPokemon"
        if (pokemon != nil){
            url = BASE_URL + "/CaughtPokemon/\(pokemon!.id)"
        }
        
        self.sendRequestWithOptions(.GET, withURL: url, withBodyData: nil, onSuccess: { (json) in
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
        }) { (error:NSError?) in
            if (pokemon != nil){
                self.throwError(error, withMessage: "Uh-oh, something went wrong trying to find \(pokemon!.name)")
                
            } else {
                self.throwError(error, withMessage: "Uh-oh, something went wrong")
                
            }
        }
        
    }
    
    /**
     send Anonymous Feedback
     
     - parameter feedback:  the feedback text
     - parameter onSuccess: function to run on success
     - parameter onError:   function to run on error
     */
    func sendFeedback(feedback: String, onSuccess: ((Array<Dictionary<String, AnyObject>>) -> Void)?, onError: ((NSError?, String?) -> Void)?) {
        
        let stringUrl = BASE_URL + "/Feedback"
        
        let bodyJson = [
            "feedback": feedback
        ]
        
        self.sendRequestWithOptions(.POST, withURL: stringUrl, withBodyData: bodyJson, onSuccess: onSuccess) { (err:NSError?) in
            onError?(err, "Looks lke your feedback got lost in transit. Try submitting your feedback again later, we'd really like to hear it!")
        }
        
    }
    
    /**
     Generic method to make a request
     
     - author: io.godex
     - date: 16-07-18 09:07
     
     - parameter requestType: the request type
     - parameter url:         the URL
     - parameter success:     function to run on success
     - parameter onError:     function to run on failure
     */
    private func sendRequestWithOptions(requestType: RequestType, withURL url: String,withBodyData body: [String: AnyObject]?, onSuccess success: ((Array<Dictionary<String, AnyObject>>) -> Void)?, onError: ((NSError?) -> Void)?) {
        
        let nsurl = NSURL(string: url)!
        let request = NSMutableURLRequest(URL: nsurl)
        request.HTTPMethod = RequestType.ToString()
        //if body data to send, add it
        if body != nil {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            do {
                let jsonData = try NSJSONSerialization.dataWithJSONObject(body!, options: .PrettyPrinted)
                request.HTTPBody = jsonData
            } catch {
                onError?(nil)
                return
            }
        }
        
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
                    // Custom error handler
                    if json[0]["error"] != nil {
                        self.throwError(nil, withMessage: json[0]["error"] as? String)
                        self.requestComplete()
                        return
                    } else {
                        success?(json)
                    }
                } else {
                    self.throwError(nil, withMessage: "Empty data")
                }
            } else {
                onError?(error)
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
            self.throwError(nil, withMessage: "Darn server, we've got some bad data here")
        }
        return json
    }
    
}