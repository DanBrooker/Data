//
//  Store.swift
//  Take Note
//
//  Created by Daniel Brooker on 8/02/15.
//  Copyright (c) 2015 Nocturnal Code. All rights reserved.
//

import YapDatabase

public class YapStore : Store {
    
//    var delegate: DataStoreDelegate?
    
    let database: YapDatabase
    let name: String
    
//    var relationshipsLookup = [ModelRelationships.Type]()
    
    private let mainThreadConnection: YapDatabaseConnection
    public var connection: YapDatabaseConnection {
        if NSThread.isMainThread() {
            return mainThreadConnection
        } else {
            return database.newConnection()
        }
    }
    
    public var path: String {
        let dir = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0] as String
        return dir.stringByAppendingPathComponent("\(name).yap")
    }

    public init(name: String = "database") {
        let dir = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0] as String
        let path = dir.stringByAppendingPathComponent("\(name).yap")
        
        self.name = name
        database = YapDatabase(path: path)
                
                //        let relationships = YapDatabaseRelationship()
                
                //        if !database.registerExtension(relationships, withName:"relationships") {
                //            println("Unable to register extension: relationships");
                //        }
                
        self.mainThreadConnection = database.newConnection()
        
        NSNotificationCenter.defaultCenter().addObserver(self,
            selector:"modified:",
            name:YapDatabaseModifiedNotification,
            object:database)
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    @objc func modified(notification: NSNotification) {
//        println("notification: \(notification)")
        if let dict = notification.userInfo {
            if let changes = dict["objectChanges"] as? YapSet {
//                println("\(changes)")
                
                changes.enumerateObjectsUsingBlock({ change, _ in
                    if let change = change as? YapCollectionKey {
                        let collection = change.collection
                        let key = change.key
                        
                        if key == nil {
                            return
                        }
                        
//                        self.delegate?.objectUpdated(key, klass: NSClassFromString(collection))
//                        NSNotificationCenter.defaultCenter().postNotificationName("dataStoreModified", object: collection, userInfo: ["id": key])
                        NSNotificationCenter.defaultCenter().postNotificationName("dataStoreModified", object: nil, userInfo: ["id": key])
                    }
                })
            } else if let removed = dict["removedKeys"] as? YapSet {
                removed.enumerateObjectsUsingBlock({ change, _ in
                    if let change = change as? YapCollectionKey {
                        let collection = change.collection
                        let key = change.key
//                        self.delegate?.objectDeleted(key, klass: NSClassFromString(collection))
//                        NSNotificationCenter.defaultCenter().postNotificationName("dataStoreRemoved", object: collection, userInfo: ["id": key])
                        NSNotificationCenter.defaultCenter().postNotificationName("dataStoreRemoved", object: nil, userInfo: ["id": key])
                    }
                })
            }
        }
//        delegate?.didUpdate()
    }
    
    // MARK: READ
    
    public func all<T : Model>() -> [T] {
        var objects = [T]()
        connection.readWithBlock { transaction in
            if let transaction: YapDatabaseReadTransaction = transaction {
                transaction.enumerateKeysInCollection(NSStringFromClass(T)) { key, _ in
                    let object = transaction.objectForKey(key, inCollection: NSStringFromClass(T)) as T
                    objects.append(object as T)
                }
            }
        }
        return objects
    }
    
    public func find<T : Model>(id: String) -> T? {
        return objectForKey(id, collection: NSStringFromClass(T))
    }
    
    public func filter<T : Model>(filter: (element: T) -> (Bool)) -> [T] {
        return all().filter(filter)
    }
    
    public func count<T : Model>(klass: T.Type) -> Int {
        var n = 0
        connection.readWithBlock { (transaction: YapDatabaseReadTransaction!) in
            if let transaction: YapDatabaseReadTransaction = transaction {
                n = Int(transaction.numberOfKeysInCollection(NSStringFromClass(T)))
            }
        }
        return n
    }
    
    // MARK: WRITE
    
    public func add<T : Model>(object: T) {
//        NSNotificationCenter.defaultCenter().postNotificationName("modelWillSave", object: object)
        connection.readWriteWithBlock { transaction in
            if let transaction: YapDatabaseReadWriteTransaction = transaction {
                transaction.setObject(object, forKey:"\(object.uid)", inCollection: NSStringFromClass(T))
//                object.saving(transaction)
            }
        }
//        NSNotificationCenter.defaultCenter().postNotificationName("modelDidSave", object: object)
    }
    
    public func remove<T : Model>(object: T) {
//        NSNotificationCenter.defaultCenter().postNotificationName("modelWillDelete", object: object)
        connection.readWriteWithBlock { transaction in
            if let transaction: YapDatabaseReadWriteTransaction = transaction {
                transaction.removeObjectForKey("\(object.uid)", inCollection: NSStringFromClass(T))
            }
        }
//        NSNotificationCenter.defaultCenter().postNotificationName("modelDidDelete", object: object)
    }
    
    public func update<T : Model>(element: T) {
        add(element)
    }
    
    public func truncate<T: Model>(klass: T.Type) {
        connection.readWriteWithBlock { transaction in
            if let transaction: YapDatabaseReadWriteTransaction = transaction {
                transaction.removeAllObjectsInCollection(NSStringFromClass(T))
            }
        }
    }
    
    public func query<T : Model>(query: Query<T>) -> [T] {
        
        var objects = [T]()
        connection.readWithBlock { transaction in
            if let transaction: YapDatabaseReadTransaction = transaction {
                transaction.enumerateKeysInCollection(NSStringFromClass(T)) { key, _ in
                    let object = transaction.objectForKey(key, inCollection: NSStringFromClass(T)) as T
                    objects.append(object as T)
                }
            }
        }
        return query.apply(objects)
    }
    
    func objectForKey<T>(key: String, collection: String = "") -> T? {
        var obj : T? = nil
        connection.readWithBlock { transaction in
            if let transaction: YapDatabaseReadTransaction = transaction {
                if transaction.hasObjectForKey(key, inCollection: collection) {
                    obj = .Some(transaction.objectForKey(key, inCollection: collection) as T)
                }
            }
        }
        return obj
    }
    
    func setObject(object: AnyObject, forKey key: String, collection: String = "") {
        connection.readWriteWithBlock { transaction in
            if let transaction: YapDatabaseReadWriteTransaction = transaction {
                transaction.setObject(object, forKey:key, inCollection: collection)
            }
        }
    }
    
