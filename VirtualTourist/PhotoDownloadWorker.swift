//
//  PhotoDownloadWorker.swift
//  VirtualTourist
//
//  Created by Yetkin Timocin on 05/12/15.
//  Copyright © 2015 BaseTech. All rights reserved.
//

import Foundation
import UIKit
import QuartzCore
import CoreData

public class PhotoDownloadWorker:NSOperation, NSURLSessionDataDelegate {
    
    var imageLoadDelegate:[ImageLoadDelegate] = [ImageLoadDelegate]()
    private var imageData:NSMutableData?
    private var totalBytes:Int = 0
    private var receivedBytes:Int = 0
    var photo:Photo
    var session:NSURLSession!
    var sharedContext:NSManagedObjectContext!
    
    public override var hashValue: Int {
        get {
            print("PhotoDownloadWorker hashValue called")
            return self.photo.flickrURL.path!.hashValue
        }
    }
    
    init(photo:Photo) {
        print("init 1")
        self.photo = photo
        super.init()
        let configuration = NSURLSessionConfiguration.defaultSessionConfiguration()
        print("1")
        session = NSURLSession(configuration: configuration, delegate: self, delegateQueue: PhotoQueue.sharedInstance().downloadQueue)
        print("2")
        PhotoQueue.sharedInstance().downloadsInProgress[self.photo.description.hashValue] = self
        print("3")
        objc_sync_enter(PhotoQueue.sharedInstance().downloadWorkers)
        print("4")
        PhotoQueue.sharedInstance().downloadWorkers.insert(self)
        print("5")
        objc_sync_exit(PhotoQueue.sharedInstance().downloadWorkers)
        print("6")
        if PhotoQueue.sharedInstance().downloadWorkers.count <= PhotoQueue.sharedInstance().downloadQueue.maxConcurrentOperationCount {
            print("7")
            PhotoQueue.sharedInstance().downloadQueue.addOperation(self)
        }
        print("init 2")
    }
    
    public override func main() {
        print("main called")
        self.download()
    }
    
    public func isDownloading() -> Bool {
        print("isDownloading")
        return PhotoQueue.sharedInstance().downloadsInProgress.indexForKey(self.photo.description.hashValue) != nil
    }
    
    func fireProgressDelegate(progress:CGFloat) {
        for next in imageLoadDelegate {
            dispatch_async(dispatch_get_main_queue()) {
                next.progress(progress)
            }
        }
    }
    
    func fireLoadFinish() {
        
        objc_sync_enter( PhotoQueue.sharedInstance().downloadWorkers)
        PhotoQueue.sharedInstance().downloadWorkers.remove(self)
        let pendingWorkers = PhotoQueue.sharedInstance().downloadWorkers.filter { !$0.finished && !$0.executing}
        if let worker = pendingWorkers.first {
            PhotoQueue.sharedInstance().downloadWorkers.insert(worker)
            PhotoQueue.sharedInstance().downloadQueue.addOperation(worker)
        }
        objc_sync_exit( PhotoQueue.sharedInstance().downloadWorkers)
        
        for next in imageLoadDelegate {
            dispatch_async(dispatch_get_main_queue()) {
                next.didFinishLoad()
            }
        }
    }
    
    override public func cancel() {
        super.cancel()
        self.imageLoadDelegate.removeAll(keepCapacity: false)
        self.totalBytes = 0
        self.receivedBytes = 0
        self.imageData = nil
        self.session = nil
        print("cancel")
        PhotoQueue
            .sharedInstance().downloadsInProgress.removeValueForKey(self.photo.description.hashValue)
    }
    
    private func download() {
        dispatch_async(dispatch_get_main_queue()) {
            let request = NSURLRequest(URL: self.photo.flickrURL)
            let dataTask = self.session.dataTaskWithRequest(request)
            
            dataTask.resume()
        }
    }
    
    public func URLSession(session: NSURLSession, dataTask: NSURLSessionDataTask, didReceiveResponse response: NSURLResponse, completionHandler: (NSURLSessionResponseDisposition) -> Void) {
        if self.cancelled {
            return;
        }
        
        self.receivedBytes = 0
        self.totalBytes = Int(response.expectedContentLength);
        self.imageData = NSMutableData(capacity: self.totalBytes)
        completionHandler(NSURLSessionResponseDisposition.Allow)
    }
    
    public func URLSession(session: NSURLSession, dataTask: NSURLSessionDataTask, didReceiveData data: NSData) {
        if self.cancelled {
            return;
        }
        
        self.imageData?.appendData(data)
        self.receivedBytes += data.length
        
        let progress = CGFloat((Float(self.receivedBytes) / Float(self.totalBytes)))
        self.fireProgressDelegate(progress)
    }
    
    public func URLSession(session: NSURLSession, task: NSURLSessionTask, didCompleteWithError error: NSError?) {
        print("URLSession")
        
        dispatch_async(dispatch_get_main_queue()) {
            PhotoQueue.sharedInstance().downloadsInProgress.removeValueForKey(self.photo.description.hashValue)
            if let error = error {
                print("Error downloading photo \(error)")
            }
            if let imageData = self.imageData {
                let image = UIImage(data: imageData)
                self.photo.image = image
            }
            self.fireLoadFinish()
            self.imageLoadDelegate.removeAll(keepCapacity: false)
            self.totalBytes = 0
            self.receivedBytes = 0
            self.imageData = nil
            self.session = nil
        }
    }
}

public func ==(lhs:PhotoDownloadWorker, rhs:PhotoDownloadWorker) -> Bool {
    print("lhs...swift")
    return lhs.photo.flickrURL.path! == rhs.photo.flickrURL.path!
}
