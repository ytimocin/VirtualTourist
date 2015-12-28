//
//  Photo.swift
//  VirtualTourist
//
//  Created by Yetkin Timocin on 05/12/15.
//  Copyright © 2015 BaseTech. All rights reserved.
//

import Foundation
import UIKit
import CoreData

@objc(Photo)

public class Photo : NSManagedObject {
    
    @NSManaged public var imagePath: String
    @NSManaged public var flickrURL: NSURL
    @NSManaged public var pin: Pin?
    
    override public var description:String {
        get {
            return self.flickrURL.path!
        }
    }
    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    init(pin:Pin, imageURL:NSURL, context:NSManagedObjectContext) {
        let name = self.dynamicType.entityName()
        let entity = NSEntityDescription.entityForName(name, inManagedObjectContext: context)!
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        self.flickrURL = imageURL
        self.imagePath = self.flickrURL.lastPathComponent!
        self.pin = pin
        if self.image == nil {
            _ = PhotoDownloadWorker(photo: self)
        }
    }
    
    public override func prepareForDeletion() {
        self.image = nil
    }
    
    var image:UIImage? {
        get {
            return ImageCache.sharedInstance().imageWithIdentifier("\(self.imagePath)")
        }
        
        set {
            dispatch_async(dispatch_get_main_queue()) {
                ImageCache.sharedInstance().storeImage(newValue, withIdentifier: "\(self.imagePath)")
            }
        }
    }
    
    func deleteObject(photo: Photo) {
        photo.deleteObject(photo)
    }
}

public func ==(lhs:Photo, rhs:Photo) -> Bool {
    return lhs.flickrURL.isEqual(rhs)
}

extension NSManagedObject {
    
    class func entityName() -> String {
        let fullClassName = NSStringFromClass(object_getClass(self))
        let nameComponents = fullClassName.characters.split{ $0 == "."}.map { String($0) }
        return nameComponents.last!
    }
    
    convenience init(context:NSManagedObjectContext) {
        let name = self.dynamicType.entityName()
        let entity = NSEntityDescription.entityForName(name, inManagedObjectContext: context)!
        self.init(entity: entity, insertIntoManagedObjectContext: context)
    }
}
