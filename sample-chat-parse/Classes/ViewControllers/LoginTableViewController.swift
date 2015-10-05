//
//  LoginTableViewController.swift
//  sample-chat-swift
//
//  Created by Anton Sokolchenko on 3/31/15.
//  Copyright (c) 2015 quickblox. All rights reserved.
//

import UIKit

/**
 *  Default test users password
 */
let kTestUsersDefaultPassword = "x6Bt0VDy5"

class LoginTableViewController: UITableViewController {

    @IBOutlet weak var loginTextField: UITextField!
    
    @IBAction func logInButtonClicked(sender: AnyObject) {
        
        SVProgressHUD.showWithStatus("SA_STR_LOGGIN_IN_AS".localized + self.loginTextField.text!, maskType: SVProgressHUDMaskType.Clear)
        
        SessionService.logInWithUsername(self.loginTextField.text!, password: kTestUsersDefaultPassword) { (error) -> Void in
        
            self.registerForRemoteNotification()
            SVProgressHUD.showSuccessWithStatus("SA_STR_LOGGED_IN".localized)
            self.dismissViewControllerAnimated(true, completion: nil)
        }
        
    }
    
    @IBAction func signUpButtonClicked(sender: AnyObject) {
        
        SVProgressHUD.showWithStatus("Signing Up as " + self.loginTextField.text!, maskType: SVProgressHUDMaskType.Clear)
        
        SessionService.signUpWithUsername(self.loginTextField.text!, password: kTestUsersDefaultPassword) { (error) -> Void in
            
            self.registerForRemoteNotification()
            SVProgressHUD.showSuccessWithStatus("SA_STR_LOGGED_IN".localized)
            self.dismissViewControllerAnimated(true, completion: nil)
        }
        
    }
    
    // MARK: Remote notifications
    
    func registerForRemoteNotification() {

        let settings = UIUserNotificationSettings(forTypes: [UIUserNotificationType.Alert, UIUserNotificationType.Badge, UIUserNotificationType.Sound], categories: nil)
        UIApplication.sharedApplication().registerUserNotificationSettings(settings)
        UIApplication.sharedApplication().registerForRemoteNotifications()
    }
}
