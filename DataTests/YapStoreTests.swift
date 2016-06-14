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

class TestModel : Model {
    
    let uid: String
    let enabled: Bool
    
    init(uid: String, enabled: Bool = true) {
        self.uid = uid
        self.enabled = enabled
    }
    
    required init(archive: Archive) {
        self.uid = archive["uid"] as! String
        self.enabled = archive["enabled"] as! Bool
    }
    
    var archive : Archive {
        return [
            "uid": uid,
            "enabled": enabled
        ]
    }
    
    func indexes() -> [Index] {
        return [
            Index(key: "enabled", value: enabled)
        ]
    }
}

func ==(lhs: TestModel, rhs: TestModel) -> Bool {
    return lhs.uid == rhs.uid
}

struct Tweet : Model {
    let uid: String
    let text: String
    let authorName: String
    
    init(uid: String, text: String, authorName: String) {
        self.uid = uid
        self.text = text
        self.authorName = authorName
    }
    
    init(archive: Archive) {
        self.uid = archive["uid"] as! String
        self.text = archive["text"] as! String
        self.authorName = archive["authorName"] as! String
    }
    
    var archive : Archive {
        return [
            "uid": uid,
            "text": text,
            "authorName": authorName
        ]
    }
    
    func indexes() -> [Index] {
        return [
            Index(key: "text", value: text),
            Index(key: "authorName", value: authorName)
        ]
    }
}


func ==(lhs: Tweet, rhs: Tweet) -> Bool {
    return lhs.uid == rhs.uid
}

class TestB : Model {
    let uid: String
    
    init(uid: String) {
        self.uid = uid
    }
    
    required init(archive: [String: AnyObject]) {
        self.uid = archive["uid"] as! String
    }
    
