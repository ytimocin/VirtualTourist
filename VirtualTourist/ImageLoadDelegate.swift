//
//  ImageLoadDelegate.swift
//  VirtualTourist
//
//  Created by Yetkin Timocin on 05/12/15.
//  Copyright © 2015 BaseTech. All rights reserved.
//

import Foundation
import QuartzCore

protocol ImageLoadDelegate {
    
    func progress(progress:CGFloat)
    
    func didFinishLoad()
}
