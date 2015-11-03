//
//  GroupChatUsersInfo.swift
//  sample-chat-swift
//
//  Created by Anton Sokolchenko on 4/14/15.
//  Copyright (c) 2015 quickblox. All rights reserved.
//


class ChatUsersInfoTableViewController: UITableViewController, QMChatServiceDelegate, QMChatConnectionDelegate {
    
    var occupantIDs : [UInt] = []
    var users : [QBUUser] = []
    
    var dialog: QBChatDialog?
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        ServicesManager.instance().chatService.addDelegate(self)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        self.occupantIDs.removeAll()
        
        for occupantID in dialog!.occupantIDs! {
            
            if (UInt(occupantID.unsignedIntegerValue) == ServicesManager.instance().currentUser().ID) {
                continue
            }
            
            self.occupantIDs.append(UInt(occupantID))
        }
        
        ServicesManager.instance().usersService.retrieveUsersWithIDs(self.occupantIDs).continueWithBlock {[unowned self] (task : BFTask!) -> AnyObject! in
            
            let users : [QBUUser] = task.result as! [QBUUser]
            
            for user in users {
                self.users.append(user)
            }
            
            self.tableView.reloadData()
            
            return nil
        }
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return self.users.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCellWithIdentifier("UserTableViewCellIdentifier", forIndexPath: indexPath) as! UserTableViewCell
        
        let user : QBUUser = self.users[indexPath.row]
        
        cell.userDescription = user.login
        
        return cell
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "SA_STR_SEGUE_GO_TO_SELECT_OPPONENTS".localized {
            if let newDialogViewController = segue.destinationViewController as? NewDialogViewController {
                newDialogViewController.dialog = self.dialog
            }
        }
    }
    
    func chatService(chatService: QMChatService!, didUpdateChatDialogInMemoryStorage chatDialog: QBChatDialog!) {
        if (chatDialog.ID == self.dialog!.ID) {
            self.dialog = chatDialog
            self.tableView.reloadData()
        }
    }
    
}
