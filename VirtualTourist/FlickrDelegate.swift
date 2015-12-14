//
//  FlickrDelegate.swift
//  VirtualTourist
//
//  Created by Yetkin Timocin on 05/12/15.
//  Copyright © 2015 BaseTech. All rights reserved.
//

import Foundation
import CoreData

public protocol FlickrDelegate {
    
    func didFinishSearchingPinPhotos(success: Bool, pin: Pin, photos: [Photo]?, errorString: String?, context: NSManagedObjectContext)
}