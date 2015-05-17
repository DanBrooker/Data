//
//  YapStoreTests.swift
//  Data
//
//  Created by Daniel Brooker on 17/03/15.
//  Copyright (c) 2015 Nocturnal Code. All rights reserved.
//

import XCTest
import Data

let store = YapStore()

class TestModel : NSObject, Model {
    
    let uid: String
    let enabled: Bool
    
    init(uid: String, enabled: Bool = true) {
        self.uid = uid
        self.enabled = enabled
    }
    
    required init(coder aDecoder: NSCoder) {
        uid = aDecoder.decodeObjectForKey("uid") as! String
        enabled =  aDecoder.decodeBoolForKey("enabled")
    }
    
    func encodeWithCoder(aCoder: NSCoder) {
        aCoder.encodeObject(uid, forKey: "uid")
        aCoder.encodeBool(enabled, forKey: "enabled")
    }
}

func ==(lhs: TestModel, rhs: TestModel) -> Bool {
    return lhs.uid == rhs.uid
}

class TestA : NSObject, Model {
    let uid: String
    
//    lazy var bees: HasMany<TestA, TestB> = {
//        return HasMany<TestA, TestB>()
//    }()
    
    init(uid: String) {
        self.uid = uid
//        self.bees = HasMany(name: "bees", owner: uid)
    }
    
    required init(coder aDecoder: NSCoder) {
        uid = aDecoder.decodeObjectForKey("uid") as! String
//        self.bees = HasMany(name: "bees", owner: self) //Data<TestB>(query: Relationship.query(self, .HasMany, "bees"), store: store)
    }
    
    func encodeWithCoder(aCoder: NSCoder) {
        aCoder.encodeObject(uid, forKey: "uid")
    }
}

func ==(lhs: TestA, rhs: TestA) -> Bool {
    return lhs.uid == rhs.uid
}

class TestB : NSObject, Model {
    let uid: String
    
    init(uid: String) {
        self.uid = uid
    }
    
    required init(coder aDecoder: NSCoder) {
        uid = aDecoder.decodeObjectForKey("uid") as! String
    }
    
    func encodeWithCoder(aCoder: NSCoder) {
        aCoder.encodeObject(uid, forKey: "uid")
    }
}

func ==(lhs: TestB, rhs: TestB) -> Bool {
    return lhs.uid == rhs.uid
}

class YapStoreTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        store.truncate(TestModel.self)
        waitFor("Truncating Notifications")
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    // MARK: - READ
    
    //    func all<T : Model>() -> [T]
    func testAll() {
        for i in 0..<10 {
            store.add(TestModel(uid: "test-\(i)"))
        }
        
        let models: [TestModel] = store.all()
        XCTAssert(models.count == 10, "Models should have 10 items but was \(models.count)")
    }
    
    //    func find<T : Model>(id: String) -> T?
    func testFind() {
        
        for i in 0..<10 {
            store.add(TestModel(uid: "test-\(i)"))
        }
        
        if let model : TestModel = store.find("test-5") {
            XCTAssert(true, "Found")
        } else {
            XCTAssert(true, "Model for id=test-5 not found")
        }
    }
    
    //    func filter<T: Model>(filter: (element: T) -> (Bool) ) -> [T]
    func testFilter() {
        
        for i in 0..<10 {
            store.add(TestModel(uid: "test-\(i)"))
            store.add(TestModel(uid: "find-test-\(i)"))
        }
        
        let modelsWithFind: [TestModel] = store.filter({ $0.uid.hasPrefix("find") })
        XCTAssert(modelsWithFind.count == 10, "Models should have 10 items but was \(modelsWithFind.count)")
        
        let modelsWithoutFind: [TestModel] = store.filter({ !$0.uid.hasPrefix("find") })
        XCTAssert(modelsWithoutFind.count == 10, "Models should have 10 items but was \(modelsWithoutFind.count)")
    }
    
    //    func count<T: Model>(klass: T.Type) -> Int
    func testCount() {
        XCTAssert(store.count(TestModel.self) == 0, "Should have only 0 models object but was \(store.count(TestModel.self))")

        store.add(TestModel(uid: "test-1"))
        store.add(TestModel(uid: "test-2"))
        store.add(TestModel(uid: "test-3"))
        
        XCTAssert(store.count(TestModel.self) == 3, "Should have only 3 model objects but was \(store.count(TestModel.self))")
    }
    
    //    func query<T : Model>(query: Query<T>, observer: StoreDelegate?) -> [T]
    func testQuery() {
        
        for i in 0..<10 {
            store.add(TestModel(uid: "test-\(i)"))
            store.add(TestModel(uid: "find-test-\(i)"))
        }
        
        let allQuery = Query<TestModel>()
        let all = store.query(allQuery)
        
        XCTAssert(all.count == 20, "Should have 20 model objects but was \(all.count))")
        
        let limitQuery = Query<TestModel>(window: 0..<10)
        let limited = store.query(limitQuery)
        
        XCTAssert(limited.count == 10, "Should have 10 model objects but was \(limited.count))")
        
        let filterQuery = Query<TestModel>(filter: {
            return $0.uid.hasPrefix("find")
        })
        let filtered = store.query(filterQuery)
        
        XCTAssert(filtered.count == 10, "Should have 10 model objects but was \(filtered.count))")
        
        let filterLimitedQuery = Query<TestModel>(window: 0..<5, filter: {
            return $0.uid.hasPrefix("find")
        })
        let filteredLimited = store.query(filterLimitedQuery)
        
        XCTAssert(filteredLimited.count == 5, "Should have 5 model objects but was \(filteredLimited.count))")
        
        let filterLimited2Query = Query<TestModel>(window: 0..<20, filter: {
            return !$0.uid.hasPrefix("find")
        })
        let filteredLimited2 = store.query(filterLimited2Query)
        
        XCTAssert(filteredLimited2.count != 20, "Should have not have 20 model objects but was \(filteredLimited2.count))")
    }
    