    var archive : [String: AnyObject] {
        return [
            "uid": uid
        ]
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
        store.truncate(Tweet.self)
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
        
        if let _ : TestModel = store.find("test-5") {
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
        let data = Collection<TestModel>(query: query, store: store)
        
        data.append(TestModel(uid: "test-data-add"))
        
        XCTAssert(data.count == 1, "Should have only 1 model but was \(data.count)")
        XCTAssert(store.count(TestModel.self) == 1, "Should have 1 model but was \(store.count(TestModel.self))")
    }
    
    func testDataBackgroundAdd() {
        
        let query = Query<TestModel>()
        let data = Collection<TestModel>(query: query, store: store)
        
        store.add(TestModel(uid: "test-data-add"))
        
        waitFor("Background Thread")
        
        XCTAssert(store.count(TestModel.self) == 1, "Should have only 1 model but was \(store.count(TestModel.self))")
        XCTAssert(data.count == 1, "Should have 1 model but was \(data.count)")
    }
    
    func testDataBackgroundRemove() {
        
        let query = Query<TestModel>()
        let data = Collection<TestModel>(query: query, store: store)
        
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
        let data = Collection<TestModel>(query: query, store: store)
        
        let delegate = TableViewDelegate()
        
        data.delegate = delegate
        
        let zero = TestModel(uid: "0")
        
        data.append(zero)
        waitFor("delegate added")
        
        store.update(zero)
        waitFor("delegate updated")
        
        data.removeAtIndex(0)
        waitFor("delegate removed")
        
        print("\(delegate.changes)")
        
        if delegate.changes.count == 3 {
            XCTAssertEqual(delegate.changes[0], "add <0,0>", "")
            XCTAssertEqual(delegate.changes[1], "update <0,0>", "")
            XCTAssertEqual(delegate.changes[2], "remove <0,0>", "")
        } else {
            XCTAssert(false, "should have 3 changes but was \(delegate.changes.count)")
        }
        
    }
    
    func testSortedTableViewDelegate() {
        
        let query = Query<TestModel>(window: 0...2, order: {  Int($0.uid) < Int($1.uid) })
        let data = Collection<TestModel>(query: query, store: store)
        
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
        
        print("\(delegate.changes)")
        
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
//        store.index(example) { model in // this block is called initially to help build index and then later on saving to index the real values
//            return [
//                Index(key: "uid", value: model.uid),
//                Index(key: "enabled", value: model.enabled)
//            ]
//        }
        store.index(example)
        
        store.add(TestModel(uid: "unique", enabled: true))
        
        let unique: TestModel? = store.find("enabled", value: true) // Use an index if it exists, which in this case it does
        XCTAssertNotNil(unique, "Should have found the object using the secondary index")
    }
    
    func testSecondaryIndexWhere() {
        
        let example = TestModel(uid: "doesn't matter")
        store.index(example)
        
        store.add(TestModel(uid: "unique1", enabled: true))
        store.add(TestModel(uid: "unique2", enabled: true))
        store.add(TestModel(uid: "unique3", enabled: false))
        store.add(TestModel(uid: "unique4", enabled: false))
        
        let enabled: [TestModel] = store.filter("enabled", value: true)
        XCTAssertEqual(enabled.count, 2)
    }
    
    // MARK - Search
    
    func tweetIndex() {
        let example = Tweet(uid: "doesn't matter", text: "also doesn't matter", authorName: "anon")
        store.index(example)// { tweet in
//            return [
//                Index(key: "text", value: tweet.text),
//                Index(key: "authorName", value: tweet.authorName)
//            ]
//        }
        
    }
    
    func testSearchContainsWord() {
        tweetIndex()
        
        store.add(Tweet(uid: "12345", text: "this is a tweet about yap database", authorName: "draconisNZ"))
        store.add(Tweet(uid: "12346", text: "this is a tweet about yapdatabase", authorName: "draconisNZ"))
        
        let results : [Tweet] = store.search(string: "yapdatabase")
        XCTAssertEqual(results.count, 1)
    }
    
    func testSearchContainsPhrase() {
        tweetIndex()
        
        store.add(Tweet(uid: "12345", text: "this is a tweet about yapdatabase", authorName: "draconisNZ"))
        store.add(Tweet(uid: "12346", text: "this is a tweet storm about yapdatabase", authorName: "draconisNZ"))
        
        var results: [Tweet] = store.search(phrase: "tweet about")
        XCTAssertEqual(results.count, 1)
        
        results = store.search(string: "\"tweet about\"") // Alternate
        XCTAssertEqual(results.count, 1)
    }
    
    func testSearchKeyContainsWord() {
        tweetIndex()
        
        store.add(Tweet(uid: "12345", text: "@draconisNZ yapdatabase", authorName: "twitter"))
        store.add(Tweet(uid: "12346", text: "this is a tweet about yapdatabase", authorName: "draconisNZ"))
        
        let results: [Tweet] = store.search(string: "authorName:draconisNZ")
        XCTAssertEqual(results.count, 1)
    }
    
    func testSearchBeginsWith() {
        tweetIndex()
        
        store.add(Tweet(uid: "12345", text: "draconisNZ yapdatabase", authorName: "twitter"))
        store.add(Tweet(uid: "12346", text: "this is a tweet about yapdatabase", authorName: "draconisNZ"))
        store.add(Tweet(uid: "12347", text: "something draconisNZ something something", authorName: "darkside"))
        
        let results: [Tweet] = store.search(string: "^draconisNZ")
        XCTAssertEqual(results.count, 2) // Matches text (12345) and authorName (12346)
        
    }
    func testSearchWildcard() {
        tweetIndex()
        
        store.add(Tweet(uid: "12345", text: "@draconisNZ yapdatabse", authorName: "twitter"))
        store.add(Tweet(uid: "12346", text: "this is a tweet about yapdatabase", authorName: "draconisNZ"))
        
        let results: [Tweet] = store.search(string: "yap*")
        XCTAssertEqual(results.count, 2)
    }
    
    func testSearchAnd() {
        tweetIndex()
        
        store.add(Tweet(uid: "12345", text: "@draconisNZ yapdatabse tweet", authorName: "twitter"))
        store.add(Tweet(uid: "12346", text: "this is a tweet about yapdatabase", authorName: "draconisNZ"))
        
        let results: [Tweet] = store.search(string: "'tweet AND yapdatabase'")
        XCTAssertEqual(results.count, 1)
    }
    
    func testSearchOr() {
        tweetIndex()
        
        store.add(Tweet(uid: "12345", text: "@draconisNZ yapdatabse", authorName: "twitter"))
        store.add(Tweet(uid: "12346", text: "this is a tweet about yapdatabase", authorName: "draconisNZ"))
        
        let results: [Tweet] = store.search(string: "'yapdatabase OR yapdatabse'")
        XCTAssertEqual(results.count, 2)
    }
    
    func testSearchNot() {
        tweetIndex()
        
        store.add(Tweet(uid: "12345", text: "@draconisNZ yapdatabse", authorName: "twitter"))
        store.add(Tweet(uid: "12346", text: "this is a tweet about yapdatabase", authorName: "draconisNZ"))
        store.add(Tweet(uid: "12347", text: "this is a tweet storm about yapdatabase", authorName: "draconisNZ"))
        
        let results: [Tweet] = store.search(string: "'tweet NOT storm'")
        XCTAssertEqual(results.count, 1)
    }

    func testSearchNear() {
        tweetIndex()
        
        store.add(Tweet(uid: "12345", text: "@draconisNZ tweet and things about yapdatabase twitter storm", authorName: "twitter"))
        store.add(Tweet(uid: "12346", text: "this is a tweet about storm yapdatabase", authorName: "draconisNZ"))
        store.add(Tweet(uid: "12347", text: "this is a tweet storm about yapdatabase", authorName: "draconisNZ"))
        
        let results: [Tweet] = store.search(string: "'tweet NEAR/2 storm'")
        XCTAssertEqual(results.count, 2)
    }
    
    func textSearchAndResultSnippet() {
        
    }

    
    // MARK: - Private
    
    func waitFor(name: String, timeout: NSTimeInterval = 1) {
        let expectation = expectationWithDescription(name)
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(timeout)), dispatch_get_main_queue(), { () -> () in
            expectation.fulfill()
        })
        waitForExpectationsWithTimeout(timeout, handler: nil)
    }
    
    class TableViewDelegate : CollectionDelegate {
        
        var updates = 0
        var changes = [String]()
        
        func beginUpdates() {
            updates += 1
        }
        
        func endUpdates() {
            updates -= 1
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
