//
//  Query.swift
//  Data
//
//  Created by Daniel Brooker on 18/03/15.
//  Copyright (c) 2015 Nocturnal Code. All rights reserved.
//

//public enum QueryResult<T: Model> : CollectionType {
//    case Empty
//    case Some(array: [T])
//    case SomeGroups(groups: [String:[T]])
//    
//    public var startIndex: Int {
//        return data.startIndex
//    }
//    
//    public var endIndex: Int {
//        return data.endIndex
//    }
//    
//    public subscript (index: Int) -> T {
//        return data[index]
//    }
//    
//    public func generate() -> IndexingGenerator<[T]> {
//        switch(self) {
//        case .Empty:
//            return [].generate()
//        case .Some(let array):
//            return array.generate()
//        case .SomeGroups(groups: <#[String : [T]]#>)
//        }
//        return data.generate()
//    }
//}

public struct Query<T : Model> {
    let filter: ( (element: T) -> Bool )?
//    let group: ( (element: T) -> (String) )?
    let window: Range<Int>?
    let order: ( (a: T, b: T) -> Bool )?

    public init(filter: ( (a: T) -> Bool )? = nil, window: Range<Int>? = nil, order: ( (a: T, b: T) -> Bool )? = nil /*, group: ( (a: T) -> (String) )? = nil */) {
        self.filter = filter
        self.window = window
//        self.group = group
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
//        
//        if array.isEmpty {
//            return .Empty
//        } else if let group = group {
//            
//            var hash: [String: [T]] = [:]
//            for i in array {
//                let key = group(element: i)
//                var group = hash[key]
//                if group == nil {
//                    group = [T]()
//                    hash[key] = group
//                }
//                group?.append(i)
//            }
//            
//            if let order = order {
//                for (key, value) in hash {
//                   hash[key] = value.sorted(order)
//                }
//            }
//            return .SomeGroups(groups: hash)
//        } else {
//            
//        }
    }
}