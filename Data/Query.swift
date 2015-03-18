//
//  Query.swift
//  Data
//
//  Created by Daniel Brooker on 18/03/15.
//  Copyright (c) 2015 Nocturnal Code. All rights reserved.
//

public struct Query<T> {
    let filter: ( (a: T) -> Bool )?
    let limit: Int?

    public init(limit: Int? = nil, filter: ( (a: T) -> Bool )? = nil) {
        self.filter = filter
        self.limit = limit
    }
    
    func apply(var array: [T]) -> [T] {
        if let filter = filter {
            array = array.filter(filter)
        }
        if let limit = limit {
            array = Array(array[0..<limit])
        }
        return array
    }
}