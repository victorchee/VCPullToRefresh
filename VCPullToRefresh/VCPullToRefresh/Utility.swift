//
//  Utility.swift
//  VCPullToRefresh
//
//  Created by Victor Chee on 15/9/8.
//  Copyright (c) 2015年 VictorChee. All rights reserved.
//

import Foundation

public func delay(delay: Double , closure:() -> Void) {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(delay * Double(NSEC_PER_SEC))), dispatch_get_main_queue(), closure)
}