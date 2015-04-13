//
//  ViewController.swift
//  Example
//
//  Created by Daniel Brooker on 17/03/15.
//  Copyright (c) 2015 Nocturnal Code. All rights reserved.
//

import UIKit
import Data

class ViewController: UIViewController {
    
    var data : Data<Message>?
    
    @IBOutlet var tableView: UITableView!
    
    required init(coder aDecoder: NSCoder) {
        
        super.init(coder: aDecoder)
        
    }

//    override func viewDidLoad() {
//        super.viewDidLoad()

    override func viewDidAppear(animated: Bool) {
    
        data = Data(query: Query<Message>(), store: store)
        tableView.reloadData()
        if let data = data {
            data.delegate = self
            
            // Do any additional setup after loading the view, typically from a nib.
            var text = ["Message 1", "Message 2", "Message 3", "Message 4", "Message 5", "Message 6", "Message 7"]
            var messages = text.map({ Message(text: $0) })
            data.appendAll(messages)
        }
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
}

extension ViewController: UITableViewDataSource {
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data?.numberOfRowsInSection(section) ?? 0
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("cell", forIndexPath: indexPath) as! UITableViewCell
        let message : Message? = data?[indexPath]
        if let message = message {
            if let label = cell.textLabel {
                println("\(message.text)")
                label.text = message.text
            }
        }
        return cell
    }
    
}

extension ViewController: UITableViewDelegate {
    
    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if (editingStyle == .Delete) {
            data?.removeAtIndexPath(indexPath)
        }
    }
    
}

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

