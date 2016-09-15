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
    func objectAdded(_ indexPaths: [IndexPath])
    func objectRemoved(_ indexPaths: [IndexPath])
    func objectUpdated(_ indexPaths: [IndexPath])
}

///
open class Collection<T> : Swift.Collection where T:Model {
    typealias Element = T
    
    var data = [T]()
    var dataIds = [String]()
    var temporalIds = [String]()
    
    let query : Query<T>
    let datastore : Store
    
    ///
    open var delegate : CollectionDelegate?
    
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
    
    func databaseModified(_ notification: Notification) {
        if let info = (notification as NSNotification).userInfo {
            if let id = info["id"] as? String {
                
                if let index = temporalIds.index(of: id) {
                    temporalIds.remove(at: index)
                    return
                }
                
                let obj : T? = datastore.find("\(id)")
                
                if let index = dataIds.index(of: id) {
                    if let obj = obj {

                        self.data[index] = obj
                        delegate?.objectUpdated([IndexPath(row: index, section: 0)])
                    }
                } else if let obj = obj {

                    if let filter = query.filter {
                        if !filter(obj) {
                            return
                        }
                    }
                    self.data.append(obj)

                }
                
                reapply()
            }
        }
    }
    
    func databaseRemoved(_ notification: Notification) {
        if let info = (notification as NSNotification).userInfo {
            if let id = info["id"] as? String {
                
                if let index = temporalIds.index(of: id) {
                    temporalIds.remove(at: index)
                    return
                }
                
                if let index = dataIds.index(of: id) {
                    
                    self.data.remove(at: index)
                    self.dataIds.remove(at: index)
                
                    delegate?.objectRemoved([IndexPath(row: index, section: 0)])
                }
            }
        }
    }
    
    func runQuery() {
        data = datastore.query(query)
    }
    
    open var startIndex: Int {
        return data.startIndex
    }
    
    open var endIndex: Int {
        return data.endIndex
    }
    
    open subscript (index: Int) -> T {
        return data[index]
    }
    
    open func makeIterator() -> IndexingIterator<[T]> {
        return data.makeIterator()
    }
    
    /// Returns the position immediately after the given index.
    ///
    /// - Parameter i: A valid index of the collection. `i` must be less than
    ///   `endIndex`.
    /// - Returns: The index value immediately after `i`.
    public func index(after i: Int) -> Int {
        return data.index(after: i)
    }
    
    ///
    open func append(_ newElement: T) {
        data.append(newElement)
        temporalIds.append(newElement.uid)
        datastore.add(newElement)
        
        reapply()
    }
    
    ///
    open func appendAll(_ newElements: [T]) {
        
        for element in newElements {
            data.append(element)
            temporalIds.append(element.uid)
            datastore.add(element)
        }
        
        reapply()
    }
    
    ///
    open func removeAtIndex(_ index: Int) -> T {
        let removed = data.remove(at: index)
        temporalIds.append(removed.uid)
        datastore.remove(removed)
        
        reapply()
        return removed
    }
    
    ///
    open func update(_ element: T) {
        datastore.update(element)
        reapply()
    }
    
    fileprivate func diff<S: Equatable>(_ a: [S], b: [S]) -> [S] {
        var d = [S]()
        for e in a {
            if b.index(of: e) == nil {
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
            let index = prevIds.index(of: $0)
            return IndexPath(row: index!, section: 0)
        }))
        
        delegate?.objectAdded(newIds.map({
            let index = updatedIds.index(of: $0)
            return IndexPath(row: index!, section: 0)
        }))
        
        // end
        delegate?.endUpdates()
        
        dataIds = updatedIds
    }
    
    ///
    open var isEmpty: Bool {
        return data.count == 0
    }
    
    ///
    open var count: Int {
        return data.count
    }
    
}

// MARK: UITableViewDataSource Compat
extension Collection {
    
    ///
    public func removeAtIndexPath(_ indexPath: IndexPath) -> T {
        // ignore section, this Data Type doesn't handle sections
        return removeAtIndex((indexPath as NSIndexPath).row)
    }
    
    ///
    public subscript(indexPath: IndexPath) -> T {
        return data[(indexPath as NSIndexPath).row]
    }
    
    ///
    public func numberOfRowsInSection(_ section: Int) -> Int {
        return data.count
    }
}
