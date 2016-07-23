//
//  MapPin.swift
//  GoDex
//
//  Created by Brandon Groff on 7/12/16.
//  Copyright © 2016 io.godex. All rights reserved.
//

import Foundation
import MapKit

/// Implementation of MKPointAnnotation
class PokePin: MKPointAnnotation {
    
    /// The Pokemon this pin represents
    var pokemon: Pokemon? = nil
    
    convenience init(pokemon: Pokemon) {
        self.init()
        self.pokemon = pokemon
    }
    
}