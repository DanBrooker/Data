//
//  Store.swift
//  Take Note
//
//  Created by Daniel Brooker on 8/02/15.
//  Copyright (c) 2015 Nocturnal Code. All rights reserved.
//

import YapDatabase

public class YapStore : Store {
    
    let database: YapDatabase
    let name: String
    
    private let mainThreadConnection: YapDatabaseConnection
    public var connection: YapDatabaseConnection {
        if NSThread.isMainThread() {
            return mainThreadConnection
        } else {
            return database.newConnection()
        }
    }
    
    public var path: String {
        let dir = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0] as! String
        return dir.stringByAppendingPathComponent("\(name).yap")
    }

    public init(name: String = "database") {
        let dir = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0] as! String
        let path = dir.stringByAppendingPathComponent("\(name).yap")
        
        self.name = name
        database = YapDatabase(path: path)
                
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
        if let dict = notification.userInfo {
            if let changes = dict["objectChanges"] as? YapSet {
                
                changes.enumerateObjectsUsingBlock({ change, _ in
                    if let change = change as? YapCollectionKey {
                        let collection = change.collection
                        let key = change.key
                        
                        if key == nil {
                            return
                        }
                        NSNotificationCenter.defaultCenter().postNotificationName("dataStoreModified", object: nil, userInfo: ["id": key])
                    }
                })
            } else if let removed = dict["removedKeys"] as? YapSet {
                removed.enumerateObjectsUsingBlock({ change, _ in
                    if let change = change as? YapCollectionKey {
                        let collection = change.collection
                        let key = change.key
                        NSNotificationCenter.defaultCenter().postNotificationName("dataStoreRemoved", object: nil, userInfo: ["id": key])
                    }
                })
            }
        }
    }
    
    // MARK: READ
    
    public func all<T : Model>() -> [T] {
        var objects = [T]()
        connection.readWithBlock { transaction in
//            if let transaction: YapDatabaseReadTransaction = transaction {
                transaction.enumerateKeysInCollection(NSStringFromClass(T)) { key, _ in
                    let object = transaction.objectForKey(key, inCollection: NSStringFromClass(T)) as! T
                    objects.append(object as T)
                }
//            }
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
        connection.readWriteWithBlock { transaction in
//            if let transaction: YapDatabaseReadWriteTransaction = transaction {
                transaction.setObject(object, forKey:"\(object.uid)", inCollection: NSStringFromClass(T))
//            }
        }
    }
    
    public func remove<T : Model>(object: T) {
        connection.readWriteWithBlock { transaction in
//            if let transaction: YapDatabaseReadWriteTransaction = transaction {
                transaction.removeObjectForKey("\(object.uid)", inCollection: NSStringFromClass(T))
//            }
        }
    }
    
    public func update<T : Model>(element: T) {
        add(element)
    }
    
    public func truncate<T: Model>(klass: T.Type) {
        connection.readWriteWithBlock { transaction in
//            if let transaction: YapDatabaseReadWriteTransaction = transaction {
                transaction.removeAllObjectsInCollection(NSStringFromClass(T))
//            }
        }
    }
    
    public func query<T : Model>(query: Query<T>) -> [T] {
        
        var objects = [T]()
        connection.readWithBlock { transaction in
//            if let transaction: YapDatabaseReadTransaction = transaction {
                transaction.enumerateKeysInCollection(NSStringFromClass(T)) { key, _ in
                    let object = transaction.objectForKey(key, inCollection: NSStringFromClass(T)) as! T
                    objects.append(object as T)
                }
//            }
        }
        return query.apply(objects)
    }
    
    public func objectForKey<T>(key: String, collection: String = "") -> T? {
        var obj : T? = nil
        connection.readWithBlock { transaction in
//            if let transaction: YapDatabaseReadTransaction = transaction {
                if transaction.hasObjectForKey(key, inCollection: collection) {
                    obj = .Some(transaction.objectForKey(key, inCollection: collection) as! T)
                }
//            }
        }
        return obj
    }
    
    public func setObject(object: AnyObject, forKey key: String, collection: String = "") {
        connection.readWriteWithBlock { transaction in
//            if let transaction: YapDatabaseReadWriteTransaction = transaction {
                transaction.setObject(object, forKey:key, inCollection: collection)
//            }
        }
    }
    
    // MARK: Indexing
    
    /// Adding an index
    public func index<T: Model>(model : T, block: ((object: T) -> [Index])  ) {
        
        let setup = YapDatabaseSecondaryIndexSetup()
        
        let indexes = block(object: model)
        if indexes.isEmpty {
            return
        }
        
        for index in indexes {
            switch(index.value) {
            case let double as Double:
                setup.addColumn(index.key, withType: .Real)
            case let float as Float:
                setup.addColumn(index.key, withType: .Real)
            case let int as Int:
                setup.addColumn(index.key, withType: .Integer)
            case let int as Bool:
                setup.addColumn(index.key, withType: .Integer)
            case let text as String:
                setup.addColumn(index.key, withType: .Text)
            default:
                println("Couldn't add index for \(index)")
                return
            }
        }
        
        let handler = YapDatabaseSecondaryIndexHandler.withRowBlock({ dictionary, _collection, _key, object, _metadata in
            if let model = object as? T {
                for index in block(object: model) {
                    if let value: AnyObject = index.value as? AnyObject {
                        dictionary[index.key] = value
                    }
                }
            }
        })
        let secondaryIndex = YapDatabaseSecondaryIndex(setup: setup, handler: handler)
        
        database.registerExtension(secondaryIndex, withName: "\(NSStringFromClass(T))_index")
    }
    
    public func find<T: Model>(key: String, value: String) -> T? {
        return findModels([key: value]).first
    }
    
    public func find<T: Model>(key: String, value: Bool) -> T? {
        return findModels([key: value]).first
    }
    
    public func find<T: Model>(key: String, value: Double) -> T? {
        return findModels([key: value]).first
    }
    
    public func find<T: Model>(key: String, value: Float) -> T? {
        return findModels([key: value]).first
    }
    
    public func filter<T: Model>(key: String, value: String) -> [T] {
        return findModels([key: value])
    }
    
    public func filter<T: Model>(key: String, value: Bool) -> [T] {
        return findModels([key: value])
    }
    
    public func filter<T: Model>(key: String, value: Double) -> [T] {
        return findModels([key: value])
    }
    
    public func filter<T: Model>(key: String, value: Float) -> [T] {
        return findModels([key: value])
    }

    func findModels<T: Model>(queryHash: [String: AnyObject]) -> [T] {
        var query : YapDatabaseQuery? = nil
        if let key = queryHash.keys.first { //
            
            if let value: AnyObject = queryHash[key] {
                query = YapDatabaseQuery.queryWithFormat("WHERE \(key) = ?", (value as! NSObject))
            }
        }
        
        if query == nil {
            println("couldn't build query for \(queryHash)")
            return []
        }
        
        var models = [T]()
        connection.readWithBlock { transaction in
            let index = transaction.ext("\(NSStringFromClass(T))_index") as! YapDatabaseSecondaryIndexTransaction
            
            index.enumerateKeysAndObjectsMatchingQuery(query, usingBlock: { _, _, object, _ in
                if let object = object as? T {
                    models.append(object)
                }
            })
        }
        
        return models
    }
    
}

extension YapDatabaseQuery {
    class func queryWithFormat(format: String, _ arguments: CVarArgType...) -> YapDatabaseQuery? {
        return withVaList(arguments, { YapDatabaseQuery(format: format, arguments: $0) })
    }
}
