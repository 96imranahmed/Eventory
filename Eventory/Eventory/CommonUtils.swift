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
    init (currentprofile:Profile, friendlist:[Profile?], currentgroup:Group) {
        self.currentprofile = currentprofile;
        self.friendlist = friendlist;
        self.currentgroup = currentgroup;
    }
}


public class Reachability {
    class func isConnectedToNetwork()->Bool{
        var Status:Bool = false
        let url = NSURL(string: "http://google.com/")
        let request = NSMutableURLRequest(URL: url!)
        request.HTTPMethod = "HEAD"
        request.cachePolicy = NSURLRequestCachePolicy.ReloadIgnoringLocalAndRemoteCacheData
        request.timeoutInterval = 3;
        var response: NSURLResponse?
        var data = NSURLConnection.sendSynchronousRequest(request, returningResponse: &response, error: nil) as NSData?
        if let httpResponse = response as? NSHTTPURLResponse {
            if httpResponse.statusCode == 200 {
                Status = true
            }
        }
        if (!Status) {
            NSLog("OFFLINE!");
        }
        return Status
    }
    
    class func postToServer(stub: String, postdata: Dictionary<String, AnyObject>, customselector: String?) -> Void {
        let URLStub: String! = NSBundle.mainBundle().objectForInfoDictionaryKey("URL Stub") as! String;
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
        dictsend["profid"] = FBSDKAccessToken.currentAccessToken().userID;
        dictsend["token"] = FBSDKAccessToken.currentAccessToken().tokenString;
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
        let urlstring = URLStub + (stub);
        let url = NSURL(string: urlstring)!;
        let session = NSURLSession.sharedSession();
        let request = NSMutableURLRequest(URL: url);
        request.HTTPMethod = "POST";
        request.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type");
        request.HTTPBody = contentBodyAsString.dataUsingEncoding(NSUTF8StringEncoding);
        let task = NSURLSession.sharedSession().dataTaskWithRequest(request) {
            (data, response, error) in
            //let subString = (response.description as NSString).containsString("Error") - Checks for error
            if let sendto = customselector {
                if (sendto == "MainGroupLoad") {
                    Group.saveGrouptoCoreData(data);
                }
            }
        }
        task.resume()
    }

}
var demoprofile = Profile(name: "", url: "", profid: "", imagedata: nil);
var demofriendlist = [Profile?]();
var demogroup = Group(name: "", groupid: "", memberstring: "", invitedstring: "", isadmin: false);
var Globals = Main(currentprofile: demoprofile , friendlist: demofriendlist , currentgroup: demogroup);