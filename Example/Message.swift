//
//  Message.swift
//  Data
//
//  Created by Daniel Brooker on 20/03/15.
//  Copyright (c) 2015 Nocturnal Code. All rights reserved.
//

import Foundation
import Data

func generateUID() -> String {
    var counter = UserDefaults.standard.integer(forKey: "generateCounter")
    counter += 1
    UserDefaults.standard.set(counter, forKey: "generateCounter")
    return "<0x\(counter)>"
}

class Message : Model {

    let uid: String
    var text: String
    
    init(text: String) {
        self.text = text
        self.uid = generateUID()
    }
    
//    required init(coder aDecoder: NSCoder) {
//        self.uid = aDecoder.decodeObjectForKey("uid") as! String
//        self.text = aDecoder.decodeObjectForKey("text") as! String
//    }
//    
//    func encodeWithCoder(aCoder: NSCoder) {
//        aCoder.encodeObject(uid, forKey: "uid")
//        aCoder.encodeObject(text, forKey: "text")
//    }
    required init(archive: [String: AnyObject]) {
        self.uid = archive["uid"] as! String
        self.text = archive["text"] as! String
    }
    
    var archive : [String: AnyObject] {
        return [
            "uid": uid as AnyObject,
            "text": text as AnyObject
        ]
    }
    
}

func ==(lhs: Message, rhs: Message) -> Bool {
    return lhs.uid == rhs.uid
}
