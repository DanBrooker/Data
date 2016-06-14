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
    var indexedFieldsByType = [String: Set<String>]()
    var searchableFieldsByType = [String: Set<String>]()
    
    typealias SearchHandler = (dictionary: NSMutableDictionary, collection: String, key: String, object: AnyObject, metadata: AnyObject) -> Void
    var searchableHandlers = [String: SearchHandler]()
    
    private let mainThreadConnection: YapDatabaseConnection
    public var connection: YapDatabaseConnection {
        if NSThread.isMainThread() {
            return mainThreadConnection
        } else {
            // FIXME: safe but a little heavy handed (slow)
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
            selector:#selector(YapStore.modified(_:)),
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
            transaction.enumerateKeysInCollection(String(T)) { key, _ in
                let archive = transaction.objectForKey(key, inCollection: String(T)) as! Archive
                objects.append(T(archive: archive))
            }
        }
        return objects
    }
    
    public func find<T : Model>(id: String) -> T? {
        let collection = String(T)
        var object : T? = nil
        connection.readWithBlock { transaction in
            if transaction.hasObjectForKey(id, inCollection: collection) {
                if let archive = transaction.objectForKey(id, inCollection: collection) as? Archive {
                    object = T(archive: archive)
                }
            }
        }
        return object
    }

    public func filter<T : Model>(filter: (element: T) -> (Bool)) -> [T] {
        return all().filter(filter)
    }
    
    public func count<T : Model>(klass: T.Type) -> Int {
        var n = 0
        connection.readWithBlock { (transaction: YapDatabaseReadTransaction!) in
            if let transaction: YapDatabaseReadTransaction = transaction {
                n = Int(transaction.numberOfKeysInCollection(String(T)))
            }
        }
        return n
    }
    
    // MARK: WRITE
    
    public func add<T : Model>(object: T) {
        connection.readWriteWithBlock { transaction in
            transaction.setObject(object.archive, forKey:"\(object.uid)", inCollection: String(T))
        }
    }
    
    public func remove<T : Model>(object: T) {
        connection.readWriteWithBlock { transaction in
            transaction.removeObjectForKey("\(object.uid)", inCollection: String(T))
        }
    }

    public func update<T : Model>(element: T) {
        add(element)
    }

    public func truncate<T: Model>(klass: T.Type) {
        connection.readWriteWithBlock { transaction in
            transaction.removeAllObjectsInCollection(String(T))
        }
    }
    
    public func query<T : Model>(query: Query<T>) -> [T] {
        
        var objects = [T]()
        connection.readWithBlock { transaction in
            transaction.enumerateKeysInCollection(String(T)) { key, _ in
                let archive = transaction.objectForKey(key, inCollection: String(T)) as! Archive
                objects.append(T(archive: archive))
            }
        }
        return query.apply(objects)
    }
    
    public func objectForKey<U>(key: String, collection: String = "") -> U? {
        var obj : U? = nil
        connection.readWithBlock { transaction in
            if transaction.hasObjectForKey(key, inCollection: collection) {
                obj = .Some(transaction.objectForKey(key, inCollection: collection) as! U)
            }
        }
        return obj
    }
    
    public func setObject(object: AnyObject, forKey key: String, collection: String = "") {
        connection.readWriteWithBlock { transaction in
            transaction.setObject(object, forKey:key, inCollection: collection)
        }
    }

    // MARK: INDEXES
    
    public func index<T: Model>(model : T) {
        
        let setup = YapDatabaseSecondaryIndexSetup()
        let type = String(T)
        
        let indexes = model.indexes()
        if indexes.isEmpty {
            return
        }
        
        print("\(model) indexes: \(indexes)")
        
        if indexedFieldsByType[type] == nil {
            indexedFieldsByType[type] = Set<String>()
        }
        
        if searchableFieldsByType[type] == nil {
            searchableFieldsByType[type] = Set<String>()
        }

        for index in indexes {
            switch(index.value) {
            case _ as Double:
                setup.addColumn(index.key, withType: .Real)
                indexedFieldsByType[type]?.insert(index.key)
            case _ as Float:
                setup.addColumn(index.key, withType: .Real)
                indexedFieldsByType[type]?.insert(index.key)
            case _ as Int:
                setup.addColumn(index.key, withType: .Integer)
                indexedFieldsByType[type]?.insert(index.key)
            case _ as Bool:
                setup.addColumn(index.key, withType: .Integer)
                indexedFieldsByType[type]?.insert(index.key)
            case _ as String:
                setup.addColumn(index.key, withType: .Text)
                indexedFieldsByType[type]?.insert(index.key)
                searchableFieldsByType[type]?.insert(index.key)
            default:
                print("Couldn't add index for \(index)")
                return
            }
        }
        
        let handler = YapDatabaseSecondaryIndexHandler.withRowBlock({ dictionary, collection, _key, object, _metadata in
            if(collection == type) {
                let archive = object as! Archive
                let model = T(archive: archive)
            
                for index in model.indexes() {
                    if let value: AnyObject = index.value as? AnyObject {
                        dictionary[index.key] = value
                    }
                }
                print("indexed values: \(dictionary)")
            }
        })
        let secondaryIndex = YapDatabaseSecondaryIndex(setup: setup, handler: handler)
        searchableHandlers[type] = { dictionary, collection, _key, object, _metadata in
            if collection == type {
                let archive = object as! Archive
                let model = T(archive: archive)
                
                for index in model.indexes() {
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
            let fts = YapDatabaseFullTextSearch(columnNames:searchableFields, handler: YapDatabaseFullTextSearchHandler.withObjectBlock({ (dictionary, collection, _, object) in
                
                for (type, handler) in self.searchableHandlers {
                    if type == collection {
                        handler(dictionary: dictionary, collection: collection, key: "", object: object, metadata: "")
                        print("dict: \(dictionary)")
                    }
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
        if let key = queryHash.keys.first {
            
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
            let index = transaction.ext("\(String(T))_index") as! YapDatabaseSecondaryIndexTransaction
            
            index.enumerateKeysAndObjectsMatchingQuery(query, usingBlock: { collection, _uid, object, _ in
                print("\(collection) == \(String(T))")
                if let archive = object as? Archive where collection == String(T) {
                    models.append(T(archive: archive))
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
            transaction.ext("fts").enumerateKeysAndObjectsMatching(string, usingBlock: { collection, _, object, _ in // maybe don't always want objects, maybe only ids?
                if let archive = object as? Archive where collection == String(T) {
                    results.append(T(archive: archive))
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
