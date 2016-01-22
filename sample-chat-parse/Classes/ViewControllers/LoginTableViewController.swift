//
//  LoginTableViewController.swift
//  sample-chat-swift
//
//  Created by Anton Sokolchenko on 3/31/15.
//  Copyright (c) 2015 quickblox. All rights reserved.
//

import UIKit

class LoginTableViewController: UITableViewController {

    @IBOutlet weak var loginTextField: UITextField!
    @IBOutlet weak var nextButton: UIBarButtonItem!
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        self.nextButton.enabled = false
    }
    
    @IBAction func loginTextFieldEditingChanged(sender: UITextField) {
        if (sender.text?.characters.count >= 3 && sender.text?.characters.count <= 40) {
            self.nextButton.enabled = true
        } else {
            self.nextButton.enabled = false
        }
    }
    
    @IBAction func nextButtonClicked(sender: AnyObject) {
        
        let regex = try! NSRegularExpression(pattern: ".*[^A-Za-z0-9_].*", options: [])
        if regex.firstMatchInString(self.loginTextField.text!, options: [], range: NSMakeRange(0, self.loginTextField.text!.characters.count)) != nil {
            
            SVProgressHUD.showErrorWithStatus("SA_STR_WRONG_USERNAME".localized)
            return
        }
        
        SVProgressHUD.showWithStatus("SA_STR_LOGGIN_IN_AS".localized + self.loginTextField.text!, maskType: SVProgressHUDMaskType.Clear)
        
        SessionService.logInWithUsername(self.loginTextField.text!, password: kTestUsersDefaultPassword) { (error : NSError?) -> Void in
            //
            if ((error) != nil) {
                SVProgressHUD.showWithStatus("Signing Up as " + self.loginTextField.text!, maskType: SVProgressHUDMaskType.Clear)
                
                SessionService.signUpWithUsername(self.loginTextField.text!, password: kTestUsersDefaultPassword) { (error) -> Void in
                    
                    self.registerForRemoteNotification()
                    SVProgressHUD.showSuccessWithStatus("SA_STR_LOGGED_IN".localized)
                    self.dismissViewControllerAnimated(true, completion: nil)
                }
            } else {
                self.registerForRemoteNotification()
                SVProgressHUD.showSuccessWithStatus("SA_STR_LOGGED_IN".localized)
                self.dismissViewControllerAnimated(true, completion: nil)
            }
        }
    }
    
    // MARK: Remote notifications
    
    func registerForRemoteNotification() {

        let settings = UIUserNotificationSettings(forTypes: [UIUserNotificationType.Alert, UIUserNotificationType.Badge, UIUserNotificationType.Sound], categories: nil)
        UIApplication.sharedApplication().registerUserNotificationSettings(settings)
        UIApplication.sharedApplication().registerForRemoteNotifications()
    }
}
