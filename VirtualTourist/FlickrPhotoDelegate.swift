//
//  FlickrPhotoDelegate.swift
//  VirtualTourist
//
//  Created by Yetkin Timocin on 05/12/15.
//  Copyright © 2015 BaseTech. All rights reserved.
//

import Foundation
import CoreData

public class FlickrPhotoDelegate: FlickrDelegate {
    
    class func sharedInstance() -> FlickrPhotoDelegate {
        struct Static {
            static let instance = FlickrPhotoDelegate()
        }
        return Static.instance
    }
    
    var pinsBeingProcessed:Set<Pin> = Set()
    var delegates:[Pin:FlickrDelegate] = [Pin:FlickrDelegate]()
    
    public func didFinishSearchingPinPhotos(success: Bool, pin: Pin, photos: [Photo]?, errorString: String?, context: NSManagedObjectContext) {
        self.pinsBeingProcessed.remove(pin)
        if let delegate = delegates[pin] {
            delegate.didFinishSearchingPinPhotos(success, pin: pin, photos: photos, errorString: errorString, context: context)
        }
        self.delegates.removeValueForKey(pin)
    }
    
    public func getPhotosOfThisPin(pin: Pin) {
        self.pinsBeingProcessed.insert(pin)
        FlickrClient.sharedInstance().getPhotosFromFlickrSearch(pin, delegate: self)
    }
    
    public func isInProgress(pin: Pin) -> Bool {
        return self.pinsBeingProcessed.contains(pin)
    }
    
    public func addDelegate(pin: Pin, delegate: FlickrDelegate) {
        delegates[pin] = delegate
    }
}
