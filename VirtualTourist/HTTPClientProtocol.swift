//
//  HTTPClientProtocol.swift
//  VirtualTourist
//
//  Created by Yetkin Timocin on 05/12/15.
//  Copyright © 2015 BaseTech. All rights reserved.
//

import Foundation

public protocol HTTPClientProtocol {
    
    func getBaseURLSecure() -> String
    func addRequestHeaders(request:NSMutableURLRequest)
    func processJsonBody(jsonBody:[String:AnyObject]) -> [String:AnyObject]
    func processResponse(data:NSData) -> NSData
}
