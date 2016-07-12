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
    
    static func CreateGradient(viewFrame: CGRect, fromColor from: UIColor, toColor to: UIColor) -> CAGradientLayer {
        let gradient: CAGradientLayer = CAGradientLayer()
        gradient.frame = viewFrame
        gradient.colors = [from.CGColor , to.CGColor]
        return gradient
    }
    
    
}