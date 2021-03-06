//
//  DialogsTableViewController.swift
//  sample-chat-swift
//
//  Created by Anton Sokolchenko on 4/1/15.
//  Copyright (c) 2015 quickblox. All rights reserved.
//

import UIKit

class DialogTableViewCellModel: NSObject {
    
    var detailTextLabelText: String = ""
    var textLabelText: String = ""
    var unreadMessagesCounterLabelText : String?
    var unreadMessagesCounterHiden = true
    var dialogIcon : UIImage?

    init(dialog: QBChatDialog) {
        super.init()
        
        if dialog.type == .Private {
            
            self.detailTextLabelText = "SA_STR_PRIVATE".localized
            
            if dialog.recipientID == -1 {
                return
            }
            
            // Getting recipient from users service.
            if let recipient = ServicesManager.instance().usersService.usersMemoryStorage.userWithID(UInt(dialog.recipientID)) {
                self.textLabelText = recipient.login ?? recipient.email!
            }
            
        } else if dialog.type == .Group {
            self.detailTextLabelText = "SA_STR_GROUP".localized
        } else {
            self.detailTextLabelText = "SA_STR_PUBLIC_GROUP".localized
        }
        
        if self.textLabelText.isEmpty {
            // group chat
            
            if let dialogName = dialog.name {
                self.textLabelText = dialogName
            }
        }
        
        // Unread messages counter label
        
        if (dialog.unreadMessagesCount > 0) {
            
            var trimmedUnreadMessageCount : String
            
            if dialog.unreadMessagesCount > 99 {
                trimmedUnreadMessageCount = "99+"
            } else {
                trimmedUnreadMessageCount = String(format: "%d", dialog.unreadMessagesCount)
            }
            
            self.unreadMessagesCounterLabelText = trimmedUnreadMessageCount
            self.unreadMessagesCounterHiden = false
            
        } else {
            
            self.unreadMessagesCounterLabelText = nil
            self.unreadMessagesCounterHiden = true
        }
        
        // Dialog icon
        
        if dialog.type == .Private {
            self.dialogIcon = UIImage(named: "user")
        } else {
            self.dialogIcon = UIImage(named: "group")
        }
    }
}

class DialogsViewController: UITableViewController, QMChatServiceDelegate, QMChatConnectionDelegate, QMUsersServiceDelegate {
    
    // MARK: - ViewController overrides
    
