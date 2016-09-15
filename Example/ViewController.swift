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
    
//    var data : Data<Message>?
    var searchController: UISearchController!
    
    @IBOutlet
    var tableView: UITableView!
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.searchController = UISearchController(searchResultsController: nil)
        self.searchController.searchResultsUpdater = self
        self.searchController.searchBar.delegate = self
        
        self.tableView.tableHeaderView = searchController.searchBar
        searchController.searchBar.sizeToFit()
        
        self.definesPresentationContext = true
    }

//    override func viewDidAppear(animated: Bool) {
//        data = Data(query: Query<Message>(), store: store)
//
//        if let data = data {
//            data.delegate = self
//            
//            var text = ["Message 1", "Message 2", "Message 3", "Message 4", "Message 5", "Message 6", "Message 7"]
//            var messages = text.map({ Message(text: $0) })
//            data.appendAll(messages)
//        }
//    }

}

extension ViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//        return data?.numberOfRowsInSection(section) ?? 0
        return 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) 
//        let message : Message? = data?[indexPath]
//        if let message = message, label = cell.textLabel  {
//            label.text = message.text
//        }
        return cell
    }
    
}

extension ViewController: UITableViewDelegate {
    
    private func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: IndexPath) -> Bool {
        return true
    }
    
    private func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if (editingStyle == .delete) {
//            data?.removeAtIndexPath(indexPath)
        }
    }
    
}

//extension ViewController: DataDelegate {
//
//    func beginUpdates() {
//        tableView.beginUpdates()
//    }
//    
//    func endUpdates() {
//        tableView.endUpdates()
//        if let count = data?.count {
//            self.navigationItem.title = "Data (\(count))"
//        }
//    }
//    
//    func objectAdded(indexPaths: [NSIndexPath]) {
//        tableView.insertRowsAtIndexPaths(indexPaths, withRowAnimation: .Automatic)
//    }
//    
//    func objectRemoved(indexPaths: [NSIndexPath]) {
//        tableView.deleteRowsAtIndexPaths(indexPaths, withRowAnimation: .Automatic)
//    }
//    
//    func objectUpdated(indexPaths: [NSIndexPath]) {
//        tableView.reloadRowsAtIndexPaths(indexPaths, withRowAnimation: .Automatic)
//    }
//
//}

extension ViewController : UISearchResultsUpdating {
    public func updateSearchResults(for searchController: UISearchController) {
        
    }
    
}

extension ViewController: UISearchBarDelegate {
    
}

