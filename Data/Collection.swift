//
//  Data.swift
//  Data
//
//  Created by Daniel Brooker on 18/03/15.
//  Copyright (c) 2015 Nocturnal Code. All rights reserved.
//

///
public protocol CollectionDelegate {
    func beginUpdates()
    func endUpdates()
    func objectAdded(indexPaths: [NSIndexPath])
    func objectRemoved(indexPaths: [NSIndexPath])
    func objectUpdated(indexPaths: [NSIndexPath])
}

///
public class Collection<T: Model> : CollectionType {
    
    typealias Element = T
    
    var data = [T]()
    var dataIds = [String]()
    var temporalIds = [String]()
    
    let query : Query<T>
    let datastore : Store
    
    ///
    public var delegate : CollectionDelegate?
    
    var removedProxy: ObserverProxy?
    var modifiedProxy: ObserverProxy?
    
    ///
    public init(query: Query<T>, store: Store) {
        self.query = query
        self.datastore = store
        runQuery()
        
        removedProxy = ObserverProxy(name: "dataStoreRemoved", closure: databaseRemoved)
        modifiedProxy = ObserverProxy(name: "dataStoreModified", closure: databaseModified)
    }
    
    func databaseModified(notification: NSNotification) {
        if let info = notification.userInfo {
            if let id = info["id"] as? String {
                
                if let index = temporalIds.indexOf(id) {
                    temporalIds.removeAtIndex(index)
                    return
                }
                
                let obj : T? = datastore.find("\(id)")
                
                if let index = dataIds.indexOf(id) {
                    if let obj = obj {

                        self.data[index] = obj
                        delegate?.objectUpdated([NSIndexPath(forRow: index, inSection: 0)])
                    }
                } else if let obj = obj {

                    if let filter = query.filter {
                        if !filter(element: obj) {
                            return
                        }
                    }
                    self.data.append(obj)

                }
                
                reapply()
            }
        }
    }
    
    func databaseRemoved(notification: NSNotification) {
        if let info = notification.userInfo {
            if let id = info["id"] as? String {
                
                if let index = temporalIds.indexOf(id) {
                    temporalIds.removeAtIndex(index)
                    return
                }
                
                if let index = dataIds.indexOf(id) {
                    
                    self.data.removeAtIndex(index)
                    self.dataIds.removeAtIndex(index)
                
                    delegate?.objectRemoved([NSIndexPath(forRow: index, inSection: 0)])
                }
            }
        }
    }
    
    func runQuery() {
        data = datastore.query(query)
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
    
    ///
    public func append(newElement: T) {
        data.append(newElement)
        temporalIds.append(newElement.uid)
        datastore.add(newElement)
        
        reapply()
    }
    
    ///
    public func appendAll(newElements: [T]) {
        
        for element in newElements {
            data.append(element)
            temporalIds.append(element.uid)
            datastore.add(element)
        }
        
        reapply()
    }
    
    ///
    public func removeAtIndex(index: Int) -> T {
        let removed = data.removeAtIndex(index)
        temporalIds.append(removed.uid)
        datastore.remove(removed)
        
        reapply()
        return removed
    }
    
    ///
    public func update(element: T) {
        datastore.update(element)
        reapply()
    }
    
    private func diff<S: Equatable>(a: [S], b: [S]) -> [S] {
        var d = [S]()
        for e in a {
            if b.indexOf(e) == nil {
                d.append(e)
            }
        }
        
        return d
    }
    
    func reapply() {
        // begin
        delegate?.beginUpdates()
        
        data = query.apply(data)
        let prevIds = dataIds
        let updatedIds = data.map({ $0.uid })
        
        // compare
        let newIds = diff(updatedIds, b: prevIds)
        let oldIds = diff(prevIds, b: updatedIds)
        
        delegate?.objectRemoved(oldIds.map({
            let index = prevIds.indexOf($0)
            return NSIndexPath(forRow: index!, inSection: 0)
        }))
        
        delegate?.objectAdded(newIds.map({
            let index = updatedIds.indexOf($0)
            return NSIndexPath(forRow: index!, inSection: 0)
        }))
        
        // end
        delegate?.endUpdates()
        
        dataIds = updatedIds
    }
    
    ///
    public var isEmpty: Bool {
        return data.count == 0
    }
    
    ///
    public var count: Int {
        return data.count
    }
    
}

// MARK: UITableViewDataSource Compat
extension Collection {
    
    ///
    public func removeAtIndexPath(indexPath: NSIndexPath) {
        // ignore section, this Data Type doesn't handle sections
        removeAtIndex(indexPath.row)
    }
    
    ///
    public subscript(indexPath: NSIndexPath) -> T {
        return data[indexPath.row]
    }
    
    ///
    public func numberOfRowsInSection(section: Int) -> Int {
        return data.count
    }
}
