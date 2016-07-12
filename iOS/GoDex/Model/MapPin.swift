//
//  MapPin.swift
//  GoDex
//
//  Created by Brandon Groff on 7/12/16.
//  Copyright © 2016 io.godex. All rights reserved.
//

import Foundation
import MapKit

/// Implementation of MKAnnotation
class MapPin: NSObject, MKAnnotation {
    
    var coordinate: CLLocationCoordinate2D
    var title: String?
    var subtitle: String?
    
    init(coordinate: CLLocationCoordinate2D, title: String?, subtitle: String?) {
        self.coordinate = coordinate
        self.title = title
        self.subtitle = subtitle
    }
    
    func annotationView() -> MKAnnotationView {
        let view = MKAnnotationView(annotation: self, reuseIdentifier: "MapPin")
        view.translatesAutoresizingMaskIntoConstraints = false
        view.enabled = true
        view.canShowCallout = true
        view.image = UIImage(named: "location-4")
        view.rightCalloutAccessoryView = UIButton(type: UIButtonType.Custom)
        view.centerOffset = CGPointMake(0, -32)
        return view
    }
    
}