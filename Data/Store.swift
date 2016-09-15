//
//  DataBacked.swift
//  Take Note
//
//  Created by Daniel Brooker on 6/10/14.
//  Copyright (c) 2014 Nocturnal Code. All rights reserved.
//

import Foundation

public protocol Store {
    
    // READ
    func all<T : Model>() -> [T]
    func find<T : Model>(_ id: String) -> T?
    func filter<T: Model>(_ filter: (_ element: T) -> (Bool) ) -> [T]
    func count<T: Model>(_ klass: T.Type) -> Int
    func query<T : Model>(_ query: Query<T>) -> [T]

    // WRITE
    func add<T : Model>(_ element: T)
    func remove<T : Model>(_ element: T)
    func update<T : Model>(_ element: T)
    func truncate<T: Model>(_ klass: T.Type)

    // INDEXES
    func index<T: Model>(_ model : T)
    func find<T: Model>(_ key: String, value: Indexable) -> T?
    func filter<T: Model>(_ key: String, value: Indexable) -> [T]
    
    // SEARCH
    func search<T: Model>(string: String) -> [T]
    func search<T: Model>(phrase: String) -> [T]
}
