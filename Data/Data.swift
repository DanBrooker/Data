//
//  Data.swift
//  Data
//
//  Created by Daniel Brooker on 18/03/15.
//  Copyright (c) 2015 Nocturnal Code. All rights reserved.
//

public protocol DataDelegate {
    func beginChanges()
    func endChanges()
    func objectAdded(indexPath: NSIndexPath)
    func objectDeleted(indexPath: NSIndexPath)
    func objectUpdated(indexPath: NSIndexPath)
}

public class Data<T: Model> : CollectionType {
    
    typealias Element = T
    
    var data = [T]()
    var dataIds = [String]()
    
    var sort : ( (a: T,b: T) -> Bool )? {
        didSet {
            resort()
        }
    }
    let query : Query<T>
    let datastore : Store
    
    var delegate : DataDelegate?
    
    init(query: Query<T>, datastore: Store) {
        self.query = query
        self.datastore = datastore
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "databaseModified:", name: "dataStoreModified", object: NSStringFromClass(T))
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "databaseRemoved:", name: "databaseRemoved", object: NSStringFromClass(T))
        runQuery()
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    func databaseModified(notification: NSNotification) {
        if let info = notification.userInfo {
            if let id = info["id"] as? String {
                
                var obj : T? = datastore.find("\(id)")
                
                if let index = find(dataIds, id) {
                    // update
                    if let obj = obj {
                        println("obj: obj")
                        
                        // TODO: somehow figure out it it was this array that updated it, and maybe not notify
                        
                        self.data[index] = obj
                        delegate?.objectUpdated(NSIndexPath(forRow: index, inSection: 0))
                    }
                } else if let obj = obj {
                    
                    // should insert?
                    
                    if let filter = query.filter {
                        if !filter(a: obj) {
                            return
                        }
                    }
                    
                    self.data.append(obj)
                    resort()
                    
                    if let index = find(data, obj) {
                        delegate?.objectUpdated(NSIndexPath(forRow: index, inSection: 0))
                    }
                }
            }
        }
    }
    
    func databaseRemoved(notification: NSNotification) {
        if let info = notification.userInfo {
            if let id = info["id"] as? String {
                
                var obj : T? = datastore.find("\(id)")
                
                if let index = find(dataIds, id) {
                    // remove
                    if let obj = obj {
                        println("obj: obj")
                        
                        self.data.removeAtIndex(index)
                        self.dataIds.removeAtIndex(index)
                        
                        delegate?.objectDeleted(NSIndexPath(forRow: index, inSection: 0))
                    }
                }
                
                
            }
        }
    }
    
    func runQuery() {
        data = datastore.query(query)
        resort()
        // TODO: maybe output delegate calls
    }
    
    public var startIndex: Int {
        return data.startIndex
    }
    
    public var endIndex: Int {
        return data.endIndex
    }
    public subscript (index: Int) -> T {
        return data[index]
    }
    
    public func generate() -> IndexingGenerator<[T]> {
        return data.generate()
    }
    
    func append(newElement: T) {
        data.append(newElement)
        datastore.add(newElement)
        resort()
    }
    
    func appendAll(newElements: [T]) {
        for element in newElements {
            data.append(element)
            datastore.add(element)
        }
        resort()
    }
    
    func removeAtIndex(index: Int) -> T {
        let removed = data.removeAtIndex(index)
        datastore.remove(removed)
        return removed
    }
    
    func update(element: T) {
        datastore.update(element)
        resort()
    }
    
    func resort() {
        if let function = sort {
            data = data.sorted(function)
        }
        dataIds = data.map({ $0.uid })
    }
    
    var empty: Bool {
        return data.count == 0
    }
    
    var count: Int {
        return data.count
    }
    
}
