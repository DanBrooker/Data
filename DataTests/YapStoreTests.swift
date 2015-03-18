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
    
    init(uid: String) {
        self.uid = uid
    }
    
    required init(coder aDecoder: NSCoder) {
        uid = aDecoder.decodeObjectForKey("uid") as String
    }
    
    func encodeWithCoder(aCoder: NSCoder) {
        aCoder.encodeObject(uid, forKey: "uid")
    }
}

func ==(lhs: TestModel, rhs: TestModel) -> Bool {
    return lhs.uid == rhs.uid
}

class YapStoreTests: XCTestCase {
    
    var i = 0

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        store.truncate(TestModel.self)
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
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
        
        let limitQuery = Query<TestModel>(limit: 10)
        let limited = store.query(limitQuery)
        
        XCTAssert(limited.count == 10, "Should have 10 model objects but was \(limited.count))")
        
        let filterQuery = Query<TestModel>(filter: {
            return $0.uid.hasPrefix("find")
        })
        let filtered = store.query(filterQuery)
        
        XCTAssert(filtered.count == 10, "Should have 10 model objects but was \(filtered.count))")
        
        let filterLimitedQuery = Query<TestModel>(limit: 5, filter: {
            return $0.uid.hasPrefix("find")
        })
        let filteredLimited = store.query(filterLimitedQuery)
        
        XCTAssert(filteredLimited.count == 5, "Should have 5 model objects but was \(filteredLimited.count))")
    }
   
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
        
        XCTAssert(store.count(TestModel.self) == 1, "Should have only 1 model but was \(store.count(TestModel.self))")
        
    }
    
    //    func truncate<T: Model>(klass: T.Type)
    func testTruncate() {
        let object = TestModel(uid: "test-update")
        
        store.add(object)
        XCTAssert(store.count(TestModel.self) == 1, "Should have only 1 model but was \(store.count(TestModel.self))")
        
        store.truncate(TestModel.self)
        
        XCTAssert(store.count(TestModel.self) == 0, "Should have only 0 models but was \(store.count(TestModel.self))")
    }
}
