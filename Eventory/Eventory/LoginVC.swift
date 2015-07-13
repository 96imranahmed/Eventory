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
    var URLStub: String!;
    let appName: String! = "Eventory";
    var postresponse:String!;
    //Below declarations allows for the creation of the login-indicator
    var messageFrame = UIView();
    var activityIndicator = UIActivityIndicatorView();
    var strLabel = UILabel();
    var canproceed:Bool = false;
    //Core Data Stuff
    let managedObjectContext = (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //Check whether network is running or not -> use as basis for offline mode
        if (!Reachability.isConnectedToNetwork()) {
            NSLog("Not connected to internet!");
            Globals.connected = false;
        } else {
            Globals.connected = true;
        }
        ProfilePicture.layer.masksToBounds = true;
        ProfilePicture.layer.cornerRadius = ProfilePicture.frame.height/2;
        URLStub = NSBundle.mainBundle().objectForInfoDictionaryKey("URL Stub") as! String;
        self.LoginButton.delegate = self;
        LoginButton.readPermissions = ["public_profile", "user_friends"]; //Add user_events if required
        LoginButton.loginBehavior = FBSDKLoginBehavior.Web;
        NSNotificationCenter.defaultCenter().addObserver(self, selector:"observeProfileChange:", name: FBSDKProfileDidChangeNotification, object: nil);
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "observeTokenChange:", name: FBSDKAccessTokenDidChangeNotification, object: nil);
        if (FBSDKProfile.currentProfile()==nil) {
            NSLog("No profile loaded");
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
            self.performSegueWithIdentifier("LogintoLanding", sender: self);
        }
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func loginButtonDidLogOut(loginButton: FBSDKLoginButton!) {
        NSLog("Logged out (after user press)!");
        let errordelete = Locksmith.deleteDataForUserAccount(self.appName);
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
            ClearProfiles();
            progressBarDisplayer("Logging In", true)
            NSLog("Successful login - check permissions and process!");
            checkPermissions();
        }
    }
    func observeProfileChange(notification: NSNotification?) {
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
        let request = FBSDKGraphRequest(graphPath: "/me?fields=id,name,picture", parameters: nil);
        let connection = FBSDKGraphRequestConnection();
        connection.addRequest(request, completionHandler: { (connection:FBSDKGraphRequestConnection!, result:AnyObject!, error:NSError!) -> Void in
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
                var personalprofile: Profile;
                if let moc = self.managedObjectContext {
                    self.ClearProfileNils();
                    if (self.CheckProfileifContains("profid", identifier: (id as? String)!)) {
                        let fetchRequest = NSFetchRequest(entityName: "Profile")
                        fetchRequest.fetchLimit = 1;
                        let predicate = NSPredicate(format: "profid == %@",id!);
                        fetchRequest.predicate = predicate
                        let fetchResults = self.managedObjectContext!.executeFetchRequest(fetchRequest, error: nil) as? [Profile];
                        Globals.currentprofile = fetchResults?[0];
                        NSLog("Profile already saved in Core Data");
                    } else {
                        Globals.currentprofile = Profile.createInManagedObjectContext(moc, name: namepost as? String, url: profilepicture as? String, profid: id as? String);
                        NSLog(Globals.currentprofile!.name! + " added and saved to Core Data");
                    }
                }
            }
        })
        if (Globals.connected) {
            let parameters = ["method": "GET"];
            let friendrequest = FBSDKGraphRequest(graphPath: "/me?fields=friends.limit(5000)%7Bpicture,name%7D", parameters: parameters, HTTPMethod: "POST");
            connection.addRequest(friendrequest, completionHandler: { (connection:FBSDKGraphRequestConnection!, result:AnyObject!, error:NSError!) -> Void in
                //Get friends
                var friendid = [String]();
                var friends: AnyObject? = (result as! NSDictionary).valueForKey("friends");
                var count: NSArray = (friends as! NSDictionary)["data"] as! NSArray;
                for (var i = 0; i < count.count; i++) {
                    var currentfriend: NSDictionary = count[i] as! NSDictionary;
                    let profid = currentfriend.valueForKey("id") as? String;
                    let namepost = currentfriend.valueForKey("name") as? String;
                    var profilepicture: AnyObject? = (currentfriend as NSDictionary).valueForKey("picture");
                    profilepicture = (profilepicture as! NSDictionary).valueForKey("data");
                    let profilepictureurl = (profilepicture as! NSDictionary).valueForKey("url") as? String;
                    if (self.CheckProfileifContains("profid", identifier: profid!)){
                        let fetchRequest = NSFetchRequest(entityName: "Profile")
                        fetchRequest.fetchLimit = 1;
                        let predicate = NSPredicate(format: "profid == %@", profid!)
                        fetchRequest.predicate = predicate
                        if let fetchResults = self.managedObjectContext!.executeFetchRequest(fetchRequest, error: nil) as? [Profile]{
                            var currententry = fetchResults[0];
                            if (currententry.url == profilepictureurl) {
                            } else {
                                self.managedObjectContext?.deleteObject(currententry)
                                currententry = Profile.createInManagedObjectContext(self.managedObjectContext!, name: namepost!, url: profilepictureurl!, profid: profid!);
                            }
                        }
                    } else {
                        //If not already in list - create entry
                        var currententry = Profile.createInManagedObjectContext(self.managedObjectContext!, name: namepost!, url: profilepictureurl!, profid: profid!);
                    }
                    friendid.append(profid!)
                    //Globals.friendlist.append(currententry);
                }
                //Remove any deleted friends
                let fetchRequest = NSFetchRequest(entityName: "Profile")
                if let fetchResults = self.managedObjectContext!.executeFetchRequest(fetchRequest, error: nil) as? [Profile]{
                    var checkfriends = friendid;
                    checkfriends.append(FBSDKAccessToken.currentAccessToken().userID);
                    for (var i = 0; i<fetchResults.count; i++){
                        if contains(checkfriends, fetchResults[i].profid!) {
                        } else {
                        self.managedObjectContext?.deleteObject(fetchResults[i]);
                        }
                    }
                }
                //Upload values to Eventory
                var params = Dictionary<String, AnyObject>();
                params["name"] = Globals.currentprofile!.name;
                params["url"] = Globals.currentprofile!.url;
                params["profid"] = Globals.currentprofile!.profid;
                params["id"] = friendid;
                params["token"] = FBSDKAccessToken.currentAccessToken().tokenString;
                self.postToServer("profile.php", postdata: params);
                self.messageFrame.removeFromSuperview()
                (UIApplication.sharedApplication().delegate as! AppDelegate).saveContext();
                self.canproceed = true;
                if (self.isViewLoaded()) {
                    self.performSegueWithIdentifier("LogintoLanding", sender: self);
                }
            })
            connection.start();
        } else {
            self.messageFrame.removeFromSuperview()
            //Process offline login
            if (FBSDKProfile.currentProfile() == nil) {
                //Create alert view - notifies that there is no saved profile to load at all
                self.view.hidden = false;
                NSLog("No internet connection!");
                var alert = UIAlertController(title: "No internet connection!", message: "You have not logged in and have no network connection. Please connect to continue", preferredStyle: UIAlertControllerStyle.Alert)
                self.presentViewController(alert, animated: true, completion: nil)
            } else {
                //Load saved profile (offline mode - but check for token expiry first!)
                if (FBSDKAccessToken.currentAccessToken().expirationDate.timeIntervalSinceNow <= 0) {
                    //Profile has expired
                    NSLog("Profile expired!");
                    self.view.hidden = false;
                    var alert = UIAlertController(title: "No internet connection!", message: "Your access token has expired and you have no network connection. Please connect to continue", preferredStyle: UIAlertControllerStyle.Alert)
                    self.presentViewController(alert, animated: true, completion: nil)
                } else {
                    //Actually load this profile
                    let fetchRequest = NSFetchRequest(entityName: "Profile")
                    let predicate = NSPredicate(format: "profid == %@", FBSDKProfile.currentProfile().userID)
                    fetchRequest.predicate = predicate
                    if let fetchResults = managedObjectContext!.executeFetchRequest(fetchRequest, error: nil) as? [Profile] {
                        Globals.currentprofile = fetchResults[0];
                        NSLog(Globals.currentprofile!.name! + " loaded from Core Data as primary profile!");
                    }
                    self.canproceed = true;
                }
            }
            if (!Reachability.isConnectedToNetwork()) {
                Globals.connected = false;
            } else {
                Globals.connected = true;
            }
        }
    }
    func postToServer(stub: NSString, postdata: Dictionary<String, AnyObject>) -> Void {
        let (dictionary, error) = Locksmith.loadDataForUserAccount("Eventory")
        //Clean Values by escaping
        var dictsend = Dictionary<String, String>()
        for (key, value) in postdata {
            if let stringArray = value as? [String] {
                for (var i=0; i<stringArray.count; i++) {
                    var newkey = (key as String) + "[" + (i.description) + "]";
                    dictsend[newkey] = stringArray[i];//stringArray[i].stringByAddingPercentEncodingWithAllowedCharacters(.URLHostAllowedCharacterSet())
                }
            }
            else {
                //var escapedval = value.stringByAddingPercentEncodingWithAllowedCharacters(.URLHostAllowedCharacterSet())
                dictsend[key as String] = value as? String;
            }
        }
        //Convert values into string
        var contentBodyAsString = "";
        var firstOneAdded = false
        let contentKeys:Array<String> = Array(dictsend.keys)
        for contentKey in contentKeys {
            if(!firstOneAdded) {
                contentBodyAsString += contentKey + "=" + dictsend[contentKey]!
                firstOneAdded = true
            }
            else {
                contentBodyAsString += "&" + contentKey + "=" + dictsend[contentKey]!
            }
        }
        contentBodyAsString = contentBodyAsString.stringByAddingPercentEscapesUsingEncoding(NSUTF8StringEncoding)!
        let urlstring = URLStub + (stub as String);
        let url = NSURL(string: urlstring)!;
        let session = NSURLSession.sharedSession();
        let request = NSMutableURLRequest(URL: url);
        request.HTTPMethod = "POST";
        request.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type");
        request.HTTPBody = contentBodyAsString.dataUsingEncoding(NSUTF8StringEncoding);
        let task = NSURLSession.sharedSession().dataTaskWithRequest(request) {
            (data, response, error) in
            //let subString = (response.description as NSString).containsString("Error") - Checks for error
            let dataoutput = String(NSString(data: data, encoding: NSUTF8StringEncoding)!)
        }
        task.resume()
    }
    
    func progressBarDisplayer(msg:String, _ indicator:Bool ) {
        println(msg)
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
    
    func ClearProfileNils () {
        let fetchRequest = NSFetchRequest(entityName: "Profile")
        let predicate = NSPredicate(format: "profid == nil OR profid == ''");
        fetchRequest.predicate = predicate;
        let fetchResults = (self.managedObjectContext!.executeFetchRequest(fetchRequest, error: nil) as? [Profile])!
        for (var i = 0; i < fetchResults.count ; i++) {
            self.managedObjectContext?.deleteObject(fetchResults[i]);
        }
    }
    
    func CheckProfileifContains(column: String, identifier: String) -> Bool {
        let fetchRequest = NSFetchRequest(entityName: "Profile")
        fetchRequest.fetchLimit = 1;
        var formatted = column + " == '" + identifier + "'";
        let predicate = NSPredicate(format: formatted);
        fetchRequest.predicate = predicate
        let fetchResults = managedObjectContext!.executeFetchRequest(fetchRequest, error: nil) as? [Profile];
            if (fetchResults!.count>0){
                return true;
            } else {
                return false;
            }
    }
    func ClearProfiles () {
        //Clears profiles only
        let fetchRequest = NSFetchRequest(entityName: "Profile")
        let fetchResults = (self.managedObjectContext!.executeFetchRequest(fetchRequest, error: nil) as? [Profile])!
        for (var i = 0; i < fetchResults.count ; i++) {
            self.managedObjectContext?.deleteObject(fetchResults[i]);
        }
    }
    
}

