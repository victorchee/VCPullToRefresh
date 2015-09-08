//
//  WaterDropLoadViewController.swift
//  VCPullToRefresh
//
//  Created by qihaijun on 9/1/15.
//  Copyright (c) 2015 VictorChee. All rights reserved.
//

import UIKit

class WaterDropLoadViewController: UITableViewController {
    var data = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        self.tableView.addPullToRefreshWithActionHandler { () -> Void in
            delay(1.5) {
                self.data.insert(self.data.first! - 1, atIndex: 0)
                self.tableView.reloadData()
                
                self.tableView.stopPullToRefresh()
            }
        }
//        self.tableView.triggerPullToRefresh()
        
        self.tableView.addPullToLoadWithActionHandler { () -> Void in
            delay(1.5) {
                self.data.append(self.data.last! + 1)
                self.tableView.reloadData()
                
                self.tableView.stopPullToLoad()
            }
        }
//        self.tableView.triggerPullToLoad()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK - table view datasource
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath) as! UITableViewCell
        cell.textLabel?.text = "\(data[indexPath.row])";
        return cell
    }
}
