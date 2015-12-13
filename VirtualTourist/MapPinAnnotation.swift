//
//  MapPinAnnotation.swift
//  VirtualTourist
//
//  Created by Yetkin Timocin on 05/12/15.
//  Copyright © 2015 BaseTech. All rights reserved.
//

import Foundation
import MapKit

public class MapPinAnnotation: NSObject, MKAnnotation {
    
    public var title: String?
    public var subtitle: String?
    public var coordinate: CLLocationCoordinate2D
    var pin: Pin?
    
    init(latitude: Double, longitude:Double) {
        self.coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        super.init()
    }
}
