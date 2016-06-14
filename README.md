# Data.swift

[![Build Status](https://travis-ci.org/DanBrooker/Data.svg?branch=master)](https://travis-ci.org/DanBrooker/Data)
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
![Cocoapods Compatible](https://img.shields.io/cocoapods/v/Data.swift.svg)
![License](https://img.shields.io/badge/license-MIT-000000.svg)
![Platform](https://img.shields.io/badge/platform-iOS-lightgrey.svg)

Data.swift is a Swift (2.0) framework for working with data models.
> Data.swift is built on the fantastic YapDatabase which is built on Sqlite3

`Swift 1.2 can be found on branch swift1.2`

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

YapDatabase now has a framework, I just need to add it :D

## Setup

Import Data module
``` swift
import Data
```

> Data.Model is simple protocol which requires a uid:String property and a means to archive and unarchive an object

``` swift
class YourModel : Data.Model {
  let uid: String   // Required property

  init() {
    self.uid = "A UID OF YOUR CHOOSING"
  }

  // Required init
  required init(archive: Archive) {
    uid = archive["uid"] as! String
  }

  // Required archive property, [String: AnyObject]
  var archive : Archive {
      return ["uid": uid]
  }
}

struct YourStruct : Data.Model {
  let uid: String   // Required property

  init() {
    self.uid = "A UID OF YOUR CHOOSING"
  }

  // Required init
  init(archive: Archive) {
    uid = archive["uid"] as! String
  }

  // Required archive property, [String: AnyObject]
  var archive : Archive {
      return ["uid": uid]
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

b) And this is the best option use `Collection<T>` collections

## Collections

`Collection<T>` is a drop in replacement for Array<T> with the added benefit of being persistent and automatically updating when someone changes an object in the underlying data store

```swift
let query = Query<YourModel>()
let data: Collection<YourModel> = Data(query: query, store: store)
```

See querying above for more information about populating `Collection<T>` with a query

### Tableview helpers

`Collection<T>` has a delegate `DataDelegate` and it generates some very useful callbacks for `UITableView`s

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
struct TestModel: Data.Model {

  let text: String

  //.. init and archive functions removed for this example

  // function used to index properties
  func indexes() -> [Index] {
      return [
          Index(key: "text", value: text)
      ]
  }
}

let example = TestModel(uid: "doesn't matter")
store.index(example)
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
struct Tweet: Data.Model {

  let text: String
  let authorName: String

  //.. init and archive functions removed for this example

  // function used to index properties
  func indexes() -> [Index] {
      return [
          Index(key: "text", value: text),
          Index(key: "authorName", value: authorName)
      ]
  }
}

let example = Tweet(uid: "doesn't matter", text: "also doesn't matter", authorName: "anon")
store.index(example)
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
    results           = store.search(string: "'tweet NEAR/2 storm'")        // Keywords are within '2' tokens of each other
```

# TODO

* Transactions and mutiple model reads/writes
* Secondary index aggregation i.e. OR and AND
* iOS9 Core Spotlight 
* Query<T> should use indexes
* Relationships (Delete rules), Implicit and Explict

* Search snippets and return results across models if required
* Metadata helpers for things like caching table row height
* Tableview sections with Collection<>, also CollectionView
* Data syncing - CloudKit, Dropbox ...

# License

Data.swift is released under an MIT license. See LICENSE for more information.
