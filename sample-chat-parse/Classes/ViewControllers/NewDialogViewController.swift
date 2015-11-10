 //
//  NewDialogViewController.swift
//  sample-chat-swift
//
//  Created by Anton Sokolchenko on 4/1/15.
//  Copyright (c) 2015 quickblox. All rights reserved.
//


class NewDialogViewController: UITableViewController, QMChatServiceDelegate, QMChatConnectionDelegate, UISearchBarDelegate, UISearchResultsUpdating {
    var dialog: QBChatDialog?
    var users : [QBUUser] = []
    var findedUsers : [QBUUser] = []
    
    var searchController = UISearchController(searchResultsController: UsersSearchResultsController())
    
    @IBOutlet weak var searchUsersLabel: UILabel!
    @IBOutlet weak var selectUsersLabel: UILabel!
    @IBOutlet weak var tableHeaderLine: UIView!
    @IBOutlet weak var tableFooterLine: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.searchController.searchResultsUpdater = self
        self.searchController.dimsBackgroundDuringPresentation = true

        self.searchController.searchBar.delegate = self
        (self.searchController.searchResultsController as! UsersSearchResultsController).tableView.delegate = self
        
        self.tableView.tableHeaderView?.addSubview(self.searchController.searchBar);
        self.definesPresentationContext = true
        
        self.setupUsers()
        
