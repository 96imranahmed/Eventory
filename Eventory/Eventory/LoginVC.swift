//
//  LoginVC.swift
//  Eventory
//
//  Created by Imran Ahmed on 05/07/2015.
//  Copyright (c) 2015 Imran Ahmed. All rights reserved.
//

import UIKit
import CoreData

class LoginVC: UIViewController, FBSDKLoginButtonDelegate {
    @IBOutlet weak var StatusLabel: UILabel!
    @IBOutlet weak var LoginButton: FBSDKLoginButton!
    @IBOutlet weak var ProfilePicture: FBSDKProfilePictureView!
    let URLStub: String! = NSBundle.mainBundle().objectForInfoDictionaryKey("URL Stub") as! String;
    let appName: String! = "Eventory";
    var postresponse:String!;
    //Below declarations allows for the creation of the login-indicator
    var messageFrame = UIView();
    var activityIndicator = UIActivityIndicatorView();
    var strLabel = UILabel();
    var canproceed:Bool = false;
    var currentlyconnected:Bool = false;
    var profdl = false;
    var frdl = false;
    //Core Data Stuff
    let managedObjectContext = (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //Check whether network is running or not -> use as basis for offline mode
        if (!Reachability.isConnectedToNetwork()) {
            currentlyconnected = false;
        } else {
            currentlyconnected = true;
        }
        ProfilePicture.layer.masksToBounds = true;
        ProfilePicture.layer.cornerRadius = ProfilePicture.frame.height/2;
        self.LoginButton.delegate = self;
        LoginButton.readPermissions = ["public_profile", "user_friends"]; //Add user_events if required
        LoginButton.loginBehavior = FBSDKLoginBehavior.Web;
        NSNotificationCenter.defaultCenter().addObserver(self, selector:"observeProfileChange:", name: FBSDKProfileDidChangeNotification, object: nil);
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "observeTokenChange:", name: FBSDKAccessTokenDidChangeNotification, object: nil);
        if (FBSDKProfile.currentProfile()==nil) {
            if (FBSDKAccessToken.currentAccessToken() == nil) {
                
            } else {
                StatusLabel.text = "SDK Error" //Try grab from NSData if possible
                if let item: Profile = Profile.fetchProfileforID(FBSDKAccessToken.currentAccessToken().userID) {
                    FBSDKProfile.setCurrentProfile(FBSDKProfile(userID: FBSDKAccessToken.currentAccessToken().userID, firstName: Profile.getFirstName(item.name!) , middleName: nil, lastName: Profile.getLastName(item.name!), name: item.name, linkURL: nil, refreshDate: FBSDKAccessToken.currentAccessToken().refreshDate))
                    checkPermissions();
                }
            }
        } else {
            progressBarDisplayer("Logging In", true)
            StatusLabel.text = "Logged in as " + FBSDKProfile.currentProfile().name;
            checkPermissions();
        }
    }
    
    override func viewWillAppear(animated: Bool) {
    }
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(true);
        if (canproceed) {
            dispatch_async(dispatch_get_main_queue(), {
                self.performSegueWithIdentifier("LogintoLanding", sender: self);
            })
        }
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func loginButtonDidLogOut(loginButton: FBSDKLoginButton!) {
        let errordelete = Locksmith.deleteDataForUserAccount(self.appName);
        StatusLabel.text = "Successfully Logged Out!";
    }
    
    func rerequestPermissions() {
        var login = FBSDKLoginManager.new();
        login.logOut();
        login.logInWithReadPermissions(["public_profile", "user_friends"], handler: { (result:FBSDKLoginManagerLoginResult!, error:NSError!) -> Void in
            if error != nil {
                return;
            }
            if (result.isCancelled) {
                login.logOut();
                self.StatusLabel.text = "Login cancelled - try again?";
                return;
            }
            self.checkPermissions();
        })  //Add user_events if required
    }
    func forceLogout() {
        var login = FBSDKLoginManager.new();
        login.logOut();
        let errordelete = Locksmith.deleteDataForUserAccount(self.appName);
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
            progressBarDisplayer("Logging In", true)
            checkPermissions();
        }
    }
    func observeProfileChange(notification: NSNotification?) {
        if (FBSDKProfile.currentProfile()==nil) {
        } else {
            StatusLabel.text = "Logged in as " + FBSDKProfile.currentProfile().name;
        }
        
    }
    
    func observeTokenChange(notification: NSNotification?) {
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
            self.messageFrame.removeFromSuperview()
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
            var alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.Alert)
            alert.addAction(UIAlertAction(title: "Enable?", style: .Default, handler: { action in
                self.rerequestPermissions();
            }))
            alert.addAction(UIAlertAction(title: "Logout", style: .Cancel, handler: { action in
                self.forceLogout();
            }))
            self.presentViewController(alert, animated: true, completion: nil)
            //Create alert view
        } else {
            self.view.hidden = true;
            logInProfile();
        }
        
    }
    func logInProfile() {
        //Get FB data from token
        let request = FBSDKGraphRequest(graphPath: "/me?fields=id,name,picture.width(150).height(150)", parameters: nil);
        let connection = FBSDKGraphRequestConnection();
        connection.addRequest(request, completionHandler: { (connection:FBSDKGraphRequestConnection!, result:AnyObject!, error:NSError!) -> Void in
            self.profdl = true;
            if (error==nil) {
                var id: NSString? = (result as! NSDictionary).valueForKey("id") as? NSString;
                var namepost: NSString? = (result as! NSDictionary).valueForKey("name") as? NSString;
                var profilepicture:AnyObject? = (result as! NSDictionary).valueForKey("picture");
                profilepicture = (profilepicture as! NSDictionary).valueForKey("data");
                profilepicture = (profilepicture as! NSDictionary).valueForKey("url") as? NSString;
                //Save credentials to keychain
                let errordelete = Locksmith.deleteDataForUserAccount(self.appName);
                let error = Locksmith.saveData([id as! String: FBSDKAccessToken.currentAccessToken().tokenString], forUserAccount: self.appName);
                //Creates a new save profile of personal profile
                if let moc = self.managedObjectContext {
                    if (Profile.CheckProfileifContains("profid", identifier: (id as? String)!)) {
                        let fetchRequest = NSFetchRequest(entityName: "Profile")
                        fetchRequest.fetchLimit = 1;
                        let predicate = NSPredicate(format: "profid == %@",id!);
                        fetchRequest.predicate = predicate
                        let fetchResults = self.managedObjectContext!.executeFetchRequest(fetchRequest, error: nil) as? [Profile];
                        Globals.currentprofile = fetchResults?[0];
                    } else {
                        Globals.currentprofile = Profile.createInManagedObjectContext(moc, name: namepost as? String, url: profilepicture as? String, profid: id as? String, isuser: true);
                    }
                }
            }
        })
        if (currentlyconnected) {
            let parameters = ["method": "GET"];
            let friendrequest = FBSDKGraphRequest(graphPath: "/me?fields=friends.limit(5000)%7Bpicture.width(150).height(150),name%7D", parameters: parameters, HTTPMethod: "POST");
            connection.addRequest(friendrequest, completionHandler: { (connection:FBSDKGraphRequestConnection!, result:AnyObject!, error:NSError!) -> Void in
                //Get friends
                self.frdl = true;
                if (result != nil) {
                    Main.clearAll();
                    var friendid = Profile.saveFriendstoCoreData(result);
                    var params = Dictionary<String, AnyObject>();
                    params["name"] = Globals.currentprofile!.name;
                    params["url"] = Globals.currentprofile!.url;
                    params["id"] = friendid;
                    Reachability.postToServer("profile.php", postdata: params, customselector:nil);
                    var paramstwo = Dictionary<String,AnyObject>();
                    paramstwo["type"] = "0";
                    Reachability.postToServer("group_get.php", postdata: paramstwo, customselector: "MainGroupLoad")
                }
                //Upload values to Eventory
                self.messageFrame.removeFromSuperview()
                (UIApplication.sharedApplication().delegate as! AppDelegate).saveContext();
                self.canproceed = true;
                self.frdl = false;
                self.profdl = false
                if (self.isViewLoaded()) {
                    if (FBSDKProfile.currentProfile().name != nil) {
                        dispatch_async(dispatch_get_main_queue(), {
                            self.performSegueWithIdentifier("LogintoLanding", sender: self);
                        })
                    } else {
                        self.forceLogout();
                    }
                }
            })
            connection.start();
            let timer = NSTimer.scheduledTimerWithTimeInterval(4.0, target: self, selector: Selector("timeout"), userInfo: nil, repeats: false);
        } else {
            self.messageFrame.removeFromSuperview()
            //Process offline login
            if (FBSDKAccessToken.currentAccessToken() == nil) {
                //Create alert view - notifies that there is no saved profile to load at all
                self.view.hidden = false;
                //NSLog("No internet connection!");
                dispatch_async(dispatch_get_main_queue(), {
                    var alert = UIAlertController(title: "No internet connection!", message: "You have not logged in and have no network connection. Please connect to continue", preferredStyle: UIAlertControllerStyle.Alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .Default, handler: nil))
                    self.presentViewController(alert, animated: true, completion: nil)
                })
            } else {
                //Load saved profile (offline mode - but check for token expiry first!)
                if (FBSDKAccessToken.currentAccessToken().expirationDate.timeIntervalSinceNow <= 0) {
                    //Profile has expired
                    //NSLog("Profile expired!");
                    self.view.hidden = false;
                    dispatch_async(dispatch_get_main_queue(), {
                        var alert = UIAlertController(title: "No internet connection!", message: "Your access token has expired and you have no network connection. Please connect to continue", preferredStyle: UIAlertControllerStyle.Alert)
                        alert.addAction(UIAlertAction(title: "OK", style: .Default, handler: nil))
                        self.presentViewController(alert, animated: true, completion: nil)
                    })
                } else {
                    //Actually load this profile
                    let fetchRequest = NSFetchRequest(entityName: "Profile")
                    let predicate = NSPredicate(format: "profid == %@", FBSDKAccessToken.currentAccessToken().userID)
                    fetchRequest.predicate = predicate
                    if let fetchResults = managedObjectContext!.executeFetchRequest(fetchRequest, error: nil) as? [Profile] {
                        if (fetchResults.count>0) {
                            Globals.currentprofile = fetchResults[0];
                        }
                    }
                    self.canproceed = true;
                }
            }
            if (!Reachability.isConnectedToNetwork()) {
                currentlyconnected = false;
            } else {
                currentlyconnected = true;
            }
        }
    }
    func timeout() {
        if (profdl == false && frdl == false) {
            //Delete
        }
    }
    func progressBarDisplayer(msg:String, _ indicator:Bool ) {
        strLabel = UILabel(frame: CGRect(x: 50, y: 0, width: 200, height: 50))
        strLabel.text = msg
        strLabel.textColor = UIColor.whiteColor()
        messageFrame = UIView(frame: CGRect(x: view.frame.midX - 90, y: view.frame.midY - 25 , width: 180, height: 50))
        messageFrame.layer.cornerRadius = 15
        messageFrame.backgroundColor = UIColor(white: 0, alpha: 0.7)
        if indicator {
            activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.White)
            activityIndicator.frame = CGRect(x: 0, y: 0, width: 50, height: 50)
            activityIndicator.startAnimating()
            messageFrame.addSubview(activityIndicator)
        }
        messageFrame.addSubview(strLabel)
        view.addSubview(messageFrame)
    }
    
}

