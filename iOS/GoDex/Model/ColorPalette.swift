//
//  ColorPalette.swift
//  GoDex
//
//  Created by Brandon Groff on 7/11/16.
//  Copyright © 2016 io.godex. All rights reserved.
//

import UIKit

/**
 *  Application Color Palette
 */
struct ColorPalette {
    
    static let BackgroundBlue: UIColor = UIColor(hex: "#AAE0EB")
    
    static let BackgroundGreenish: UIColor = UIColor(hex: "#D8EEE2")
    
    static let LabelBorderGray: UIColor = UIColor(hex: "#BABABA")
    
    static let SubmitBackground: UIColor = UIColor(hex: "#349b93")
    
    static let DropdownTextColor: UIColor = UIColor(hex: "#7c7a7c")
    
    static let GoDexYellow: UIColor = UIColor(hex: "#ffd200")
    
    static let DropdownBackground: UIColor = UIColor.whiteColor().colorWithAlphaComponent(0.7)
    
    static let TabBarTextSelectedColor: UIColor = UIColor(hex: "#474747")
    
    static let BackgroundGradientDarkGray: UIColor = UIColor(hex: "#43474A")
    
    static let BackgroundGradientGray: UIColor = UIColor(hex: "#8C9191")
    
    /**
     Create a top to bottom gradient between 2 colors
     
     - parameter viewFrame: the frame the gradient will appear in
     - parameter from:      the top color
     - parameter to:        the bottom color
     
     - returns: the generated Gradient Layer
     */
    static func CreateGradient(viewFrame: CGRect, fromColor from: UIColor, toColor to: UIColor) -> CAGradientLayer {
        let gradient: CAGradientLayer = CAGradientLayer()
        gradient.frame = viewFrame
        gradient.colors = [from.CGColor , to.CGColor]
        return gradient
    }
    
    
}