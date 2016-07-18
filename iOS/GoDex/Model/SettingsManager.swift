//
//  SettingsManager.swift
//  GoDex
//
//  Created by Brandon Groff on 7/14/16.
//  Copyright © 2016 io.godex. All rights reserved.
//

import Foundation

/// Manage stored app settings
class SettingsManager {
    
    private struct Defaults {
        static let FIRST_SUBMIT: String = "FIRST_SUBMIT"
    }
    
    /**
     Saves setting for the first submission made
     (sets to true)
     
     - author: io.godex
     - date: 16-07-18 09:07
     */
    class func FirstSubmissionMade() {
        let defaults = NSUserDefaults.standardUserDefaults()
        defaults.setBool(true, forKey: Defaults.FIRST_SUBMIT)
    }
    
    /**
     Returns Bool, checks savd settings to see if a
     submission has ever been made
     
     - author: io.godex
     - date: 16-07-18 09:07
     
     - returns: <#return value description#>
     */
    class func HasFirstSubmitBeenMade() -> Bool {
        let defaults = NSUserDefaults.standardUserDefaults()
        return defaults.boolForKey(Defaults.FIRST_SUBMIT)
    }
    
}