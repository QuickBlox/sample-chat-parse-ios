//
//  UsersSearchResultsController.swift
//  sample-chat-parse
//
//  Created by Gleb Ustimenko on 05.10.15.
//  Copyright © 2015 quickblox. All rights reserved.
//

import Foundation

class UsersSearchResultsController : UITableViewController {
    
    var users : [QBUUser] = []
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return users.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        var cell = tableView.dequeueReusableCellWithIdentifier("Cell")
        
        if (cell == nil) {
            cell = UITableViewCell(style: UITableViewCellStyle.Default, reuseIdentifier: "Cell")
        }
        
        let user = self.users[indexPath.row]
        cell?.textLabel?.text = user.login
        
        return cell!
    }
}