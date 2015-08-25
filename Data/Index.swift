//
//  Index.swift
//  Data
//
//  Created by Daniel Brooker on 17/05/15.
//  Copyright (c) 2015 Nocturnal Code. All rights reserved.
//

public protocol Indexable {
}

/// Data.Index
public struct Index {
    let key: String
    let value: Indexable
    
    public init(key: String, value: Indexable) {
        self.key = key
        self.value = value
    }
}

public class Indexed {
    let value: Indexable
    
    public init(_ value: Indexable) {
        self.value = value
    }
}

extension Int : Indexable {
}

extension Float : Indexable {
}

extension Double : Indexable {
}

extension String : Indexable {
}

extension Bool : Indexable {
}