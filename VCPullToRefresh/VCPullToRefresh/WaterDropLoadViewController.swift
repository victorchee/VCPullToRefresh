//
//  WaterDropLoadViewController.swift
//  VCPullToRefresh
//
//  Created by qihaijun on 9/1/15.
//  Copyright (c) 2015 VictorChee. All rights reserved.
//

import UIKit

class WaterDropLoadViewController: UITableViewController {

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
            self.delay(1.5) {
                self.tableView.stopPullToRefresh()
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func delay(delay: Double , _ closure:() -> Void) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(delay * Double(NSEC_PER_SEC))), dispatch_get_main_queue(), closure)
    }
}
