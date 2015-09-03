//
//  Profile.swift
//  Eventory
//
//  Created by Imran Ahmed on 18/07/2015.
//  Copyright (c) 2015 Imran Ahmed. All rights reserved.
//

import Foundation
import CoreData
class Profile : NSManagedObject {
    @NSManaged var name:String?;
    @NSManaged var url:String?;
    @NSManaged var profid:String?;
    @NSManaged var imagedata:NSData?;
    convenience init (name:String?, url:String?, profid:String?, imagedata:NSData?, save:Bool) {
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        let ctx = appDelegate.managedObjectContext;
        var entity = NSEntityDescription.entityForName("Profile", inManagedObjectContext: ctx!)
        if (save) {
            self.init(entity: entity!, insertIntoManagedObjectContext: ctx);
        } else {
            self.init(entity: entity!, insertIntoManagedObjectContext: nil);
        }
        self.name = name;
        self.url = url;
        self.profid = profid;
        if (imagedata == nil) { } else {
            self.imagedata = imagedata;
        }
    }
    //MARK: Core Data Methods
    class func createInManagedObjectContext(moc: NSManagedObjectContext, name:String?, url:String?, profid:String?, isuser:Bool?) -> Profile {
        let savedprofile = NSEntityDescription.insertNewObjectForEntityForName("Profile", inManagedObjectContext: moc) as! Profile
        savedprofile.name = name;
        savedprofile.url = url;
        savedprofile.profid = profid;
        savedprofile.imagedata = NSData();
        downloadPictureAsync(url, id: profid)
        return savedprofile;
    }
    
    class func fetchProfileforID(id: String) -> Profile! {
        let fetchRequest = NSFetchRequest(entityName: "Profile")
        fetchRequest.fetchLimit = 1;
        let predicate = NSPredicate(format: "profid == '" + id + "'");
        fetchRequest.predicate = predicate
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        let ctx = appDelegate.managedObjectContext;
        if let fetchResults = ctx!.executeFetchRequest(fetchRequest, error: nil) as? [Profile] {
            var currentprof:Profile = fetchResults[0];
            return currentprof
        } else {
            return nil
        }
        
    }
    
    class func ClearProfiles () {
        //Clears profiles only
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        let ctx = appDelegate.managedObjectContext
        let fetchRequest = NSFetchRequest(entityName: "Profile")
        let fetchResults = (ctx!.executeFetchRequest(fetchRequest, error: nil) as? [Profile])!
        for (var i = 0; i < fetchResults.count ; i++) {
            if (FBSDKAccessToken.currentAccessToken() != nil) {
                if (fetchResults[i].profid != FBSDKAccessToken.currentAccessToken().userID) {
                    ctx?.deleteObject(fetchResults[i]);
                }
            } else {
                ctx?.deleteObject(fetchResults[i]);
            }
        }
        ctx?.save(nil)
    }
    class func ClearProfileNils () {
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        let ctx = appDelegate.managedObjectContext
        let fetchRequest = NSFetchRequest(entityName: "Profile")
        let predicate = NSPredicate(format: "profid == nil OR profid == ''");
        fetchRequest.predicate = predicate;
        let fetchResults = (ctx!.executeFetchRequest(fetchRequest, error: nil) as? [Profile])!
        for (var i = 0; i < fetchResults.count ; i++) {
            ctx?.deleteObject(fetchResults[i]);
        }
        ctx?.save(nil)
    }
    class func CheckProfileifContains(column: String, identifier: String) -> Bool {
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        let ctx = appDelegate.managedObjectContext
        let fetchRequest = NSFetchRequest(entityName: "Profile")
        fetchRequest.fetchLimit = 1;
        var formatted = column + " == '" + identifier + "'";
        let predicate = NSPredicate(format: formatted);
        fetchRequest.predicate = predicate
        let fetchResults = ctx!.executeFetchRequest(fetchRequest, error: nil) as? [Profile];
        if (fetchResults!.count>0){
            return true;
        } else {
            return false;
        }
    }
    //MARK: Friend Parse Methods
    class func getIDArray(inputarray:[Profile?]) -> [String] {
        var outputarray = [String]();
        for (index, element) in enumerate(inputarray) {
            outputarray.append(element!.profid!);
        }
        return outputarray;
    }
    