    override func viewDidLoad() {

        self.navigationItem.leftBarButtonItem = self.createLogoutButton()

        ServicesManager.instance().chatService.addDelegate(self)
        ServicesManager.instance().usersService.addDelegate(self)
        
        NSNotificationCenter.defaultCenter().addObserverForName(UIApplicationDidBecomeActiveNotification, object: nil, queue: NSOperationQueue.mainQueue()) { (notification: NSNotification) -> Void in
            
            if ServicesManager.instance().isAuthorized() && !QBChat.instance().isConnected() {
                SVProgressHUD.showWithStatus("SA_STR_CONNECTING_TO_CHAT".localized, maskType: SVProgressHUDMaskType.Clear)
            }
        }
        
        if (QBChat.instance().isConnected()) {
            self.getDialogs()
        }
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        if ServicesManager.instance().isAuthorized() {
            
            self.navigationItem.title = "SA_STR_WELCOME".localized + " " + ServicesManager.instance().currentUser()!.login!
            
        } else {
            
            SVProgressHUD.showWithStatus("Connecting", maskType:SVProgressHUDMaskType.Clear)
            if SessionService.isCanRestoreSession() {
                
                SessionService.restoreSession({ [unowned self] (error) -> Void in
                    if (error != nil) {
                        SVProgressHUD.showErrorWithStatus(error?.localizedDescription)
                        self.performSegueWithIdentifier("goToAuth", sender: nil)
                    } else {
                        self.navigationItem.title = "SA_STR_WELCOME".localized + " " + ServicesManager.instance().currentUser()!.login!
                    }
                })
                
            } else {
                SVProgressHUD.dismiss()
                self.performSegueWithIdentifier("goToAuth", sender: nil)
            }
            
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "SA_STR_SEGUE_GO_TO_CHAT".localized {
            if let chatVC = segue.destinationViewController as? ChatViewController {
                chatVC.dialog = sender as? QBChatDialog
            }
        }
    }
    
    // MARK: - Actions
    
    func createLogoutButton() -> UIBarButtonItem {
        
        let logoutButton = UIBarButtonItem(title: "SA_STR_LOGOUT".localized, style: UIBarButtonItemStyle.Plain, target: self, action: Selector("logoutAction"))
        
        return logoutButton
    }
    
    @IBAction func logoutAction() {
        
        SVProgressHUD.showWithStatus("SA_STR_LOGOUTING".localized, maskType: SVProgressHUDMaskType.Clear)
        
        let logoutGroup: dispatch_group_t = dispatch_group_create()
        dispatch_group_enter(logoutGroup)
        
        let deviceIdentifier: String = UIDevice.currentDevice().identifierForVendor!.UUIDString
        QBRequest.unregisterSubscriptionForUniqueDeviceIdentifier(deviceIdentifier, successBlock: { (response: QBResponse!) -> Void in
            //
            NSLog("success unsub push")
            dispatch_group_leave(logoutGroup)
            }) { (error: QBError?) -> Void in
                //
                NSLog("push unsub failed")
                dispatch_group_leave(logoutGroup)
        }
        
        ServicesManager.instance().lastActivityDate = nil
        
        dispatch_group_notify(logoutGroup, dispatch_get_main_queue()) {
            [weak self] () -> Void in
            // Logouts from Quickblox, clears cache.
            if let strongSelf = self {
                SessionService.logOut({ (error) -> Void in
                    
                    SVProgressHUD.showSuccessWithStatus("SA_STR_COMPLETED".localized)
                    
                    strongSelf.performSegueWithIdentifier("goToAuth", sender: nil);
                })
            }
        }
}
    
    // MARK: - DataSource Action
    
    func getDialogs() {
        
        if (ServicesManager.instance().lastActivityDate != nil) {
            ServicesManager.instance().chatService.fetchDialogsUpdatedFromDate(ServicesManager.instance().lastActivityDate, andPageLimit: kDialogsPageLimit, iterationBlock: { (response: QBResponse!, dialogObjects: [AnyObject]!, dialogsUsersIDs: Set<NSObject>!, stop: UnsafeMutablePointer<ObjCBool>) -> Void in
                //
                if let usersIDs = Array(dialogsUsersIDs) as? [NSNumber] {
                    ServicesManager.instance().usersService.getUsersWithIDs(usersIDs)
                }
                }, completionBlock: { (response: QBResponse!) -> Void in
                    //
                    if (ServicesManager.instance().isAuthorized() && response.success) {
                        ServicesManager.instance().lastActivityDate = NSDate()
                    }
            })
        }
        else {
            SVProgressHUD.showWithStatus("Loading...", maskType: SVProgressHUDMaskType.Clear)
            ServicesManager.instance().chatService.allDialogsWithPageLimit(kDialogsPageLimit, extendedRequest: nil, iterationBlock: { (response: QBResponse!, dialogObjects: [AnyObject]!, dialogsUsersIDs: Set<NSObject>!, stop: UnsafeMutablePointer<ObjCBool>) -> Void in
                //
                if let usersIDs = Array(dialogsUsersIDs) as? [NSNumber] {
                    ServicesManager.instance().usersService.getUsersWithIDs(usersIDs)
                }
                }, completion: { (response: QBResponse!) -> Void in
                    //
                    if (ServicesManager.instance().isAuthorized()) {
                        if (response.success) {
                            SVProgressHUD.showSuccessWithStatus("Completed")
                            ServicesManager.instance().lastActivityDate = NSDate()
                        }
                        else {
                            SVProgressHUD.showErrorWithStatus("Failed to load dialogs")
                        }
                    }
            })
        }
    }
    
    // MARK: - DataSource
    
    static func dialogs() -> Array<QBChatDialog> {
        
        // Returns dialogs sorted by updatedAt date.
        return ServicesManager.instance().chatService.dialogsMemoryStorage.dialogsSortByUpdatedAtWithAscending(false) as! Array<QBChatDialog>
    }
    
    // MARK: - UITableViewDataSource
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let numberOfRowsInSection = DialogsViewController.dialogs().count
        
        return numberOfRowsInSection
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 64.0
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("dialogcell", forIndexPath: indexPath) as! DialogTableViewCell
        
        let chatDialog = DialogsViewController.dialogs()[indexPath.row]
        
        cell.tag = indexPath.row
        cell.dialogID = chatDialog.ID!
        
        let cellModel = DialogTableViewCellModel(dialog: chatDialog)
        
        cell.dialogLastMessage?.text = chatDialog.lastMessageText
        cell.dialogName?.text = cellModel.textLabelText
        cell.dialogTypeImage.image = cellModel.dialogIcon
        cell.unreadMessageCounterLabel.text = cellModel.unreadMessagesCounterLabelText
        cell.unreadMessageCounterHolder.hidden = cellModel.unreadMessagesCounterHiden
        
        return cell
    }
    
