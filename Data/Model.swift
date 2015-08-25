//
//  Model.swift
//  Data
//
//  Created by Daniel Brooker on 16/03/15.
//  Copyright (c) 2015 Nocturnal Code. All rights reserved.
//

/// Data.Archive
public typealias Archive = [String: AnyObject]

/// Data.Model
public protocol Model : Equatable {
    /// Unique identifier
    var uid : String { get }
    
    init(archive: Archive)
    var archive : Archive { get }
    
    func indexes() -> [Index]
}

public extension Model {

    func indexes() -> [Index] {
        return []
    }
    
}
