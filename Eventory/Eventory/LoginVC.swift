//
//  LoginVC.swift
//  Eventory
//
//  Created by Imran Ahmed on 05/07/2015.
//  Copyright (c) 2015 Imran Ahmed. All rights reserved.
//

import UIKit

class LoginVC: UIViewController, FBSDKLoginButtonDelegate {
    @IBOutlet weak var StatusLabel: UILabel!
    @IBOutlet weak var LoginButton: FBSDKLoginButton!
    @IBOutlet weak var ProfilePicture: FBSDKProfilePictureView!
    var URLStub: String!;
    var appName: String! = "Eventory";
    
    override func viewDidLoad() {
        super.viewDidLoad()
        URLStub = NSBundle.mainBundle().objectForInfoDictionaryKey("URL Stub") as! String;
        self.LoginButton.delegate = self;
        LoginButton.readPermissions = ["public_profile", "user_friends"]; //Add user_events if required
        LoginButton.loginBehavior = FBSDKLoginBehavior.Native;
        NSNotificationCenter.defaultCenter().addObserver(self, selector:"observeProfileChange:", name: FBSDKProfileDidChangeNotification, object: nil);
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "observeTokenChange:", name: FBSDKAccessTokenDidChangeNotification, object: nil);
        if (FBSDKProfile.currentProfile()==nil) {
            NSLog("No profile loaded");
        } else {
            NSLog("Profile already stored");
            StatusLabel.text = "Logged in as " + FBSDKProfile.currentProfile().name;
        }
        NSLog("View loaded");
    }
    
    override func viewDidAppear(animated: Bool) {
   
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func loginButtonDidLogOut(loginButton: FBSDKLoginButton!) {
        NSLog("Logged out (after user press)!");
        StatusLabel.text = "Successfully Logged Out!";
    }
    
    func rerequestPermissions() {
        NSLog("Rerequesting Permissions");
        var login = FBSDKLoginManager.new();
        login.logOut();
        login.logInWithReadPermissions(["public_profile", "user_friends"], handler: { (result:FBSDKLoginManagerLoginResult!, error:NSError!) -> Void in
            if error != nil {
                NSLog("Unknown Error");
                return;
            }
            if (result.isCancelled) {
                NSLog("Rerequest permissions cancelled - logging out");
                login.logOut();
                self.StatusLabel.text = "Login cancelled - try again?";
                return;
            }
            self.checkPermissions();
        })  //Add user_events if required
    }
    func forceLogout() {
        NSLog("Forced logout");
        var login = FBSDKLoginManager.new();
        login.logOut();
    }
    func loginButton(loginButton: FBSDKLoginButton!, didCompleteWithResult result: FBSDKLoginManagerLoginResult!, error: NSError!) {
        if ((error) != nil)
        {
            StatusLabel.text = "Error - try again?";
        }
        else if result.isCancelled {
            StatusLabel.text = "Login cancelled - try again?";
        }
        else {
            NSLog("Successful login - check permissions and process!");
        }
    }
    func observeProfileChange(notification: NSNotification?) {
        NSLog("Profile has changed");
        if (FBSDKProfile.currentProfile()==nil) {
            NSLog("No profile loaded");
        } else {
            NSLog("Profile already stored");
            StatusLabel.text = "Logged in as " + FBSDKProfile.currentProfile().name;
        }
    }
    
    func observeTokenChange(notification: NSNotification?) {
        NSLog("Token has changed");
            if ((FBSDKAccessToken.currentAccessToken())==nil) {
            } else {
                self.observeProfileChange(nil);
            }
        }
    
    func checkPermissions() {
        var currentpermissions:Int = 0;
        if (FBSDKAccessToken.currentAccessToken().permissions.contains("user_friends")) {
            currentpermissions = currentpermissions + 1;
        }
        if (FBSDKAccessToken.currentAccessToken().permissions.contains("user_events")) {
            currentpermissions = currentpermissions + 2;
        }
        if (currentpermissions<1) { //Increase to 3 when including user_events permission
            var message = "";
            var title = "";
            if (currentpermissions==0) {
                //user_friends && user_events denied
                title = "Friends & Event Access Denied :(";
                message = appName + " requires a list of your upcoming events and friends to provide you with the best user experience possible. Would you like to enable these permissions or log-out?";
            } else if (currentpermissions==1) {
                //user_events denied
                title = "Event Access Denied :(";
                message = appName + " requires a list of your upcoming events to provide you with the best experience possible. Would you like to enable this permission or log-out?";
            } else if (currentpermissions == 2) {
                //user_friends denied
                title = "Friend Access Denied :(";
                message = appName + " requires a list of your friends using " + appName + " to provide you with the best social experience possible. Would you like to enable this permission or log-out?";
            }
            //Create alert view
        }
    }
}

