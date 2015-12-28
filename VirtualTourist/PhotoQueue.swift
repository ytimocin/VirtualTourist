//
//  PhotoQueue.swift
//  VirtualTourist
//
//  Created by Yetkin Timocin on 05/12/15.
//  Copyright © 2015 BaseTech. All rights reserved.
//

import Foundation
import CoreData

class PhotoQueue: NSObject {
    
    class func sharedInstance() -> PhotoQueue {
        struct Static {
            static let instance = PhotoQueue()
        }
        return Static.instance
    }
    
    var downloadsInProgress:[Int:AnyObject] = [Int:AnyObject]()
    var downloadQueue:NSOperationQueue
    var downloadWorkers:Set<PhotoDownloadWorker> = Set()
    
    override init() {
        downloadQueue = NSOperationQueue()
        downloadQueue.name = "Download Queue"
        downloadQueue.maxConcurrentOperationCount = 6
        super.init()
    }
    
    
}
