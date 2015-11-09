//
//  QMServiceManager.swift
//  sample-chat-swift
//
//  Created by Injoit on 5/22/15.
//  Copyright (c) 2015 quickblox. All rights reserved.
//

import Foundation

/**
*  Implements user's memory/cache storing, error handling, show top bar notifications.
*/
class ServicesManager: QMServicesManager {
    
    var currentDialogID : String = ""
    
    var notificationService: NotificationService!
    
    override init() {
        super.init()
        
        self.setupContactServices()
        
        self.usersService.loadFromCache()
        
    }
    
    private func setupContactServices() {
        self.notificationService = NotificationService()
    }
    
    func handleNewMessage(message: QBChatMessage, dialogID: String) {
        
        if self.currentDialogID == dialogID {
            return
        }
        
        if message.senderID == self.currentUser().ID {
            return
        }
        
        let dialog = self.chatService.dialogsMemoryStorage.chatDialogWithID(dialogID)
        var dialogName = "New message"
        
        if dialog.type != QBChatDialogType.Private {
            
            if dialog.name != nil {
                dialogName = dialog.name!
            }
            
        } else {
            
            if let user = ServicesManager.instance().usersService.usersMemoryStorage.userWithID(UInt(dialog.recipientID)) {
                dialogName = user.login!
            }
        }
        
        TWMessageBarManager.sharedInstance().hideAll()
        TWMessageBarManager.sharedInstance().showMessageWithTitle(dialogName, description: message.text, type: TWMessageBarMessageType.Info)
    }
    
    // MARK: dialog utils
    
    func joinAllGroupDialogs() {
        let allDialogs: Array<QBChatDialog> = ServicesManager.instance().chatService.dialogsMemoryStorage.dialogsSortByUpdatedAtWithAscending(false) as! Array<QBChatDialog>
        for dialog : QBChatDialog in allDialogs {
            
            // Notifies occupants that user left the dialog.
            if dialog.type != QBChatDialogType.Private {
                
                self.chatService.joinToGroupDialog(dialog, completion: { (error: NSError?) -> Void in
                    if (error != nil) {
                        NSLog("Failed to join dialog with error: %@", error!)
                    }
                })
            }
        }
    }
    
    // MARK: Last activity date
    
    var lastActivityDate: NSDate? {
        get {
            let defaults = NSUserDefaults.standardUserDefaults()
            return defaults.valueForKey("SA_STR_LAST_ACTIVITY_DATE".localized) as! NSDate?
        }
        set {
            let defaults = NSUserDefaults.standardUserDefaults()
            defaults.setObject(newValue, forKey: "SA_STR_LAST_ACTIVITY_DATE".localized)
            defaults.synchronize()
        }
    }
    
    // MARK: QMServiceManagerProtocol
    
    override func handleErrorResponse(response: QBResponse!) {
        super.handleErrorResponse(response)
        
        if !self.isAuthorized() {
            return;
        }
        
        var errorMessage : String
        
        if response.status.rawValue == 502 {
            errorMessage = "Bad Gateway, please try again"
        } else if response.status.rawValue == 0 {
            errorMessage = "Connection network error, please try again"
        } else {
            errorMessage = (response.error?.error?.localizedDescription.stringByReplacingOccurrencesOfString("(", withString: "", options: NSStringCompareOptions.CaseInsensitiveSearch, range: nil).stringByReplacingOccurrencesOfString(")", withString: "", options: NSStringCompareOptions.CaseInsensitiveSearch, range: nil))!
        }
        
        TWMessageBarManager.sharedInstance().hideAll()
        TWMessageBarManager.sharedInstance().showMessageWithTitle("Error", description: errorMessage, type: TWMessageBarMessageType.Error)
        
    }
    
    // MARK: QMChatServiceDelegate
    
    override func chatService(chatService: QMChatService!, didAddMessageToMemoryStorage message: QBChatMessage!, forDialogID dialogID: String!) {
        super.chatService(chatService, didAddMessageToMemoryStorage: message, forDialogID: dialogID)
        self.handleNewMessage(message, dialogID: dialogID)
    }
}
