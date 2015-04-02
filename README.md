# Data

[![Build Status](https://travis-ci.org/DanBrooker/Data.svg?branch=master)](https://travis-ci.org/DanBrooker/Data)

Data is a Swift framework for working with data models.
> It uses YapDatabase and not CoreData

It aims to have the following attributes:
* Threadsafe
* Typesafe
* Tested
* Uses protocols not subclasses

# Getting started

## Cocoapods

```ruby
platform :ios, '8.0'
use_frameworks!

pod 'Data', git: 'https://github.com/DanBrooker/Data'
```

## Carthage

Not yet, just waiting on YapDatabase to have a framework target
https://github.com/yapstudios/YapDatabase/issues/152

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

You can also just store arbitrary key-values
```swift
// Set
store.setObjectForKey(object, forKey:"key")
// Get
let object : ObjectType = store.objectForKey("key")
```

# TODO

* Relationships (Delete rules)
* Secondary indexes for performance
* Full text search
* Metadata helpers for things like caching table row height
* Tableview sections with Data<>
* Data syncing - CloudKit, Dropbox ...

# License

Data.swift is released under an MIT license. See LICENSE for more information.