//    func relationshipForName<T : Model, U: Model>(name: String, model: T) -> U? {
//        let array : [U] = relationshipForName(name, model: model)
//        return array.first
//    }
//    
//    func relationshipForName<T : Model, U: Model>(name: String, model: T) -> [U] {
//        var objects = [U]()
//        
//        connection.readWithBlock { transaction in
//            if let transaction: YapDatabaseReadTransaction = transaction {
//            
//                transaction.ext("relationships").enumerateEdgesWithName(name, sourceKey: model.uid, collection: "\(NSStringFromClass(U))", usingBlock:
//                    { (edge, stop) -> Void in
//                    
//                    if let object = transaction.objectForKey(edge.destinationKey, inCollection: edge.destinationCollection) as? U {
//                        objects.append(object)
//                    } else {
//                        println("should trim this edge: \(edge)")
//                    }
//                })
//            }
//        }
//        
//        return objects
//    }
    
//    func setRelationshipForName<T: Model, U: Model>(name: String, model: T, object: U, type: RelationshipType = .BelongsTo, delete: DeleteRule = .Nullify) {
//        connection.readWriteWithBlock { transaction in
//            if let transaction: YapDatabaseReadWriteTransaction = transaction {
//        
//                transaction.ext("relationships").enumerateEdgesWithName(name, sourceKey: model.uid, collection: "\(NSStringFromClass(U))", usingBlock: { (edge, stop) -> Void in
//                    transaction.ext("relationships").removeEdge(edge, withProcessing: YDB_NotifyReason.EdgeDeleted)
//                })
//                
//                var deleteRule: UInt16 = 0
//                switch(delete) {
//                case .Delete:
//                    switch(type) {
//                    case .BelongsTo:
//                        deleteRule =  UInt16(YDB_DeleteSourceIfDestinationDeleted)
//                    case .HasOne:
//                        deleteRule =  UInt16(YDB_DeleteDestinationIfSourceDeleted)
//                    case .HasMany:
//                        deleteRule =  UInt16(YDB_DeleteDestinationIfSourceDeleted)
//                    case .HasFile:
//                        deleteRule =  UInt16(YDB_DeleteDestinationIfSourceDeleted)
//                    }
//                case .Nullify:
//                    deleteRule = 0
//                }
//                
//                let edge = YapDatabaseRelationshipEdge(name: name, sourceKey: model.uid, collection: "\(NSStringFromClass(T))", destinationKey: object.uid, collection: "\(NSStringFromClass(U))", nodeDeleteRules: deleteRule)
//                transaction.ext("relationships").addEdge(edge)
//            }
//        }
//    }
//    
//    func setRelationshipForName<T: Model, U: Model>(name: String, model: T, collection: [U], type: RelationshipType = .HasMany, delete: DeleteRule = .Nullify) {
//        connection.readWriteWithBlock { transaction in
//            if let transaction: YapDatabaseReadWriteTransaction = transaction {
//                
//                transaction.ext("relationships").enumerateEdgesWithName(name, sourceKey: model.uid, collection: "\(NSStringFromClass(U))", usingBlock: { (edge, stop) -> Void in
//                    transaction.ext("relationships").removeEdge(edge, withProcessing: YDB_NotifyReason.EdgeDeleted)
//                })
//                
//                var deleteRule: UInt16 = 0
//                switch(delete) {
//                case .Delete:
//                    switch(type) {
//                    case .BelongsTo:
//                        deleteRule =  UInt16(YDB_DeleteSourceIfDestinationDeleted)
//                    case .HasOne:
//                        deleteRule =  UInt16(YDB_DeleteDestinationIfSourceDeleted)
//                    case .HasMany:
//                        deleteRule =  UInt16(YDB_DeleteDestinationIfSourceDeleted)
//                    case .HasFile:
//                        deleteRule =  UInt16(YDB_DeleteDestinationIfSourceDeleted)
//                    }
//                case .Nullify:
//                    deleteRule = 0
//                }
//                
//                for object in collection {
//                    let edge = YapDatabaseRelationshipEdge(name: name, sourceKey: model.uid, collection: "\(NSStringFromClass(T))", destinationKey: object.uid, collection: "\(NSStringFromClass(U))", nodeDeleteRules: deleteRule)
//                    transaction.ext("relationships").addEdge(edge)
//                }
//                
//            }
//        }
//    }
}