//    func testGroupedQuery() {
//        for i in 0..<10 {
//            store.add(TestModel(uid: "test-\(i)"))
//            store.add(TestModel(uid: "find-test-\(i)"))
//        }
//        
//        let query = Query<TestModel>(group: { $0.uid } )
//        let all = store.query(query)
//        
//        XCTAssert(all.count == 2, "Should have 2 groups but was \(all.count))")
//    }
    
    // MARK: - WRITE
   
    //    func add<T : Model>(element: T)
    func testAdd() {
        store.add(TestModel(uid: "test-add"))
        
        XCTAssert(store.count(TestModel.self) == 1, "Should have only one model object but was \(store.count(TestModel.self))")
    }
    
    //    func remove<T : Model>(element: T)
    func testRemove() {
        let object = TestModel(uid: "test-remove")
        
        store.add(object)
        store.remove(object)
        
        XCTAssert(store.count(TestModel.self) == 0, "Should have only 0 models but was \(store.count(TestModel.self))")
    }
    
    //    func update<T : Model>(element: T)
    func testUpdate() {
        let object = TestModel(uid: "test-update")
        
        store.add(object)
        store.update(object)
        
        XCTAssert(store.count(TestModel.self) == 1, "Should have 1 model but was \(store.count(TestModel.self))")
        
    }
    
    //    func truncate<T: Model>(klass: T.Type)
    func testTruncate() {
        let object = TestModel(uid: "test-update")
        
        store.add(object)
        XCTAssert(store.count(TestModel.self) == 1, "Should have 1 model but was \(store.count(TestModel.self))")
        
        store.truncate(TestModel.self)
        
        XCTAssert(store.count(TestModel.self) == 0, "Should have 0 models but was \(store.count(TestModel.self))")
    }
    
    func testDataAdd() {
        let query = Query<TestModel>()
        let data = Data<TestModel>(query: query, store: store)
        
        data.append(TestModel(uid: "test-data-add"))
        
        XCTAssert(data.count == 1, "Should have only 1 model but was \(data.count)")
        XCTAssert(store.count(TestModel.self) == 1, "Should have 1 model but was \(store.count(TestModel.self))")
    }
    
    func testDataBackgroundAdd() {
        
        let query = Query<TestModel>()
        let data = Data<TestModel>(query: query, store: store)
        
        store.add(TestModel(uid: "test-data-add"))
        
        waitFor("Background Thread")
        
        XCTAssert(store.count(TestModel.self) == 1, "Should have only 1 model but was \(store.count(TestModel.self))")
        XCTAssert(data.count == 1, "Should have 1 model but was \(data.count)")
    }
    
    func testDataBackgroundRemove() {
        
        let query = Query<TestModel>()
        let data = Data<TestModel>(query: query, store: store)
        
        let model = TestModel(uid: "test-data-remove")
        data.append(model)
        
        store.remove(model)
        
        waitFor("Background Thread")
        
        XCTAssert(store.count(TestModel.self) == 0, "Should have 0 models but was \(store.count(TestModel.self))")
        XCTAssert(data.count == 0, "Should have 0 models but was \(data.count)")
    }
    
    // MARK: - Tableview
    
    func testTableViewDelegate() {
        
        let query = Query<TestModel>()
        let data = Data<TestModel>(query: query, store: store)
        
        let delegate = TableViewDelegate()
        
        data.delegate = delegate
        
        let zero = TestModel(uid: "0")
        
        data.append(zero)
        waitFor("delegate added")
        
        store.update(zero)
        waitFor("delegate updated")
        
        data.removeAtIndex(0)
        waitFor("delegate removed")
        
        println("\(delegate.changes)")
        
        if delegate.changes.count == 3 {
            XCTAssertEqual(delegate.changes[0], "add <0,0>", "")
            XCTAssertEqual(delegate.changes[1], "update <0,0>", "")
            XCTAssertEqual(delegate.changes[2], "remove <0,0>", "")
        } else {
            XCTAssert(false, "should have 3 changes but was \(delegate.changes.count)")
        }
        
    }
    
    func testSortedTableViewDelegate() {
        
        let query = Query<TestModel>(window: 0...2, order: { $0.uid.toInt() < $1.uid.toInt() })
        let data = Data<TestModel>(query: query, store: store)
        
        let delegate = TableViewDelegate()
        
        data.delegate = delegate
        
        let zero = TestModel(uid: "0")
        let one = TestModel(uid: "1")
        let two = TestModel(uid: "2")
        let three = TestModel(uid: "3")
        let four = TestModel(uid: "4")
        
        data.append(one)
        data.append(zero)
        data.append(two)
        waitFor("delegate added")
        
        data.removeAtIndex(0)
        waitFor("delegate removed")
        
        data.append(four)
        data.append(three)
        data.append(zero)
        waitFor("delegate added")
        
        println("\(delegate.changes)")
        
        XCTAssertEqual(data.count, 3)
        
        if delegate.changes.count == 9 {
            XCTAssertEqual(delegate.changes[0], "add <0,0>")
            XCTAssertEqual(delegate.changes[1], "add <0,0>")
            XCTAssertEqual(delegate.changes[2], "add <2,0>")
            
            XCTAssertEqual(delegate.changes[3], "remove <0,0>")
            
            XCTAssertEqual(delegate.changes[4], "add <2,0>")
            
            XCTAssertEqual(delegate.changes[5], "remove <2,0>")
            XCTAssertEqual(delegate.changes[6], "add <2,0>")
            
            XCTAssertEqual(delegate.changes[7], "remove <2,0>")
            XCTAssertEqual(delegate.changes[8], "add <0,0>")
        } else {
            XCTAssert(false, "should have 10 changes but was \(delegate.changes.count)")
        }
        
//        data.query.order = { $1.created > $0.created }
    }
    
    // MARK: - Relationships - TODO

