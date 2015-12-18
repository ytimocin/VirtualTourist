//
//  Pin.swift
//  VirtualTourist
//
//  Created by Yetkin Timocin on 05/12/15.
//  Copyright © 2015 BaseTech. All rights reserved.
//

import Foundation
import CoreData

@objc(Pin)

public class Pin : NSManagedObject {
    
    @NSManaged var latitude:NSNumber
    @NSManaged var longitude:NSNumber
    @NSManaged var photos:[Photo]
    @NSManaged public var details:PinDetail?
    
    override public var description:String {
        get {
            return "latitude:\(self.latitude)::longitude:\(self.longitude)"
        }
    }
    
    override public var hashValue : Int {
        get {
            return self.description.hashValue
        }
    }
    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    convenience init(latitude:NSNumber, longitude:NSNumber, context:NSManagedObjectContext) {
        self.init(context: context)
        
        self.latitude = latitude
        self.longitude = longitude
    }
    
    func isDownloading() -> Bool {
        print("isDownloading in Pin")
        
        var result = false
        
        for next in self.photos {
            if let downloadWorker = PhotoQueue.sharedInstance().downloadsInProgress[next.description.hashValue] as? PhotoDownloadWorker {
                print("Pin.swift")
                if downloadWorker.isDownloading() {
                    result = true
                    break
                }
            }
        }
        
        return result
    }
    
}