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
    func find<T : Model>(id: String) -> T?
    func filter<T: Model>(filter: (element: T) -> (Bool) ) -> [T]
    func count<T: Model>(klass: T.Type) -> Int
    func query<T : Model>(query: Query<T>) -> [T]
    
    // WRITE
    func add<T : Model>(element: T)
    func remove<T : Model>(element: T)
    func update<T : Model>(element: T)
    func truncate<T: Model>(klass: T.Type)
    
    // INDEXES
    func index<T: Model>(model : T, block: ((object: T) -> [Index]))
    func find<T: Model>(key: String, value: Indexable) -> T?
    func filter<T: Model>(key: String, value: Indexable) -> [T]
    
    // SEARCH
    func search<T: Model>(#string: String) -> [T]
    func search<T: Model>(#phrase: String) -> [T]
}