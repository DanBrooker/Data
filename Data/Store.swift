//
//  DataBacked.swift
//  Take Note
//
//  Created by Daniel Brooker on 6/10/14.
//  Copyright (c) 2014 Nocturnal Code. All rights reserved.
//

import Foundation

public protocol StoreDelegate {
    func objectAdded(uid: String, klass: AnyClass)
    func objectDeleted(uid: String, klass: AnyClass)
    func objectUpdated(uid: String, klass: AnyClass)
//    
//    func didUpdate()
}

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
}
//

//

//
//enum DeleteRule {
//    case Nullify
//    case Delete
//}
//
//enum RelationshipType {
//    case HasOne
//    case BelongsTo
//    case HasMany
//    case HasFile
//}
//
//protocol ModelRelationships {
//    
//}
//
//struct Relationship {
////    let klass: AnyClass
//    
//
////    let map: (Target) -> Destination
//    let type: RelationshipType
////    let collection: AnyObject
//    let delete: DeleteRule
////
////    
////    
////    func destination<T:Model, U:Model>(target: T) -> U {
////        return self.map(T)
////    }
//    
////    init(object: @autoclosure () -> [Model] ) {
////    }
//    
////    init(type: RelationshipType , delete: DeleteRule = .Nullify ) {
////        self.type = type
//////        self.object = object
////        self.delete = delete
////    }
//    
////    static func HasOne(object: @autoclosure () -> AnyObject, delete: DeleteRule = .Nullify ) -> Relationship {
////        return Relationship(type: .HasMany, object: object, delete: delete)
////    }
////    
////    static func BelongsTo(object: @autoclosure () -> AnyObject, delete: DeleteRule = .Nullify ) -> Relationship {
////        return Relationship(type: .HasMany, object: object, delete: delete)
////    }
////    
////    static func HasMany(object: (object: T) -> ( (object: T) -> AnyObject ), delete: DeleteRule = .Nullify ) -> Relationship {
////        return Relationship(type: .HasMany, object: object, delete: delete)
////    }
////
////    static func HasFile(object: (object: T) -> ( (object: T) -> AnyObject ), delete: DeleteRule = .Nullify ) -> Relationship {
////        return Relationship(type: .HasMany, object: object, delete: delete)
////    }
//}
//

//