//    func testBelongsToRelation() {
//        
//    }
//    
//    func testHasOneToRelation() {
//        
//    }
//    
//    func testHasManyToRelation() {
//        
//    }
//    
//    func testImplicitRelation() {
//        
//    }
//    
//    func testExplicitRelation() {
//        
//    }
    
    // MARK: - Indexes
    
    func testSecondaryIndexFind() {

        let example = TestModel(uid: "doesn't matter")
        store.index(example) { model in // this block is called initially to help build index and then later on saving to index the real values
            return [
                Index(key: "uid", value: model.uid),
                Index(key: "enabled", value: model.enabled)
            ]
        }
        
        store.add(TestModel(uid: "unique", enabled: true))
        
        var unique: TestModel? = store.find("enabled", value: true) // Use an index if it exists, which in this case it does
        XCTAssertNotNil(unique, "Should have found the object using the secondary index")
    }
    
    func testSecondaryIndexWhere() {
        
        let example = TestModel(uid: "doesn't matter")
        store.index(example) { model in
            return [
                Index(key: "uid", value: model.uid),
                Index(key: "enabled", value: model.enabled)
            ]
        }
        
        store.add(TestModel(uid: "unique1", enabled: true))
        store.add(TestModel(uid: "unique2", enabled: true))
        store.add(TestModel(uid: "unique3", enabled: false))
        store.add(TestModel(uid: "unique4", enabled: false))
        
        var enabled: [TestModel] = store.filter("enabled", value: true)
        XCTAssertEqual(enabled.count, 2)
    }

    
    // MARK: - Private
    
    func waitFor(name: String, timeout: NSTimeInterval = 1) {
        let expectation = expectationWithDescription(name)
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(timeout)), dispatch_get_main_queue(), { () -> () in
            expectation.fulfill()
        })
        waitForExpectationsWithTimeout(timeout, handler: nil)
    }
    
    class TableViewDelegate : DataDelegate {
        
        var updates = 0
        var changes = [String]()
        
        func beginUpdates() {
            updates++
        }
        
        func endUpdates() {
            updates--
        }
        
        func objectAdded(indexPaths: [NSIndexPath]) {
            for indexPath in indexPaths {
                changes.append("add <\(indexPath.row),\(indexPath.section)>")
            }
        }
        
        func objectRemoved(indexPaths: [NSIndexPath]) {
            for indexPath in indexPaths {
                changes.append("remove <\(indexPath.row),\(indexPath.section)>")
            }
        }
        
        func objectUpdated(indexPaths: [NSIndexPath]) {
            for indexPath in indexPaths {
                changes.append("update <\(indexPath.row),\(indexPath.section)>")
            }
        }
        
    }
}
