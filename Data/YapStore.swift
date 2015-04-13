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
            if let transaction: YapDatabaseReadTransaction = transaction {
                transaction.enumerateKeysInCollection(NSStringFromClass(T)) { key, _ in
                    let object = transaction.objectForKey(key, inCollection: NSStringFromClass(T)) as! T
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
        connection.readWriteWithBlock { transaction in
            if let transaction: YapDatabaseReadWriteTransaction = transaction {
                transaction.setObject(object, forKey:"\(object.uid)", inCollection: NSStringFromClass(T))
            }
        }
    }
    
    public func remove<T : Model>(object: T) {
        connection.readWriteWithBlock { transaction in
            if let transaction: YapDatabaseReadWriteTransaction = transaction {
                transaction.removeObjectForKey("\(object.uid)", inCollection: NSStringFromClass(T))
            }
        }
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
                    let object = transaction.objectForKey(key, inCollection: NSStringFromClass(T)) as! T
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
                    obj = .Some(transaction.objectForKey(key, inCollection: collection) as! T)
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
}
