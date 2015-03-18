//
//  Model.swift
//  Data
//
//  Created by Daniel Brooker on 16/03/15.
//  Copyright (c) 2015 Nocturnal Code. All rights reserved.
//

import Foundation

public protocol Model : NSCoding, Equatable {
    var uid : String { get }
}

//protocol ModelRelationships {
//
//}

//func ==<T: Model>(lhs: T, rhs: T) -> Bool {
//    return lhs.uid == rhs.uid
//}