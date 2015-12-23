//
//  FlickrConvenience.swift
//  VirtualTourist
//
//  Created by Yetkin Timocin on 05/12/15.
//  Copyright © 2015 BaseTech. All rights reserved.
//

import Foundation
import CoreData

private let MAX_PHOTOS = 39

extension FlickrClient {
    
    public func getPhotosFromFlickrSearch(annotation:Pin, delegate:FlickrDelegate?) {
        print("getPhotosFromFlickrSearch")
        self.getImageFromFlickrSearch(annotation) { success, result, errorString in
            if success {
                let photos = [Photo]()
                var photoURLs:[NSURL] = [NSURL]()
                
                for photo in result! {
                    if photoURLs.count < MAX_PHOTOS {
                        let imageUrlString = photo["url_m"] as? String
                        if let imageURL = NSURL(string: imageUrlString!) {
                            photoURLs.append(imageURL)
                        }
                    } else {
                        break
                    }
                }
                
                var pin: Pin!
                
                //self.sharedModelContext.performBlockAndWait({ () -> Void in
                    //pin = self.sharedModelContext.objectWithID(annotation.objectID) as? Pin
                //})
                
                dispatch_async(dispatch_get_main_queue()) {
                    pin = self.sharedModelContext.objectWithID(annotation.objectID) as? Pin
                    
                    if pin != nil {
                        
                        //self.sharedModelContext.performBlockAndWait({ () -> Void in
                        photoURLs.map({ Photo(pin: pin, imageURL: $0, context: self.sharedModelContext)})
                        //})
                        
                        print("addPhotosFromFlickr1")
                        NSNotificationCenter.defaultCenter().addObserver(self, selector: "addPhotosFromFlickr:", name: NSManagedObjectContextDidSaveNotification, object: self.sharedModelContext)
                        
                        
                        print("*** FlickrConvenience")
                        saveContext(self.sharedModelContext) { success in
                            dispatch_async(dispatch_get_main_queue()) {
                                delegate?.didFinishSearchingPinPhotos(true, pin: annotation, photos: photos, errorString: nil, context: self.sharedModelContext)
                            }
                        }
                    }
                }

            } else {
                delegate?.didFinishSearchingPinPhotos(false, pin: annotation, photos: nil, errorString: errorString, context: self.sharedModelContext)
            }
        }
    }
    
    
    public func addPhotosFromFlickr(notification:NSNotification) {
        
        let mainContext:NSManagedObjectContext = CoreDataManager.sharedInstance().managedObjectContext!
        
        print("addPhotosFromFlickr2")
        
        //dispatch_async(dispatch_get_main_queue()) {
            mainContext.mergeChangesFromContextDidSaveNotification(notification)
            print("*** addPhotosFromFlickr")
            CoreDataManager.sharedInstance().saveContext()
        //}
        
    }
    
    public func getImageFromFlickrSearch(annotation:Pin, completionHandler:(success:Bool, result:[[String: AnyObject]]?, errorString:String?) -> Void) {
        let parameters = [
            FlickrClient.ParameterKeys.METHOD : FlickrClient.Methods.SEARCH,
            FlickrClient.ParameterKeys.API_KEY : FLICKR_API_KEY,
            FlickrClient.ParameterKeys.BBOX : self.createBoundingBoxString(annotation),
            FlickrClient.ParameterKeys.SAFE_SEARCH : FlickrClient.Constants.SAFE_SEARCH,
            FlickrClient.ParameterKeys.EXTRAS : FlickrClient.Constants.EXTRAS,
            FlickrClient.ParameterKeys.FORMAT : FlickrClient.Constants.DATA_FORMAT,
            FlickrClient.ParameterKeys.NO_JSON_CALLBACK : FlickrClient.Constants.NO_JSON_CALLBACK
        ]
        self.httpClient?.taskForGETMethod("", parameters: parameters) { JSONResult, error in
            if let _ = error {
                completionHandler(success: false, result: nil, errorString: "Can not find photos for location")
            } else  {
                if let photosDictionary = JSONResult.valueForKey("photos") as? [String:AnyObject] {
                    
                    if let totalPages = photosDictionary["pages"] as? Int {
                        
                        /* Flickr API - will only return up the 4000 images (100 per page * 40 page max) */
                        let pageLimit = min(totalPages, 40)
                        let randomPage = Int(arc4random_uniform(UInt32(pageLimit))) + 1
                        self.getImageFromFlickrBySearchWithPage(parameters, pageNumber: randomPage, completionHandler: completionHandler)
                        
                    } else {
                        completionHandler(success:false, result:nil, errorString:"Cant find key 'pages' in result")
                    }
                } else {
                    completionHandler(success:false, result:nil, errorString:"Cant find key 'pages' in result")
                }
            }
        }
    }
    
    private func getImageFromFlickrBySearchWithPage(methodArguments: [String : AnyObject], pageNumber: Int, completionHandler:(success:Bool, result:[[String: AnyObject]]?, errorString:String?) -> Void) {
        var withPageDictionary = methodArguments
        withPageDictionary["page"] = pageNumber
        self.httpClient?.taskForGETMethod("", parameters: withPageDictionary) { JSONResult, error in
            if let _ = error {
                completionHandler(success: false, result: nil, errorString: "Can not find photos for location")
            } else {
                if let photosDictionary = JSONResult.valueForKey("photos") as? [String:AnyObject] {
                    var totalPhotosVal = 0
                    if let totalPhotos = photosDictionary["total"] as? String {
                        totalPhotosVal = (totalPhotos as NSString).integerValue
                    }
                    
                    if totalPhotosVal > 0 {
                        if let photosArray = photosDictionary["photo"] as? [[String: AnyObject]] {
                            if photosArray.count > 0 {
                                completionHandler(success: true, result: photosArray, errorString: nil)
                            } else {
                                completionHandler(success: false, result: nil, errorString: "Images does not exist for this location")
                            }
                        } else {
                            completionHandler(success: false, result: nil, errorString: "Cant find key 'photo' in response")
                        }
                    } else {
                        completionHandler(success: false, result: nil, errorString: "No Photos Found")
                    }
                } else {
                    completionHandler(success: false, result: nil, errorString: "Cant find key 'photo' in response")
                }
            }
            
        }
    }
    
    private func createBoundingBoxString(annotation:Pin) -> String {
        
        let latitude = annotation.latitude as Double
        let longitude = annotation.longitude as Double
        
        /* Fix added to ensure box is bounded by minimum and maximums */
        let bottom_left_lon = max(longitude - FlickrClient.Constants.BOUNDING_BOX_HALF_WIDTH, FlickrClient.Constants.LON_MIN)
        let bottom_left_lat = max(latitude - FlickrClient.Constants.BOUNDING_BOX_HALF_HEIGHT, FlickrClient.Constants.LAT_MIN)
        let top_right_lon = min(longitude + FlickrClient.Constants.BOUNDING_BOX_HALF_HEIGHT, FlickrClient.Constants.LON_MAX)
        let top_right_lat = min(latitude + FlickrClient.Constants.BOUNDING_BOX_HALF_HEIGHT, FlickrClient.Constants.LAT_MAX)
        
        return "\(bottom_left_lon),\(bottom_left_lat),\(top_right_lon),\(top_right_lat)"
    }
}
