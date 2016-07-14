//
//  ColorPalette.swift
//  GoDex
//
//  Created by Brandon Groff on 7/11/16.
//  Copyright © 2016 io.godex. All rights reserved.
//

import UIKit

struct ColorPalette {
    
    static let BackgroundBlue: UIColor = UIColor(hex: "#AAE0EB")
    
    static let BackgroundGreenish: UIColor = UIColor(hex: "#D8EEE2")
    
    static let LabelBorderGray: UIColor = UIColor(hex: "#BABABA")
    
    static let SubmitBackground: UIColor = UIColor(hex: "#349b93")
    
    static let DropdownTextColor: UIColor = UIColor(hex: "#7c7a7c")
    
    static let DropdownBackground: UIColor = UIColor.whiteColor().colorWithAlphaComponent(0.7)
    
    static let TabBarTextSelectedColor: UIColor = UIColor(hex: "#474747")
    
    static func CreateGradient(viewFrame: CGRect, fromColor from: UIColor, toColor to: UIColor) -> CAGradientLayer {
        let gradient: CAGradientLayer = CAGradientLayer()
        gradient.frame = viewFrame
        gradient.colors = [from.CGColor , to.CGColor]
        return gradient
    }
    
    
}