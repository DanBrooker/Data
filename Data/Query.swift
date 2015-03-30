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
    let filter: ( (element: T) -> Bool )?
    
    /// Limit number of results and initial offset
    let window: Range<Int>?
    
    /// Sort order
    let order: ( (a: T, b: T) -> Bool )?

    /**
        Initializes a new bicycle with the provided parts and specifications.
    
        :param: filter Only include data that pass the filter i.e { $0.enabled == true }
        :param: window Range of data required i.e 1...5 -> location 1, length 5
        :param: order Set the sorting function i.e { $0.createdAt > $1.createdAt }
    
        :returns: A query object.
     */
    public init(filter: ( (a: T) -> Bool )? = nil, window: Range<Int>? = nil, order: ( (a: T, b: T) -> Bool )? = nil) {
        self.filter = filter
        self.window = window
        self.order = order
    }
    
    func apply(var array: [T]) -> [T] {
        if let filter = filter {
            array = array.filter(filter)
        }
        
        if let order = order {
            array.sort(order)
        }
        
        if let window = window {
            if window.endIndex > array.count {
                array = Array(array[window.startIndex..<array.count])
            } else {
                array = Array(array[window])
            }
        }

        return array
    }
}
