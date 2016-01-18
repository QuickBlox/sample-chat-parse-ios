# QuickBlox iOS Sample Chat (Swift) + Parse integration

## Introduction
This is a code sample for [QuickBlox](http://quickblox.com/) platform with usage of users from [Parse](https://parse.com) platform. It is showing a basic implementation of authentication with users from Parse.

## Requirements
* Xcode 7+
* iOS SDK 7+
* Quickblox iOS SDK 2.5+
* Parse iOS SDK (installed via Cocoapods)

Additional libraries used via [CocoaPods](https://cocoapods.org):

* [Parse](https://github.com/ParsePlatform/Parse-SDK-iOS-OSX)
* [SVProgressHUD](https://github.com/TransitApp/SVProgressHUD.git/)
* [TWMessageBarManager](https://github.com/rs/SDWebImage.git)
* [TTTAttributedLabel](https://github.com/TTTAttributedLabel/TTTAttributedLabel.git)
  * [QMChatViewController](https://github.com/QuickBlox/QMChatViewController-ios)
  * [QMServices](https://github.com/QuickBlox/q-municate-services-ios)


## Explanation 
To login in the app just type any name in username field and press login. It will login or create new account with this name if doesn't exists.

### Session Service 
SessionService class contains main logic of Parse and Quickblox authentication.

Login user with username. This method connecting user to Parse and calling method to login in Quickblox on success.

```swift
static func logInWithUsername(username : String, password : String, completion : CompletionWithError?)
```

Sign up user with username. This method doing sign up into parse and then sign up into Quickblox on success.

```swift
static func signUpWithUsername(username : String, password : String, completion : CompletionWithError?)
```

Restore session if possible. Restoring Quickblox session if possible, if not - login into Quickblox with existed parse user.

```swift
static func restoreSession(completion : CompletionWithError?) -> Bool
```

Login into Quickblox with Parse user. Private method to login into Quickblox after successful Parse login.

```swift
private static func logInWithParseUser(parseUser: PFUser, completion : CompletionWithError?)
```

Is session restoration possible. Determines whether Parse user exist or not.

```swift
static func isCanRestoreSession() -> Bool
```

Logout current user. Login out of Quickblox and Parse for current user.

```swift
static func logOut(completion : CompletionWithError?)
```

Open LoginTableViewController class to see SessionService usage.