//extension Relationship {
//
//    func yap_deleteRule() -> YDB_NodeDeleteRules {
//        switch(delete) {
//        case .Delete:
//            switch(type) {
//            case .BelongsTo:
//                return UInt16(YDB_DeleteSourceIfDestinationDeleted)
//            case .HasOne:
//                return UInt16(YDB_DeleteDestinationIfSourceDeleted)
//            case .HasMany:
//                return UInt16(YDB_DeleteDestinationIfSourceDeleted)
//            case .HasFile:
//                return UInt16(YDB_DeleteDestinationIfSourceDeleted)
//            }
//        case .Nullify:
//            return 0
//        }
//    }
//
//    func yap_relationshipEdges<T:Model, U:Model>(origin: T, target: U? = nil, targetFile: String? = nil, targetCollection: [U]? = nil) -> [YapDatabaseRelationshipEdge] {
//        var edges = [YapDatabaseRelationshipEdge]()
//        let name = "\(NSStringFromClass(T))\(NSStringFromClass(U))"
//        
//        switch(type) {
//        case .BelongsTo:
//            println("belongsTo")
//            let name = "\(NSStringFromClass(T))\(NSStringFromClass(U))"
//            let edge = YapDatabaseRelationshipEdge(name: name, sourceKey: origin.uid, collection: "\(NSStringFromClass(T))", destinationKey: target?.uid, collection: "\(NSStringFromClass(U))", nodeDeleteRules: yap_deleteRule())
//            edges.append(edge)
//        case .HasOne:
//            println("hasOne")
//        case .HasMany:
//            println("hasMany")
//            for target in targetCollection! {
//                let edge = YapDatabaseRelationshipEdge(name: name, sourceKey: origin.uid, collection: "\(NSStringFromClass(T))", destinationKey: target.uid, collection: "\(NSStringFromClass(U))", nodeDeleteRules: yap_deleteRule())
//                edges.append(edge)
//            }
//        case .HasFile:
//            println("hasFile")
//        }
//        return edges
//    }
//    
//}