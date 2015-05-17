//
//  Model.swift
//  Data
//
//  Created by Daniel Brooker on 16/03/15.
//  Copyright (c) 2015 Nocturnal Code. All rights reserved.
//

/// Data.Model
public protocol Model : NSCoding, Equatable {
    /// Unique identifier
    var uid : String { get }
}
