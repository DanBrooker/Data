//
//  Query.swift
//  Data
//
//  Created by Daniel Brooker on 18/03/15.
//  Copyright (c) 2015 Nocturnal Code. All rights reserved.
//

/// A basic query structure
public struct Query<T : Model> {
    
    /// Where condition
    let filter: ( (_ element: T) -> Bool )?
    
    /// Limit number of results and initial offset
    let window: CountableRange<Int>?
    
    /// Sort order
    let order: ( (_ a: T, _ b: T) -> Bool )?

    /**
        Initializes a new Query for a Type
    
        - parameter filter: Only include data that pass the filter i.e { $0.enabled == true }
        - parameter window: Range of data required i.e 1...5 -> location 1, length 5
        - parameter order: Set the sorting function i.e { $0.createdAt > $1.createdAt }
    
        - returns: A query object.
     */
    public init(filter: ( (_ a: T) -> Bool )? = nil, window: CountableRange<Int>? = nil, order: ( (_ a: T, _ b: T) -> Bool )? = nil) {
        self.filter = filter
        self.window = window
        self.order = order
    }
    
    func apply( _ array: [T]) -> [T] {
        var array = array
        if let filter = filter {
            array = array.filter(filter)
        }
        
        if let order = order {
            array.sort(by: order)
        }
        
        if let window = window {
            if window.upperBound > array.count {
                array = Array(array[window.lowerBound..<array.count])
            } else {
                array = Array(array[window])
            }
        }

        return array
    }
}
