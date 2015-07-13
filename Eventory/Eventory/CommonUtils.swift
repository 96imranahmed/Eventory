//
//  CommonUtils.swift
//  Eventory
//
//  Created by Imran Ahmed on 07/07/2015.
//  Copyright (c) 2015 Imran Ahmed. All rights reserved.
//

import Foundation
import CoreData;
class Main {
     var currentprofile:Profile?;
     var currentgroup:Group?;
     var friendlist:[Profile?];
     var connected:Bool;
    init (currentprofile:Profile, friendlist:[Profile?], currentgroup:Group, connected:Bool) {
        self.currentprofile = currentprofile;
        self.friendlist = friendlist;
        self.currentgroup = currentgroup;
        self.connected = connected;
    }
}

class Profile : NSManagedObject {
   @NSManaged var name:String?;
   @NSManaged var url:String?;
   @NSManaged var profid:String?;
   @NSManaged var imagedata:NSData?;
    convenience init (name:String?, url:String?, profid:String?, imagedata:NSData?) {
    let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
    let ctx = appDelegate.managedObjectContext;
    var entity = NSEntityDescription.entityForName("Profile", inManagedObjectContext: ctx!)
    self.init(entity: entity!, insertIntoManagedObjectContext: ctx)
    self.name = name;
    self.url = url;
    self.profid = profid;
        if (imagedata == nil) { } else {
            self.imagedata = imagedata;
        }
    }
class func getIDArray(inputarray:[Profile?]) -> [String] {
        var outputarray = [String]();
        for (index, element) in enumerate(inputarray) {
            outputarray.append(element!.profid!);
        }
        return outputarray;
    }
    class func createInManagedObjectContext(moc: NSManagedObjectContext, name:String?, url:String?, profid:String?) -> Profile {
        let urldownload = NSURL(string: url!)
        let data = NSData(contentsOfURL: urldownload!)
        let savedprofile = NSEntityDescription.insertNewObjectForEntityForName("Profile", inManagedObjectContext: moc) as! Profile
        savedprofile.name = name;
        savedprofile.url = url;
        savedprofile.profid = profid;
        savedprofile.imagedata = data;
        return savedprofile;
    }
}

class Group {
    var name:String?;
    var groupid:String?;
    var members:[Profile]?;
    init (name:String?, groupid:String?, members:[Profile]?) {
        self.name = name;
        self.groupid = groupid;
        self.members = members;
    }
}
public class Reachability {
    
    class func isConnectedToNetwork()->Bool{
        
        var Status:Bool = false
        let url = NSURL(string: "http://google.com/")
        let request = NSMutableURLRequest(URL: url!)
        request.HTTPMethod = "HEAD"
        request.cachePolicy = NSURLRequestCachePolicy.ReloadIgnoringLocalAndRemoteCacheData
        request.timeoutInterval = 10.0
        
        var response: NSURLResponse?
        
        var data = NSURLConnection.sendSynchronousRequest(request, returningResponse: &response, error: nil) as NSData?
        
        if let httpResponse = response as? NSHTTPURLResponse {
            if httpResponse.statusCode == 200 {
                Status = true
            }
        }
        
        return Status
    }
}

var demoprofile = Profile(name: "", url: "", profid: "", imagedata: nil);
var demofriendlist = [Profile?]();
var demogroup = Group(name: "", groupid: "", members: [Profile]());
var Globals = Main(currentprofile: demoprofile , friendlist: demofriendlist , currentgroup: demogroup, connected:false);