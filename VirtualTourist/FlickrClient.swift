//
//  FlickrClient.swift
//  VirtualTourist
//
//  Created by Yetkin Timocin on 05/12/15.
//  Copyright © 2015 BaseTech. All rights reserved.
//

import Foundation
import CoreData

let FLICKR_API_KEY = "ab8d7d9d5729d02cbfc694d369c8a7a5"

public class FlickrClient: NSObject, HTTPClientProtocol {
    
    var httpClient:HTTPClient?
    
    override init() {
        super.init()
        self.httpClient = HTTPClient(delegate: self)
    }
    
    public func getBaseURLSecure() -> String {
        return FlickrClient.Constants.BASE_URL
    }
    
    public func addRequestHeaders(request: NSMutableURLRequest) {
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
    }
    
    public func processJsonBody(jsonBody: [String : AnyObject]) -> [String : AnyObject] {
        return jsonBody
    }
    
    public func processResponse(data: NSData) -> NSData {
        return data
    }
    
    lazy var sharedModelContext:NSManagedObjectContext = {
        return CoreDataStackManager.sharedInstance().dataStack.childManagedObjectContext(NSManagedObjectContextConcurrencyType.MainQueueConcurrencyType)//(NSManagedObjectContextConcurrencyType.PrivateQueueConcurrencyType)
    }()
    
    // MARK: - Shared Instance
    
    public class func sharedInstance() -> FlickrClient {
        
        struct Singleton {
            static var sharedInstance = FlickrClient()
        }
        
        return Singleton.sharedInstance
    }
}

extension FlickrClient {
    
    struct Constants {
        static let BASE_URL = "https://api.flickr.com/services/rest/"
        static let EXTRAS = "url_m"
        static let SAFE_SEARCH = "1"
        static let DATA_FORMAT = "json"
        static let NO_JSON_CALLBACK = "1"
        static let BOUNDING_BOX_HALF_WIDTH = 1.0
        static let BOUNDING_BOX_HALF_HEIGHT = 1.0
        static let LAT_MIN = -90.0
        static let LAT_MAX = 90.0
        static let LON_MIN = -180.0
        static let LON_MAX = 180.0
    }
    
    struct ParameterKeys {
        static let METHOD = "method"
        static let API_KEY = "api_key"
        static let BBOX = "bbox"
        static let SAFE_SEARCH = "safe_search"
        static let EXTRAS = "extras"
        static let FORMAT = "format"
        static let NO_JSON_CALLBACK = "nojsoncallback"
    }
    
    struct Methods {
        static let SEARCH = "flickr.photos.search"
        
    }
}
