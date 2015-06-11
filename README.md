# Data

[![Build Status](https://travis-ci.org/DanBrooker/Data.svg?branch=master)](https://travis-ci.org/DanBrooker/Data)
See issue

Data is a Swift (1.2) framework for working with data models.
> It uses YapDatabase and not CoreData

It aims to have the following attributes:
* Threadsafe
* Typesafe
* Tested
* Protocols not Inheritance

# Getting started

## Cocoapods

```ruby
platform :ios, '8.0'
use_frameworks!

pod 'Data', git: 'https://github.com/DanBrooker/Data'
```

## Carthage

YapDatabase now has a framework, this needs to be tested

## Setup

Import Data module
``` swift
import Data
```

> Models must conform to Data.Model which includes NSCoding and a uid:String property


``` swift
class YourModel : NSObject : Data.Model {
  let uid: String   // Required property

  init() {
    self.uid = "A UID OF YOUR CHOOSING"
  }

  required init(coder aDecoder: NSCoder) {
    self.uid = aDecoder.decodeObjectForKey("uid") as String
    //....
  }

  func encodeWithCoder(aCoder: NSCoder) {
    aCoder.encodeObject(uid, forKey: "uid")
    //.....
  }
}
```

# Basics

Created a data store
``` swift
let store = YapStore()
```

## Add
``` swift
let model = YourModel()
store.append(model)
```

## Find
``` swift
let model: YourModel = store.find(modelsUID)
```

## Filter
``` swift
let models: [YourModel] =  store.filter({ $0.someProperty > 0 })
```

## All
``` swift
let models: [YourModel] =  store.all()
```
## Count
``` swift
let count =  store.count(YourModel.self)
```

## Update

> Update is important because your object is not being observed for changes and therefore once your done changing a object you will need to save it

``` swift
store.update(model)
```

## Delete
``` swift
store.remove(model)
```

## Delete all
``` swift
store.truncate(YourModel.self)
```

# Next step

Now that you've got the basics

## Querying

```swift
public struct Query<T : Model> {
  let filter: ( (element: T) -> Bool )?
  let window: Range<Int>?
  let order: ( (a: T, b: T) -> Bool )?
}
```

A simple query for all YourModel objects
```swift
let query = Query<YourModel>()
```

A more complex query
> Filter models based on enabled being true, limited to the first 20 elements and ordered by property

```swift
let query = Query<YourModel>(
    filter: { $0.enabled == true },
    window: 0..<20,
    order:  { $0.property > $1.property }
  )
```

## Notifications
Options:

a) You can observe the following notifications for changes
* "dataStoreAdded"
> Not actually called yet, cannot distinguish between modified and added currently

* "dataStoreModified"
* "dataStoreRemoved"

b) And this is the best option use `Data<T>` collections

## Collections

`Data<T>` is a drop in replacement for Array<T> with the added benefit of being persistent and automatically updating when someone changes an object in the underlying data store

```swift
let query = Query<YourModel>()
let data: Data<YourModel> = Data(query: query, store: store)
```

See querying above for more information about populating `Data<T>` with a query

### Tableview helpers

`Data<T>` has a delegate `DataDelegate` and it generates some very useful callbacks for `UITableView`s

```swift
extension ViewController: DataDelegate {

    func beginUpdates() {
        tableView.beginUpdates()
    }

    func endUpdates() {
        tableView.endUpdates()
    }

    func objectAdded(indexPaths: [NSIndexPath]) {
        tableView.insertRowsAtIndexPaths(indexPaths, withRowAnimation: .Automatic)
    }

    func objectRemoved(indexPaths: [NSIndexPath]) {
        tableView.deleteRowsAtIndexPaths(indexPaths, withRowAnimation: .Automatic)
    }

    func objectUpdated(indexPaths: [NSIndexPath]) {
        tableView.reloadRowsAtIndexPaths(indexPaths, withRowAnimation: .Automatic)
    }

}
```

## Key-Value Store

YapDatabase is actually a key-value store, or more correctly a hash of hashes.

You can therefore just store arbitrary key-values if you need to
```swift
// Set
store.setObjectForKey(object, forKey:"key")
// Get
let object : ObjectType = store.objectForKey("key")
```

## Indexes - WIP

> Basic indexes are working but the API is not solidified yet
> Aggregate index `filter`ing not yet supported

Setup Indexes, once per model
```swift
let example = TestModel(uid: "doesn't matter")
store.index(example) { model in
    return [
        Index(key: "uid", value: model.uid),
        Index(key: "enabled", value: model.enabled)
    ]
}
```
> Indexable types String, Int Double, Float, Bool

### Find

```swift
var unique: TestModel? = store.find("enabled", value: true)
```

### Filter

```swift
var enabled: [TestModel] = store.filter("enabled", value: true)
```

### Search

sqlite full text search. [reference](http://www.sqlite.org/fts3.html#section_1_4)

> You need to setup indexes to use search. Only searches **TEXT** columns

```swift
let example = Tweet(uid: "doesn't matter", text: "also doesn't matter", authorName: "anon")
    store.index(example) { tweet in
        return [
            Index(key: "text", value: tweet.text),
            Index(key: "authorName", value: tweet.authorName)
        ]
    }
```

Search using various methods
```swift
var results : [Tweet] = store.search(string: "yapdatabase")                 // Basic Keyword Search
    results           = store.search(phrase: "yapdatabase is good")         // Exact Phrase
    results           = store.search(string: "authorName:draconisNZ")       // Only Search Property
    results           = store.search(string: "^yap")                        // Starts with
    results           = store.search(string: "yap*"                         // Wildcard
    results           = store.search(string: "'yapdatabase OR yapdatabse'") // OR
    results           = store.search(string: "'tweet NOT storm'")           // NOT
    results           = store.search(string: "'tweet NEAR/2 storm'")        // Keywords are with '2' tokens of each other
```

# TODO

* Secondary index aggregation i.e. OR and AND
* Search snippets and return results across models if required
* Relationships (Delete rules)
* Metadata helpers for things like caching table row height
* Tableview sections with Data<>
* Data syncing - CloudKit, Dropbox ...

# License

Data.swift is released under an MIT license. See LICENSE for more information.
