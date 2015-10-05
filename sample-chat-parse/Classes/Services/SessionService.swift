//
//  SessionService.swift
//  sample-chat-parse
//
//  Created by Injoit on 10/5/15.
//  Copyright © 2015 quickblox. All rights reserved.
//

import Foundation

typealias CompletionWithError = (error : NSError?) -> Void

class SessionService : NSObject {
    
    static func logInWithUsername(username : String, password : String, completion : CompletionWithError?) {
        
        guard let username : String = username, let password : String = password
            where username.characters.count > 0 && password.characters.count > 0 else {
                
            completion?(error: nil)
                
            return
        }
        
        PFUser.logInWithUsernameInBackground(username, password: password) { (user: PFUser?, error: NSError?) -> Void in
            
            if let _ = error {
                
                completion?(error: error)
                
                return
            }
            
            user?.password = password
            
            SessionService.logInWithParseUser(user!, completion: completion)
        }
        
    }
    
    static func signUpWithUsername(username : String, password : String, completion : CompletionWithError?) {
        
        guard let username : String = username, let password : String = password
            where username.characters.count > 0 && password.characters.count > 0 else {
                
                completion?(error: nil)
                
                return
        }
        
        let parseUser = PFUser()
        parseUser.username = username
        parseUser.password = password
        
        parseUser.signUpInBackgroundWithBlock { (result: Bool, error: NSError?) -> Void in
            
            if let _ = error {
                
                completion?(error: error)
                
                return
            }
            
            let quickbloxUser = QBUUser()
            quickbloxUser.login = username
            quickbloxUser.password = password
            
            QBRequest.signUp(quickbloxUser, successBlock: { (response: QBResponse, users: QBUUser?) -> Void in
                
                completion?(error: nil)
                
            }, errorBlock: { (response: QBResponse) -> Void in
                    
                completion?(error: response.error?.error)
            })
            
        }
    }
    
    static func restoreSession(completion : CompletionWithError?) -> Bool {
        
        if (ServicesManager.instance().isAuthorized()) {
            
            completion?(error: nil)
            
            return true
        }
        
        let isCanRestoreSession = SessionService.isCanRestoreSession()
        
        if isCanRestoreSession {
            
            let parseUser = PFUser.currentUser()
            
            SessionService.logInWithParseUser(parseUser!, completion: completion)
        }
        
        return isCanRestoreSession
    }
    
    private static func logInWithParseUser(parseUser: PFUser, completion : CompletionWithError?) {
        
        guard let username : String = parseUser.username, let password : String = parseUser.password
            where username.characters.count > 0 && password.characters.count > 0 else {
                
                completion?(error: nil)
                
                return
        }
        
        let quickbloxUser = QBUUser()
        quickbloxUser.login = parseUser.username
        quickbloxUser.password = parseUser.password
        
        ServicesManager.instance().logInWithUser(quickbloxUser, completion: { (result: Bool, errorMessage: String!) -> Void in
            
            if let _ = errorMessage {
                
                completion?(error: NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey : errorMessage]))
                
                return
            }
            
            completion?(error: nil)
            
        })
        
    }
    
    static func isCanRestoreSession() -> Bool {
        return PFUser.currentUser() != nil
    }
    
    static func logOut(completion : CompletionWithError?) {
        
        ServicesManager.instance().logoutWithCompletion { () -> Void in
            
            PFUser.logOutInBackgroundWithBlock({ (error: NSError?) -> Void in
                completion?(error: error)
            })
        }
    }
}