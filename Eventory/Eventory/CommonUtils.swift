//
//  CommonUtils.swift
//  Eventory
//
//  Created by Imran Ahmed on 07/07/2015.
//  Copyright (c) 2015 Imran Ahmed. All rights reserved.
//

import Foundation
import CoreData;
import SystemConfiguration;

class Main {
    var currentprofile:Profile?;
    var currentgroup:Group?;
    init (currentprofile:Profile, currentgroup:Group) {
        self.currentprofile = currentprofile;
        self.currentgroup = currentgroup;
    }
}


public class Reachability {
    class func isConnectedToNetwork()->Bool
    {
        var zeroAddress = sockaddr_in(sin_len: 0, sin_family: 0, sin_port: 0, sin_addr: in_addr(s_addr: 0), sin_zero: (0, 0, 0, 0, 0, 0, 0, 0))
        zeroAddress.sin_len = UInt8(sizeofValue(zeroAddress))
        zeroAddress.sin_family = sa_family_t(AF_INET)
        let defaultRouteReachability = withUnsafePointer(&zeroAddress) {
            SCNetworkReachabilityCreateWithAddress(nil, UnsafePointer($0)).takeRetainedValue()
        }
        var flags: SCNetworkReachabilityFlags = 0
        if SCNetworkReachabilityGetFlags(defaultRouteReachability, &flags) == 0 {
            return false
        }
        let isReachable = (flags & UInt32(kSCNetworkFlagsReachable)) != 0
        let needsConnection = (flags & UInt32(kSCNetworkFlagsConnectionRequired)) != 0
        return (isReachable && !needsConnection) ? true : false;
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
                } else if (sendto == "GroupRefresh") {
                    var params = Dictionary<String,AnyObject>();
                    params["type"] = "0";
                    Reachability.postToServer("group_get.php", postdata: params, customselector: "MainGroupLoad")
                } else if (sendto == "UpdateGroupMemberList") {
                    var friends:[Profile] = Group.parseProfileGet(data);
                    var params:Dictionary = ["Friends":friends];
                    NSNotificationCenter.defaultCenter().postNotificationName("Eventory_Group_List_Updated", object: self, userInfo: params);
                } else if (sendto == "UpdateGroupInvitedList") {
                    var friends:[Profile] = Group.parseProfileGet(data);
                    var params:Dictionary = ["Friends":friends];
                    NSNotificationCenter.defaultCenter().postNotificationName("Eventory_Group_Invited_List_Updated", object: self, userInfo: params);
                }
            }
        }
        task.resume()
    }

}
var demoprofile = Profile(name: "", url: "", profid: "", imagedata: nil, save: false);
var demogroup = Group(name: "", groupid: "", memberstring: "", invitedstring: "", isadmin: false, save: false);
var Globals = Main(currentprofile: demoprofile, currentgroup: demogroup);