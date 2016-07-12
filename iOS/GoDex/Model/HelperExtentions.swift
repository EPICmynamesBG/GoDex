//
//  HelperExtentions.swift
//  GoDex
//
//  Created by Brandon Groff on 7/11/16.
//  Copyright © 2016 io.godex. All rights reserved.
//

import Foundation
import UIKit

public extension UIColor {
    
    /**
     Create a color using CSS RGBA (values 0 - 255)
     
     - parameter red:   0 - 255
     - parameter green: 0 - 255
     - parameter blue:  0 - 255
     - parameter alpha: 0.0 - 1.0
     
     - returns: UIColor
     */
//    convenience init(red: Int, green: Int, blue: Int, alpha: Double) {
//        self.init(red: CGFloat(Double(red) / 255.0),
//                  green: CGFloat(Double(green) / 255.0),
//                  blue: CGFloat(Double(blue) / 255.0),
//                  alpha: CGFloat(alpha))
//    }
    
    /**
     Create a color using CSS HEX code
     
     - parameter hex: 3 or 6 char color hex code
     
     - returns: UIColor, Black if error
     */
    convenience init(hex: String) { // "001122" OR "#FFddFF"
        var cString:String = hex.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet() as NSCharacterSet).uppercaseString
        
        if (cString.hasPrefix("#")) {
            cString = cString.substringFromIndex(cString.startIndex.advancedBy(1))
        }
        
        if ((cString.characters.count) != 6) {
            self.init(red: 0,
                      green: 0,
                      blue: 0,
                      alpha: 1.0)
            return
        }
        
        var rgbValue:UInt32 = 0
        NSScanner(string: cString).scanHexInt(&rgbValue)
        
        self.init(
            red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
            alpha: CGFloat(1.0)
        )
    }
    
}

// MARK: - Add border configuration and corder radius configuration to all views
public extension UIView {
    
    /// a view's corner radius, for rounding corners
    @IBInspectable var cornerRadius: CGFloat {
        get {
            return layer.cornerRadius
        }
        set {
            layer.cornerRadius = newValue
            layer.masksToBounds = newValue > 0
        }
    }
    
    /// a view's border width, if any
    @IBInspectable var borderWidth: CGFloat {
        get {
            return layer.borderWidth
        }
        set {
            layer.borderWidth = newValue
        }
    }
    
    /// a view's border color, if any
    @IBInspectable var borderColor: UIColor? {
        get {
            return UIColor(CGColor: layer.borderColor!)
        }
        set {
            layer.borderColor = newValue?.CGColor
        }
    }
    
}
