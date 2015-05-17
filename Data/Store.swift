//
//  DataBacked.swift
//  Take Note
//
//  Created by Daniel Brooker on 6/10/14.
//  Copyright (c) 2014 Nocturnal Code. All rights reserved.
//

import Foundation

///
//public protocol StoreDelegate {
//    
//    /**
//        Called on every model object added to data store
//    
//        :uid: Unique identifier of model
//        :klass: Class of model
//     */
//    func objectAdded(uid: String, klass: AnyClass)
//    
//    /**
//        Called on every model object deleted from data store
//        
//        :uid: Unique identifier of model
//        :klass: Class of model
//    */
//    func objectDeleted(uid: String, klass: AnyClass)
//    
//    /**
//        Called on every model object updated in data store
//        
//        :uid: Unique identifier of model
//        :klass: Class of model
//    */
//    func objectUpdated(uid: String, klass: AnyClass)
//}

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
//    func index<T:Model>:(klass: T.Type, )
}