    class func getLastName(name: String) -> String {
        var fullNameArr = split(name) {$0 == " "}
        return fullNameArr[fullNameArr.count - 1]
    }
    class func getFirstName(name: String) -> String {
        var fullNameArr = split(name) {$0 == " "}
        return fullNameArr[0]
    }
    class func SortFriends(input:[Profile]!) -> [Profile]! {
        var friends = input;
        if (friends.count>0) {
            if contains(friends, Globals.currentprofile!) {
                friends.removeAtIndex(find(friends,Globals.currentprofile!)!)
            }
            friends.sort({self.getLastName($0.name!)>self.getLastName($1.name!)});
            friends = friends.reverse();
        }
        return friends;
    }
    class func saveFriendstoCoreData(result:AnyObject?) -> [String]! {
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        let ctx = appDelegate.managedObjectContext
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
            if (Profile.CheckProfileifContains("profid", identifier: profid!)){
                let fetchRequest = NSFetchRequest(entityName: "Profile")
                fetchRequest.fetchLimit = 1;
                let predicate = NSPredicate(format: "profid == %@", profid!)
                fetchRequest.predicate = predicate
                if let fetchResults = ctx!.executeFetchRequest(fetchRequest, error: nil) as? [Profile]{
                    var currententry = fetchResults[0];
                    if (currententry.url == profilepictureurl) {
                    } else {
                        ctx?.deleteObject(currententry)
                        currententry = Profile.createInManagedObjectContext(ctx!, name: namepost!, url: profilepictureurl!, profid: profid!, isuser: false);
                    }
                }
            } else {
                //If not already in list - create entry
                var currententry = Profile.createInManagedObjectContext(ctx!, name: namepost!, url: profilepictureurl!, profid: profid!, isuser: false);
            }
            friendid.append(profid!)
        }
        //Remove any deleted friends
        let fetchRequest = NSFetchRequest(entityName: "Profile")
        if let fetchResults = ctx!.executeFetchRequest(fetchRequest, error: nil) as? [Profile]{
            var checkfriends = friendid;
            checkfriends.append(FBSDKAccessToken.currentAccessToken().userID);
            for (var i = 0; i<fetchResults.count; i++){
                if contains(checkfriends, fetchResults[i].profid!) {
                } else {
                    ctx?.deleteObject(fetchResults[i]);
                }
            }
        }
        NSNotificationCenter.defaultCenter().postNotificationName("Eventory_Friends_Saved", object: self, userInfo: nil);
        ctx?.save(nil);
        return friendid;
    }
    //MARK: Image Download Methods
    class func downloadUnknownPictureAsync(input:Profile, membersfind:Bool) { //Downloads an unknown profile image based on supplied Profile
        let imageRequest: NSURLRequest = NSURLRequest(URL: NSURL(string: input.url!)!);
        let queue: NSOperationQueue = NSOperationQueue.mainQueue()
        NSURLConnection.sendAsynchronousRequest(imageRequest, queue: queue, completionHandler:{ (response: NSURLResponse!, data: NSData!, error: NSError!) -> Void in
            if data != nil {
                var params = Dictionary<String,AnyObject>();
                params["ID"] = input.profid;
                params["Data"] = data;
                if membersfind {
                    NSNotificationCenter.defaultCenter().postNotificationName("Eventory_Group_Picture_Updated", object: self, userInfo: params);
                } else {
                    NSNotificationCenter.defaultCenter().postNotificationName("Eventory_Group_Invited_Picture_Updated", object: self, userInfo: params);
                }
            }
        })
    }
    class func downloadPictureAsync(URL:String?, id:String?) { //Downloads Profile Picture (doesn't return anything)
        let imageRequest: NSURLRequest = NSURLRequest(URL: NSURL(string: URL!)!);
        let queue: NSOperationQueue = NSOperationQueue.mainQueue()
        NSURLConnection.sendAsynchronousRequest(imageRequest, queue: queue, completionHandler:{ (response: NSURLResponse!, data: NSData!, error: NSError!) -> Void in
            if data != nil {
                let fetchRequest = NSFetchRequest(entityName: "Profile")
                fetchRequest.fetchLimit = 1;
                let predicate = NSPredicate(format: "profid == '" + id! + "'");
                fetchRequest.predicate = predicate
                let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
                let ctx = appDelegate.managedObjectContext;
                if let fetchResults = ctx!.executeFetchRequest(fetchRequest, error: nil) as? [Profile] {
                    var currentprof:Profile = fetchResults[0];
                    currentprof.imagedata = data;
                    if (currentprof.profid==Globals.currentprofile?.profid) {
                        Globals.currentprofile?.imagedata = data;
                        NSNotificationCenter.defaultCenter().postNotificationName("PPUpdated", object: self);
                    }
                    ctx?.save(nil);
                }
            }
        })
    }
    class func getPicturefromCoreData(id: String!) -> UIImage {
        if let inid = id {
            let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
            let ctx = appDelegate.managedObjectContext
            let fetchRequest = NSFetchRequest(entityName: "Profile");
            fetchRequest.fetchLimit = 1;
            var formatted = "profid == '" + inid + "'";
            let predicate = NSPredicate(format: formatted);
            fetchRequest.predicate = predicate
            let fetchResults = ctx!.executeFetchRequest(fetchRequest, error: nil) as? [Profile];
            if (fetchResults!.count>0){
                let imageprof:Profile = fetchResults![0];
                if let image = UIImage(data: imageprof.imagedata!) {
                    return image;
                } else {
                    return (UIImage(named: "unknownprofile.png"))!;
                }
            } else {
                return (UIImage(named: "unknownprofile.png"))!;
            }
        } else {
            return (UIImage(named: "unknownprofile.png"))!;
        }
    }
    
    
}
