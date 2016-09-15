//
//  Store.swift
//  Take Note
//
//  Created by Daniel Brooker on 8/02/15.
//  Copyright (c) 2015 Nocturnal Code. All rights reserved.
//

import YapDatabase

open class YapStore : Store {
    
    let name: String
    let database: YapDatabase
    var indexedFieldsByType = [String: Set<String>]()
    var searchableFieldsByType = [String: Set<String>]()
    
    typealias SearchHandler = (_ dictionary: NSMutableDictionary, _ collection: String, _ key: String, _ object: AnyObject, _ metadata: AnyObject) -> Void
    var searchableHandlers = [String: SearchHandler]()
    
    fileprivate let mainThreadConnection: YapDatabaseConnection
    open var connection: YapDatabaseConnection {
        if Thread.isMainThread {
            return mainThreadConnection
        } else {
            // FIXME: safe but a little heavy handed (slow)
            return database.newConnection()
        }
    }
    
    open var path: String {
        let dir = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] 
        return dir + "/\(name).yap"
    }

    public init(name: String = "database") {
        let dir = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] 
        let path = dir + "/\(name).yap"
        
        self.name = name
        database = YapDatabase(path: path)
                
        self.mainThreadConnection = database.newConnection()
        
        NotificationCenter.default.addObserver(self,
            selector:#selector(YapStore.modified(_:)),
            name:NSNotification.Name.YapDatabaseModified,
            object:database)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func modified(_ notification: Notification) {
        if let dict = (notification as NSNotification).userInfo {
            if let changes = dict["objectChanges"] as? YapSet {
                
                changes.enumerateObjects({ change, _ in
                    if let change = change as? YapCollectionKey {
                        let key = change.key
                        
//                        if key == nil {
//                            return
//                        }
                        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "dataStoreModified"), object: nil, userInfo: ["id": key])
                    }
                })
            } else if let removed = dict["removedKeys"] as? YapSet {
                removed.enumerateObjects({ change, _ in
                    if let change = change as? YapCollectionKey {
                        let key = change.key
                        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "dataStoreRemoved"), object: nil, userInfo: ["id": key])
                    }
                })
            }
        }
    }
    
    // MARK: READ
    
    open func all<T : Model>() -> [T] {
        var objects = [T]()
        connection.read { transaction in
            transaction.enumerateKeys(inCollection: String(describing: T.self)) { key, _ in
                let archive = transaction.object(forKey: key, inCollection: String(describing: T.self)) as! Archive
                objects.append(T(archive: archive))
            }
        }
        return objects
    }
    
    open func find<T : Model>(_ id: String) -> T? {
        let collection = String(describing: T.self)
        var object : T? = nil
        connection.read { transaction in
            if transaction.hasObject(forKey: id, inCollection: collection) {
                if let archive = transaction.object(forKey: id, inCollection: collection) as? Archive {
                    object = T(archive: archive)
                }
            }
        }
        return object
    }

    open func filter<T : Model>(_ filter: (_ element: T) -> (Bool)) -> [T] {
        return all().filter(filter)
    }
    
    open func count<T : Model>(_ klass: T.Type) -> Int {
        var n = 0
        connection.read { (transaction: YapDatabaseReadTransaction!) in
            if let transaction: YapDatabaseReadTransaction = transaction {
                n = Int(transaction.numberOfKeys(inCollection: String(describing: T.self)))
            }
        }
        return n
    }
    
    // MARK: WRITE
    
    open func add<T : Model>(_ object: T) {
        connection.readWrite { transaction in
            transaction.setObject(object.archive, forKey:"\(object.uid)", inCollection: String(describing: T.self))
        }
    }
    
    open func remove<T : Model>(_ object: T) {
        connection.readWrite { transaction in
            transaction.removeObject(forKey: "\(object.uid)", inCollection: String(describing: T.self))
        }
    }

    open func update<T : Model>(_ element: T) {
        add(element)
    }

    open func truncate<T: Model>(_ klass: T.Type) {
        connection.readWrite { transaction in
            transaction.removeAllObjects(inCollection: String(describing: T.self))
        }
    }
    
    open func query<T : Model>(_ query: Query<T>) -> [T] {
        
        var objects = [T]()
        connection.read { transaction in
            transaction.enumerateKeys(inCollection: String(describing: T.self)) { key, _ in
                let archive = transaction.object(forKey: key, inCollection: String(describing: T.self)) as! Archive
                objects.append(T(archive: archive))
            }
        }
        return query.apply(objects)
    }
    
    open func objectForKey<U>(_ key: String, collection: String = "") -> U? {
        var obj : U? = nil
        connection.read { transaction in
            if transaction.hasObject(forKey: key, inCollection: collection) {
                obj = .some(transaction.object(forKey: key, inCollection: collection) as! U)
            }
        }
        return obj
    }
    
    open func setObject(_ object: AnyObject, forKey key: String, collection: String = "") {
        connection.readWrite { transaction in
            transaction.setObject(object, forKey:key, inCollection: collection)
        }
    }

    // MARK: INDEXES
    
    open func index<T: Model>(_ model : T) {
        
        let setup = YapDatabaseSecondaryIndexSetup()
        let type = String(describing: T.self)
        
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
                setup.addColumn(index.key, with: .real)
                indexedFieldsByType[type]?.insert(index.key)
            case _ as Float:
                setup.addColumn(index.key, with: .real)
                indexedFieldsByType[type]?.insert(index.key)
            case _ as Int:
                setup.addColumn(index.key, with: .integer)
                indexedFieldsByType[type]?.insert(index.key)
            case _ as Bool:
                setup.addColumn(index.key, with: .integer)
                indexedFieldsByType[type]?.insert(index.key)
            case _ as String:
                setup.addColumn(index.key, with: .text)
                indexedFieldsByType[type]?.insert(index.key)
                searchableFieldsByType[type]?.insert(index.key)
            default:
                print("Couldn't add index for \(index)")
                return
            }
        }
        
        let handler = YapDatabaseSecondaryIndexHandler.withRowBlock({ _something, dictionary, collection, _key, object, _metadata in
            if(collection == type) {
                let archive = object as! Archive
                let model = T(archive: archive)
            
                for index in model.indexes() {
//                    if let value = index.value as? AnyObject {
                        dictionary[index.key] = index.value
//                    }
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
//                    if let value = index.value as? AnyObject {
                        dictionary[index.key] = index.value
//                    }
                }
            }
        }
        
        database.register(secondaryIndex, withName: "\(type)_index")
        
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
                        handler(dictionary, collection, "", object as AnyObject, "" as AnyObject)
                        print("dict: \(dictionary)")
                    }
                }
                
            }))
            print("registered for FTS")
            database.register(fts, withName: "fts")
        }
    }
    
    open func find<T: Model>(_ key: String, value: Indexable) -> T? {
//        if let value = value as AnyObject {
            return findModels([key: value as AnyObject]).first
//        }
//        return nil
    }
    
    open func filter<T: Model>(_ key: String, value: Indexable) -> [T] {
//        if let value = value as AnyObject {
            return findModels([key: value as AnyObject])
//        }
//        return []
    }

    func findModels<T: Model>(_ queryHash: [String: AnyObject]) -> [T] {
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
        connection.read { transaction in
            let index = transaction.ext("\(String(describing: T.self))_index") as! YapDatabaseSecondaryIndexTransaction
            
            index.enumerateKeysAndObjects(matching: query!, using: { collection, _uid, object, _ in
                print("\(collection) == \(String(describing: T.self))")
                if let archive = object as? Archive , collection == String(describing: T.self) {
                    models.append(T(archive: archive))
                }
            })
        }
        
        return models
    }
    
    // MARK: - SEARCH
    
    open func search<T: Model>(string: String) -> [T] {
        if searchableFieldsByType.count == 0 {
            print("Cannot search before setting up indexes")
            return []
        }
        var results = [T]()
        connection.read { transaction in
            if let fts = transaction.ext("fts") as? YapDatabaseFullTextSearchTransaction {
                fts.enumerateKeysAndObjects(matching: string, using: { collection, _, object, _ in // maybe don't always want objects, maybe only ids?
                    if let archive = object as? Archive , collection == String(describing: T.self) {
                        results.append(T(archive: archive))
                    }
                })
            }
        }
        return results
    }
    
    open func search<T: Model>(phrase: String) -> [T] {
        return search(string: "\"\(phrase)\"")
    }
    
}

extension YapDatabaseQuery {
    class func queryWithFormat(_ format: String, _ arguments: CVarArg...) -> YapDatabaseQuery? {
        return withVaList(arguments, { YapDatabaseQuery(format: format, arguments: $0) })
    }
}