        self.checkCreateChatButtonState()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        ServicesManager.instance().chatService.addDelegate(self)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        self.checkCreateChatButtonState()
    }
    
    func checkCreateChatButtonState() {
        self.navigationItem.rightBarButtonItem?.enabled = tableView.indexPathsForSelectedRows?.count > 0
    }
    
    func updateHeader(usersExists: Bool) {
        self.searchUsersLabel.hidden = usersExists
        self.selectUsersLabel.hidden = !usersExists
        self.tableHeaderLine.hidden = !usersExists
        self.tableFooterLine.hidden = !usersExists
    }
    
    func setupUsers() {
        var filteredUsers = (ServicesManager.instance().usersService.usersMemoryStorage.unsortedUsers() as! [QBUUser]).filter({($0 as QBUUser).ID != ServicesManager.instance().currentUser().ID})
        if let _ = self.dialog {
            self.navigationItem.rightBarButtonItem?.title = "Done"
            self.title = "Add Occupants"
            filteredUsers = filteredUsers.filter({!(self.dialog!.occupantIDs as! [UInt]).contains(($0 as QBUUser).ID)})
            
        } else {
            self.navigationItem.rightBarButtonItem?.title = "Create"
            self.title = "New Chat"
        }
        
        if (filteredUsers.count > 0) {
            self.updateHeader(true)
            self.users = filteredUsers
            self.tableView.reloadData()
        } else {
            self.updateHeader(false)
        }
    }
    
    @IBAction func createChatButtonPressed(sender: AnyObject) {

        (sender as! UIBarButtonItem).enabled = false
        
        let selectedIndexes = self.tableView.indexPathsForSelectedRows
        
        var users: [QBUUser] = []
        
        for indexPath in selectedIndexes! {
            let user = self.users[indexPath.row]
            users.append(user)
        }
        
        weak var weakSelf = self
        
        let completion = { (response: QBResponse!, createdDialog: QBChatDialog!) -> Void in
            
            (sender as! UIBarButtonItem).enabled = true
            
            if createdDialog != nil {
                print(createdDialog)
                weakSelf?.processeNewDialog(createdDialog)
            }
            
            if response != nil && response.error != nil {
                print(response.error?.error)
                SVProgressHUD.showErrorWithStatus(response.error?.error?.localizedDescription)
            }
        }
        
        if let dialog = self.dialog {
            
            if dialog.type == .Group {
                
                SVProgressHUD.showWithStatus("SA_STR_LOADING".localized, maskType: SVProgressHUDMaskType.Clear)
                
                NewDialogViewController.updateDialog(self.dialog!, newUsers:users, completion: { (response, dialog) -> Void in
                    
                    if let rightBarButtonItem = weakSelf?.navigationItem.rightBarButtonItem {
                        rightBarButtonItem.enabled = true
                    }
                    
                    if (response.error == nil) {
                        
                        SVProgressHUD.showSuccessWithStatus("STR_DIALOG_CREATED".localized)
        
        
                        weakSelf?.processeNewDialog(dialog)
                        
                    } else {
                        SVProgressHUD.showErrorWithStatus(response.error?.error?.localizedDescription)
                    }
                    
                })
                
            } else {
                
                let chatName = NewDialogViewController.nameForGroupChatWithUsers(users)

                NewDialogViewController.createChat(chatName, users: users, completion: completion)
            }
            
        } else {
            
            if users.count == 1 {
                
                NewDialogViewController.createChat(nil, users: users, completion: completion)

            } else {
                
                _ = AlertViewWithTextField(title: "SA_STR_ENTER_CHAT_NAME".localized, message: nil, showOver:self, didClickOk: { (text) -> Void in
                    
                    var chatName = text
                    
                    if chatName!.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet()).isEmpty {
                        chatName = NewDialogViewController.nameForGroupChatWithUsers(users)
                    }
                    
                    NewDialogViewController.createChat(chatName, users: users, completion: completion)
                    
                    }) { () -> Void in
                        
                        // cancel
                        (sender as! UIBarButtonItem).enabled = true
                }
            }
        }
    }
    
    static func updateDialog(dialog:QBChatDialog!, newUsers users:[QBUUser], completion: ((response: QBResponse!, dialog: QBChatDialog!) -> Void)?) {
        
        let usersIDs = users.map{ $0.ID }
        
        // Updates dialog with new occupants.
        ServicesManager.instance().chatService.joinOccupantsWithIDs(usersIDs, toChatDialog: dialog) { (response: QBResponse!, dialog: QBChatDialog!) -> Void in
    
            if (response.error == nil) {
                
                // Notifies users about new dialog with them.
                ServicesManager.instance().chatService.notifyUsersWithIDs(usersIDs, aboutAddingToDialog: dialog, completion: { (error: NSError?) -> Void in
                    // Notifies existing dialog occupants about new users.
                    ServicesManager.instance().chatService.notifyAboutUpdateDialog(dialog, occupantsCustomParameters: nil, notificationText: self.updatedMessageWithUsers(users), completion: nil)
                })
                
                print(dialog)
                
                completion?(response: response, dialog: dialog)
                
            } else {
                
                print(response.error?.error)
                
                completion?(response: response, dialog: nil)
    
            }
            
        }
    }
    
    static func updatedMessageWithUsers(users: [QBUUser]) -> String {
        var message: String = "\(QBSession.currentSession().currentUser!.login!) added "
        for user: QBUUser in users {
            message = "\(message)\(user.login!),"
        }
        message = message.substringToIndex(message.endIndex.predecessor())
        return message
    }
    
    static func nameForGroupChatWithUsers(users:[QBUUser]) -> String {
        
        let chatName = ServicesManager.instance().currentUser()!.login! + "_" + users.map({ $0.login ?? $0.email! }).joinWithSeparator(", ").stringByReplacingOccurrencesOfString("@", withString: "", options: NSStringCompareOptions.LiteralSearch, range: nil)
        
        return chatName
    }
    
    static func createChat(name: String?, users:[QBUUser], completion: ((response: QBResponse!, createdDialog: QBChatDialog!) -> Void)?) {
        
        SVProgressHUD.showWithStatus("SA_STR_LOADING".localized, maskType: SVProgressHUDMaskType.Clear)
        
        if users.count == 1 {
            
            // Creating private chat.
            ServicesManager.instance().chatService.createPrivateChatDialogWithOpponent(users.first!, completion: { (response: QBResponse!, chatDialog: QBChatDialog!) -> Void in
                
                SVProgressHUD.showSuccessWithStatus("STR_DIALOG_CREATED".localized)
                
                completion?(response: response, createdDialog: chatDialog)
            })
            
        } else {
            
            // Creating group chat.
            ServicesManager.instance().chatService.createGroupChatDialogWithName(name, photo: nil, occupants: users) { (response: QBResponse!, chatDialog: QBChatDialog!) -> Void in
                
                if (chatDialog != nil) {
                    ServicesManager.instance().chatService.notifyUsersWithIDs(chatDialog.occupantIDs, aboutAddingToDialog: chatDialog, completion: nil)
                }
                
                SVProgressHUD.showSuccessWithStatus("STR_DIALOG_CREATED".localized)
                
                completion?(response: response, createdDialog: chatDialog)
            }
        }
    }
    
    func processeNewDialog(dialog: QBChatDialog!) {
        self.dialog = dialog
        self.performSegueWithIdentifier("SA_STR_SEGUE_GO_TO_CHAT".localized, sender: nil)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "SA_STR_SEGUE_GO_TO_CHAT".localized {
            if let chatVC = segue.destinationViewController as? ChatViewController {
                chatVC.dialog = self.dialog
                chatVC.shouldFixViewControllersStack = true
            }
        }
    }
    
    // MARK: - UITableViewDataSource
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        var numberOfRowsInSection = 0
        
        if (tableView == self.tableView) {
            
            numberOfRowsInSection = self.users.count
            
        } else {
            
            numberOfRowsInSection = self.findedUsers.count
            
        }
        
        return numberOfRowsInSection
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        var cell : UITableViewCell
        
        if (tableView == self.tableView) {
            
            let userCell = tableView.dequeueReusableCellWithIdentifier("SA_STR_CELL_USER".localized, forIndexPath: indexPath) as! UserTableViewCell
            
            userCell.tag = indexPath.row
            
            let user = self.users[indexPath.row]
            userCell.userDescription = user.login
            
            cell = userCell
            
        } else {
            
            cell = UITableViewCell(style: UITableViewCellStyle.Default, reuseIdentifier: nil)
            
        }
        
        return cell
    }
    
    // MARK: - UITableViewDelegate
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        if tableView == self.tableView {
            
            if self.users.count > indexPath.row {
                self.checkCreateChatButtonState()
            }
            
        } else {
            
            let selectedUser = (self.searchController.searchResultsController as! UsersSearchResultsController).users[indexPath.row]
            
            if !self.users.contains(selectedUser) {
                self.searchController.active = false
                
                if (self.users.count == 0) {
                    self.updateHeader(true)
                }
                
                self.users.append(selectedUser)
                
                let newIndexPath = NSIndexPath(forItem: self.users.count - 1, inSection: 0)
                
                self.tableView.insertRowsAtIndexPaths([newIndexPath], withRowAnimation: UITableViewRowAnimation.Automatic)
                self.tableView.selectRowAtIndexPath(newIndexPath, animated: true, scrollPosition: UITableViewScrollPosition.None)
                
                self.checkCreateChatButtonState()
            }
        }
    }
    
    override func tableView(tableView: UITableView, didDeselectRowAtIndexPath indexPath: NSIndexPath) {
        self.checkCreateChatButtonState()
    }
    
    // MARK: - QMChatServiceDelegate
    
    func chatService(chatService: QMChatService!, didUpdateChatDialogInMemoryStorage chatDialog: QBChatDialog!) {
        
        if (chatDialog.ID == self.dialog?.ID) {
            self.dialog = chatDialog
            self.tableView.reloadData()
        }
        
    }
    
    func updateSearchResultsForSearchController(searchController: UISearchController) {

        let usersSearchResultsController = searchController.searchResultsController as! UsersSearchResultsController
        
        if searchController.searchBar.text?.characters.count < 3 {
            
            usersSearchResultsController.users.removeAll()
            usersSearchResultsController.tableView.reloadData()
            
            return
        }
        
        NSObject.cancelPreviousPerformRequestsWithTarget(self)
        self.performSelector("performSearchUsersWithKeyWord:", withObject: searchController.searchBar.text!, afterDelay: 1.0)
    }
    
    func performSearchUsersWithKeyWord(keyWord : String) {
        
        let usersSearchResultsController = self.searchController.searchResultsController as! UsersSearchResultsController
        
        ServicesManager.instance().usersService.searchUsersWithFullName(keyWord).continueWithBlock { (task: BFTask!) -> AnyObject! in
            if task.error != nil {
                
            } else if task.cancelled {
                
            } else {
                
                let filteredUsers = (task.result as! [QBUUser]).filter({ (user : QBUUser) -> Bool in
                    let isEqual = !user.isEqual(ServicesManager.instance().currentUser())
                    
                    return isEqual
                })
                
                usersSearchResultsController.users.removeAll()
                usersSearchResultsController.users.appendContentsOf(filteredUsers)
                usersSearchResultsController.tableView.reloadData()
                
            }
            return nil
        }
    }
}
