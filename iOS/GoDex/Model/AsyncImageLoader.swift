//
//  AsyncImageLoader.swift
//  GoDex
//
//  Created by Brandon Groff on 7/12/16.
//  Copyright © 2016 io.godex. All rights reserved.
//

import Foundation
import UIKit

/**
 *  @author io.godex, 16-07-18 09:07
 *
 *  Simple struct for Async Image loading
 */
struct AsyncImageLoader {
    
    /**
     Static func - Async load an image from a url
     
     - author: io.godex
     - date: 16-07-18 09:07
     
     - parameter url:        the image url
     - parameter onComplete: function to run on image load success
     - parameter onError:    function to run on image load error
     */
    static func LoadImage(url: String, onComplete: (UIImage) -> Void, onError: (NSError?, String?) -> Void) {
        let nsurl = NSURL(string: url)!
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
        let datatask = NSURLSession.sharedSession().dataTaskWithURL(nsurl) { (data:NSData?, response:NSURLResponse?, error:NSError?) in
            if error == nil {
                let image = UIImage(data: data!)!
                NSOperationQueue.mainQueue().addOperationWithBlock({ 
                    onComplete(image)
                    UIApplication.sharedApplication().networkActivityIndicatorVisible = false
                })
            } else {
                NSOperationQueue.mainQueue().addOperationWithBlock({ 
                    onError(error, "We couldn't find the image. Are you online?")
                })
            }
        }
        datatask.resume()
    }
    
}