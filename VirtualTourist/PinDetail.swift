//
//  PinDetail.swift
//  VirtualTourist
//
//  Created by Yetkin Timocin on 05/12/15.
//  Copyright © 2015 BaseTech. All rights reserved.
//

import Foundation
import CoreData
import MapKit

@objc(PinDetail)

public class PinDetail: NSManagedObject {
    
    @NSManaged var locality: String
    @NSManaged var pin: Pin
    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    convenience init(pin: Pin, locality: String, context: NSManagedObjectContext) {
        self.init(context: context)
        
        self.locality = locality
        self.pin = pin
    }
}
