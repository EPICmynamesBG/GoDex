//
//  SettingsManager.swift
//  GoDex
//
//  Created by Brandon Groff on 7/14/16.
//  Copyright © 2016 io.godex. All rights reserved.
//

import Foundation

class SettingsManager {
    
    private struct Defaults {
        static let FIRST_SUBMIT: String = "FIRST_SUBMIT"
    }
    
    class func FirstSubmissionMade() {
        let defaults = NSUserDefaults.standardUserDefaults()
        defaults.setBool(true, forKey: Defaults.FIRST_SUBMIT)
    }
    
    class func HasFirstSubmitBeenMade() -> Bool {
        let defaults = NSUserDefaults.standardUserDefaults()
        return defaults.boolForKey(Defaults.FIRST_SUBMIT)
    }
    
}