//
//  Data.swift
//  Data
//
//  Created by Daniel Brooker on 18/03/15.
//  Copyright (c) 2015 Nocturnal Code. All rights reserved.
//

public protocol DataDelegate {
    func beginUpdates()
    func endUpdates()
    func objectAdded(indexPaths: [NSIndexPath])
    func objectRemoved(indexPaths: [NSIndexPath])
    func objectUpdated(indexPaths: [NSIndexPath])
}

public class Data<T: Model> : CollectionType {
    
    typealias Element = T
    
    var data = [T]()
    var dataIds = [String]()
    var temporalIds = [String]()
    
    let query : Query<T>
    let datastore : Store
    
    public var delegate : DataDelegate?
    
    var removedProxy: ObserverProxy?
    var modifiedProxy: ObserverProxy?
    
    public init(query: Query<T>, store: Store) {
        self.query = query
        self.datastore = store
        runQuery()
        
        removedProxy = ObserverProxy(name: "dataStoreRemoved", closure: databaseRemoved)
        modifiedProxy = ObserverProxy(name: "dataStoreModified", closure: databaseModified)
    }
    
    func databaseModified(notification: NSNotification) {
//        println("mod: \(notification)")
        if let info = notification.userInfo {
//            println("info: \(info)")
            if let id = info["id"] as? String {
//                println("id \(id)")
                
                if let index = find(temporalIds, id) {
//                    println("don't notify already handled locally")
                    temporalIds.removeAtIndex(index)
                    return
                }
                
                var obj : T? = datastore.find("\(id)")
                
                if let index = find(dataIds, id) {
                    // update
                    
                    // TODO: identify if this is actually an add or an update?
                    if let obj = obj {
//                        println("obj: obj")

                        self.data[index] = obj
//                        println("delegate \(delegate): updated")
                        delegate?.objectUpdated([NSIndexPath(forRow: index, inSection: 0)])
                    } else {
//                        println("delegate \(delegate): added")
//                        delegate?.objectAdded([NSIndexPath(forRow: index, inSection: 0)])
                    }
                } else if let obj = obj {
                    
                    // should insert?
                    
                    if let filter = query.filter {
                        if !filter(element: obj) {
                            return
                        }
                    }
//                    
                    self.data.append(obj)
//                    reapply()
//
//                    if let index = find(data, obj) {
//                        println("delegate \(delegate): added")
//                        delegate?.objectAdded([NSIndexPath(forRow: index, inSection: 0)])
//                    }
                } else {
//                    println("delegate \(delegate): added")
//                    delegate?.objectAdded([NSIndexPath(forRow: 0, inSection: 0)])
                }
                
                reapply()
            }
        }
    }
    
    func databaseRemoved(notification: NSNotification) {
//        println("removed: \(notification)")
        if let info = notification.userInfo {
            if let id = info["id"] as? String {
                
                if let index = find(temporalIds, id) {
//                    println("don't notify already handled locally")
                    temporalIds.removeAtIndex(index)
                    return
                }
                
//                println("removed key: \(id)")
//                var obj : T? = datastore.find("\(id)")
                
                if let index = find(dataIds, id) {
                    // remove
//                    if let obj = obj {
//                        println("obj: obj")
                    
                        self.data.removeAtIndex(index)
                        self.dataIds.removeAtIndex(index)
                    
//                        println("delegate \(delegate): removed")
                        delegate?.objectRemoved([NSIndexPath(forRow: index, inSection: 0)])
//                    }
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
    
    public func append(newElement: T) {
        data.append(newElement)
//        dataIds.append(newElement.uid)
        temporalIds.append(newElement.uid)
        datastore.add(newElement)
        
        reapply()
        
//        if let index = find(data, newElement) {
//            delegate?.objectAdded([NSIndexPath(forRow: index, inSection: 0)])
//        }
    }
    
    public func appendAll(newElements: [T]) {
        
//        var indexPaths = [NSIndexPath]()
        for element in newElements {
            data.append(element)
//            dataIds.append(element.uid)
            temporalIds.append(element.uid)
            datastore.add(element)
            

            
//            if let index = find(data, element) {
//                indexPaths.append(NSIndexPath(forRow: index, inSection: 0))
//            }
        }
        
        reapply()
        
//        if !indexPaths.isEmpty {
//            delegate?.objectAdded(indexPaths)
//        }
    }
    
    public func removeAtIndex(index: Int) -> T {
        let removed = data.removeAtIndex(index)
//        dataIds.removeAtIndex(index)
        temporalIds.append(removed.uid)
        datastore.remove(removed)
//        delegate?.objectRemoved([NSIndexPath(forRow: index, inSection: 0)])
        reapply()
        return removed
    }
    
    public func update(element: T) {
        datastore.update(element)
        reapply()
    }
    
    private func diff<S: Equatable>(a: [S], b: [S]) -> [S] {
        var d = [S]()
        for e in a {
            if find(b, e) == nil {
                d.append(e)
            }
        }
        
        return d
    }
    
    func reapply() {
        // begin
        delegate?.beginUpdates()
        println("---- begin -----\n")
        
        data = query.apply(data)
        let prevIds = dataIds
        let updatedIds = data.map({ $0.uid })
        
        println("prev: \(prevIds)")
        println("next: \(updatedIds)")
        
        // compare
        let newIds = diff(updatedIds, b: prevIds)
        let oldIds = diff(prevIds, b: updatedIds)
        
        println("added \(newIds)")
        println("removed: \(oldIds)")
        
        delegate?.objectRemoved(oldIds.map({
            let index = find(prevIds, $0)
            return NSIndexPath(forRow: index!, inSection: 0)
        }))
        
        delegate?.objectAdded(newIds.map({
            let index = find(updatedIds, $0)
            return NSIndexPath(forRow: index!, inSection: 0)
        }))
        
        // end
        delegate?.endUpdates()
        println("\n---- end -----\n")
        
        dataIds = updatedIds
    }
    
    public var isEmpty: Bool {
        return data.count == 0
    }
    
    public var count: Int {
        return data.count
    }
    
}

// MARK: UITableViewDataSource Compat
extension Data {
    
    public func removeAtIndexPath(indexPath: NSIndexPath) {
        // ignore section, this Data doesn't handle section
        removeAtIndex(indexPath.row)
    }
    
    public subscript(indexPath: NSIndexPath) -> T {
        return data[indexPath.row]
    }
    
    public func numberOfRowsInSection(section: Int) -> Int {
        return data.count
    }
}