    // MARK: - UITableViewDelegate
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        
        let dialog = DialogsViewController.dialogs()[indexPath.row]
        self.performSegueWithIdentifier("SA_STR_SEGUE_GO_TO_CHAT".localized , sender: dialog)
    }
    
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        
        if (editingStyle == UITableViewCellEditingStyle.Delete) {
            
            let dialog = DialogsViewController.dialogs()[indexPath.row]
            
            _ = AlertView(title:"SA_STR_WARNING".localized , message:"SA_STR_DO_YOU_REALLY_WANT_TO_DELETE_SELECTED_DIALOG".localized , cancelButtonTitle: "SA_STR_CANCEL".localized, otherButtonTitle: ["SA_STR_DELETE".localized], didClick:{ (buttonIndex) -> Void in
                
                if buttonIndex != 1 {
                    return
                }
                
                SVProgressHUD.showWithStatus("SA_STR_DELETING".localized, maskType: SVProgressHUDMaskType.Clear)
                
                let deleteDialogBlock = { (dialog: QBChatDialog!) -> Void in
                    
                    // Deletes dialog from server and cache.
                    ServicesManager.instance().chatService.deleteDialogWithID(dialog.ID, completion: { (response: QBResponse!) -> Void in
                        
                        if response.success {
                            
                            SVProgressHUD.showSuccessWithStatus("SA_STR_DELETED".localized)
                            
                        } else {
                            
                            SVProgressHUD.showErrorWithStatus("SA_STR_ERROR_DELETING".localized)
                            print(response.error?.error)
                        }
                    })
                }
                
                if dialog.type == QBChatDialogType.Private {
                    
                    deleteDialogBlock(dialog)
                    
                } else {
                    
                    let occupantIDs =  dialog.occupantIDs!.filter( {$0 != ServicesManager.instance().currentUser().ID} )
                    
                    dialog.occupantIDs = occupantIDs
                    
                    // Notifies occupants that user left the dialog.
                    ServicesManager.instance().chatService.sendMessageAboutUpdateDialog(dialog, withNotificationText: "User \(ServicesManager.instance().currentUser().login!) has left the dialog", customParameters: nil, completion: { (error: NSError?) -> Void in
                        deleteDialogBlock(dialog)
                    })
                }
            })
        }
    }
    
    override func tableView(tableView: UITableView, titleForDeleteConfirmationButtonForRowAtIndexPath indexPath: NSIndexPath) -> String? {
        return "SA_STR_DELETE".localized
    }
    
    // MARK: - QMChatServiceDelegate
    
    func chatService(chatService: QMChatService!, didUpdateChatDialogInMemoryStorage chatDialog: QBChatDialog!) {
        self.tableView.reloadData()
    }
    
    func chatService(chatService: QMChatService!, didAddChatDialogsToMemoryStorage chatDialogs: [AnyObject]!) {
        
        for dialog : QBChatDialog in chatDialogs as! [QBChatDialog] {
            
            // Performing join to the group dialogs.
            if dialog.type != QBChatDialogType.Private {
                ServicesManager.instance().chatService.joinToGroupDialog(dialog, completion: { (error: NSError?) -> Void in
                    if (error != nil) {
                        NSLog("Failed to join dialog with error: %@", error!)
                    }
                })
            }
        }
        
        self.tableView.reloadData()
    }
    
    func chatService(chatService: QMChatService!, didAddChatDialogToMemoryStorage chatDialog: QBChatDialog!) {
        ServicesManager.instance().usersService.getUsersWithIDs(chatDialog.occupantIDs)
        self.tableView.reloadData()
    }
    
    func chatService(chatService: QMChatService!, didDeleteChatDialogWithIDFromMemoryStorage chatDialogID: String!) {
        self.tableView.reloadData()
    }
    
    func chatService(chatService: QMChatService!, didAddMessagesToMemoryStorage messages: [AnyObject]!, forDialogID dialogID: String!) {
        self.tableView.reloadData()
    }
    
    func chatService(chatService: QMChatService!, didAddMessageToMemoryStorage message: QBChatMessage!, forDialogID dialogID: String!) {
        self.tableView.reloadData()
    }
    
    // MARK: QMUsersServiceDelegate
    
    func usersService(usersService: QMUsersService!, didAddUsers user: [QBUUser]!) {
        self.tableView.reloadData()
    }
    
    // MARK: QMChatConnectionDelegate
    
    func chatServiceChatDidAccidentallyDisconnect(chatService: QMChatService!) {
        SVProgressHUD.showErrorWithStatus("SA_STR_DISCONNECTED".localized)
    }
    
    func chatServiceChatDidConnect(chatService: QMChatService!) {
        SVProgressHUD.showSuccessWithStatus("SA_STR_CONNECTED".localized)
        self.getDialogs()
    }
    
    func chatServiceChatDidNotLoginWithError(error: NSError!) {
        SVProgressHUD.showErrorWithStatus(error.localizedDescription)
    }
    
    func chatServiceChatDidReconnect(chatService: QMChatService!) {
        SVProgressHUD.showSuccessWithStatus("SA_STR_RECONNECTED".localized)
        self.getDialogs()
    }
}
