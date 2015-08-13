//
//  Store.swift
//  Take Note
//
//  Created by Daniel Brooker on 8/02/15.
//  Copyright (c) 2015 Nocturnal Code. All rights reserved.
//

import YapDatabase

public class YapStore : Store {
    
    let name: String
    let database: YapDatabase
    var indexedFieldsByType = [String: [String]]()
    var searchableFieldsByType = [String: [String]]()
    
    typealias SearchHandler = (dictionary: NSMutableDictionary, collection: String, key: String, object: AnyObject, metadata: AnyObject) -> Void
    var searchableHandlers = [String: SearchHandler]()
    
    private let mainThreadConnection: YapDatabaseConnection
    public var connection: YapDatabaseConnection {
        if NSThread.isMainThread() {
            return mainThreadConnection
        } else {
            return database.newConnection()
        }
    }
    
    public var path: String {
        let dir = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0] 
        return dir.stringByAppendingString("/\(name).yap")
    }

    public init(name: String = "database") {
        let dir = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0] 
        let path = dir.stringByAppendingString("/\(name).yap")
        
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
//                        let collection = change.collection
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
//                        let collection = change.collection
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
    
    // MARK: INDEXES
    
    /// Adding an index
    public func index<T: Model>(model : T, block: ((object: T) -> [Index])  ) {
        
        let setup = YapDatabaseSecondaryIndexSetup()
        let type = NSStringFromClass(T)
        
        let indexes = block(object: model)
        if indexes.isEmpty {
            return
        }
        
        if indexedFieldsByType[type] == nil {
            indexedFieldsByType[type] = []
        }
        
        if searchableFieldsByType[type] == nil {
            searchableFieldsByType[type] = []
        }
        
        for index in indexes {
            switch(index.value) {
            case _ as Double:
                setup.addColumn(index.key, withType: .Real)
                indexedFieldsByType[type]?.append(index.key)
            case _ as Float:
                setup.addColumn(index.key, withType: .Real)
                indexedFieldsByType[type]?.append(index.key)
            case _ as Int:
                setup.addColumn(index.key, withType: .Integer)
                indexedFieldsByType[type]?.append(index.key)
            case _ as Bool:
                setup.addColumn(index.key, withType: .Integer)
                indexedFieldsByType[type]?.append(index.key)
            case _ as String:
                setup.addColumn(index.key, withType: .Text)
                indexedFieldsByType[type]?.append(index.key)
                searchableFieldsByType[type]?.append(index.key)
            default:
                print("Couldn't add index for \(index)")
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
        searchableHandlers[type] = { dictionary, _collection, _key, object, _metadata in
            if let model = object as? T {
                for index in block(object: model) {
                    if let value: AnyObject = index.value as? AnyObject {
                        dictionary[index.key] = value
                    }
                }
            }
        }
        
        database.registerExtension(secondaryIndex, withName: "\(type)_index")
        
        var searchableFields = [String]()
        for (_, value) in searchableFieldsByType {
            for field in value {
                searchableFields.append(field)
            }
        }
        
        if searchableFields.count > 0 {
            print("searchable: \(searchableFields)")
            let fts = YapDatabaseFullTextSearch(columnNames:searchableFields, handler: YapDatabaseFullTextSearchHandler.withObjectBlock({ (dictionary, _, _, object) in
                
                for (type, handler) in self.searchableHandlers {
                    handler(dictionary: dictionary, collection: type, key: "", object: object, metadata: "")
                    print("dict: \(dictionary)")
                }
                
            }))
            print("registered for FTS")
            database.registerExtension(fts, withName: "fts")
        }

    }
    
    public func find<T: Model>(key: String, value: Indexable) -> T? {
        if let value: AnyObject = value as? AnyObject {
            return findModels([key: value]).first
        }
        return nil
    }
    
    public func filter<T: Model>(key: String, value: Indexable) -> [T] {
        if let value: AnyObject = value as? AnyObject {
            return findModels([key: value])
        }
        return []
    }

    func findModels<T: Model>(queryHash: [String: AnyObject]) -> [T] {
        var query : YapDatabaseQuery? = nil
        if let key = queryHash.keys.first { //
            
            if let value: AnyObject = queryHash[key] {
                query = YapDatabaseQuery.queryWithFormat("WHERE \(key) = ?", (value as! NSObject))
            }
        }
        
        if query == nil {
            print("couldn't build query for \(queryHash)")
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
    
    // MARK: - SEARCH
    
    public func search<T: Model>(string string: String) -> [T] {
        if searchableFieldsByType.count == 0 {
            print("Cannot search before setting up indexes")
            return []
        }
        var results = [T]()
        connection.readWithBlock { transaction in
            transaction.ext("fts").enumerateKeysAndObjectsMatching(string, usingBlock: { _, _, object, _ in // maybe don't always want objects, maybe only ids?
                if let object = object as? T {
                    results.append(object)
                }
            })
        }
        return results
    }
    
    public func search<T: Model>(phrase phrase: String) -> [T] {
        return search(string: "\"\(phrase)\"")
    }
    
}

extension YapDatabaseQuery {
    class func queryWithFormat(format: String, _ arguments: CVarArgType...) -> YapDatabaseQuery? {
        return withVaList(arguments, { YapDatabaseQuery(format: format, arguments: $0) })
    }
}
