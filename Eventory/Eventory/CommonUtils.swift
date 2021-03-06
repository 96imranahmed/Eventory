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
    var notifications:[Notification];
    var unreadnotificationcount:Int!;
    var profloaded:Bool;
    var groupschanged:Bool;
    var localgroups:[GroupData];
    init (currentprofile:Profile, currentgroup:Group, notifications:[Notification], unreadnotificationcount:Int, profloaded:Bool, groupschanged:Bool) {
        self.currentprofile = currentprofile;
        self.currentgroup = currentgroup;
        self.notifications = notifications;
        self.unreadnotificationcount = unreadnotificationcount;
        self.profloaded = profloaded;
        self.groupschanged = groupschanged;
        self.localgroups = [];
    }
    class func clearAll() {
        Profile.ClearProfiles();
        Group.ClearGroups();
    }
}
public struct Constants {
    static let notificationloadlimit = 5;
}
public class Schemes
{
    class func returnColor(name: String, alpha: CGFloat) -> UIColor {
        switch name {
        case "Turquoise":
            return UIColor(red: 26/255, green: 188/255, blue: 156/255, alpha: alpha)
        case "Emerald":
            return UIColor(red: 46/255, green: 204/255, blue: 113/255, alpha: alpha)
        case "Peter River":
            return UIColor(red: 52/255, green: 152/255, blue: 219/255, alpha: alpha)
        case "Amethyst":
            return UIColor(red: 155/255, green: 89/255, blue: 182/255, alpha: alpha)
        case "Wet Asphalt":
            return UIColor(red: 52/255, green: 73/255, blue: 94/255, alpha: alpha)
        case "Green Sea":
            return UIColor(red: 22/255, green: 160/255, blue: 133/255, alpha: alpha)
        case "Nephritis":
            return UIColor(red: 39/255, green: 174/255, blue: 96/255, alpha: alpha)
        case "Belize Hole":
            return UIColor(red: 41/255, green: 128/255, blue: 185/255, alpha: alpha)
        case "Wisteria":
            return UIColor(red: 142/255, green: 68/255, blue: 173/255, alpha: alpha)
        case "Midnight Blue":
            return UIColor(red: 44/255, green: 62/255, blue: 80/255, alpha: alpha)
        case "Sunflower":
            return UIColor(red: 241/255, green: 196/255, blue: 15/255, alpha: alpha)
        case "Carrot":
            return UIColor(red: 230/255, green: 126/255, blue: 34/255, alpha: alpha)
        case "Alizarin":
            return UIColor(red: 231/255, green: 76/255, blue: 60/255, alpha: alpha)
        case "Clouds":
            return UIColor(red: 236/255, green: 240/255, blue: 241/255, alpha: alpha)
        case "Concrete":
            return UIColor(red: 149/255, green: 165/255, blue: 166/255, alpha: alpha)
        case "Orange":
            return UIColor(red: 243/255, green: 156/255, blue: 18/255, alpha: alpha)
        case "Pumpkin":
            return UIColor(red: 211/255, green: 84/255, blue: 0/255, alpha: alpha)
        case "Pomegranite":
            return UIColor(red: 192/255, green: 57/255, blue: 43/255, alpha: alpha)
        case "Silver":
            return UIColor(red: 189/255, green: 195/255, blue: 199/255, alpha: alpha)
        case "Asbestos":
            return UIColor(red: 127/255, green: 140/255, blue: 141/255, alpha: alpha)
        default:
            return UIColor.whiteColor();
        }
    }
}

public class Reachability {
    class func isConnectedToNetwork()->Bool
    {
        var zeroAddress = sockaddr_in()
        zeroAddress.sin_len = UInt8(sizeofValue(zeroAddress))
        zeroAddress.sin_family = sa_family_t(AF_INET)
        let defaultRouteReachability = withUnsafePointer(&zeroAddress) {
            SCNetworkReachabilityCreateWithAddress(nil, UnsafePointer($0))
        }
        var flags = SCNetworkReachabilityFlags.ConnectionAutomatic
        if !SCNetworkReachabilityGetFlags(defaultRouteReachability!, &flags) {
            return false
        }
        let isReachable = (flags.rawValue & UInt32(kSCNetworkFlagsReachable)) != 0
        let needsConnection = (flags.rawValue & UInt32(kSCNetworkFlagsConnectionRequired)) != 0
        return (isReachable && !needsConnection)
    }
    
    class func postToServer(stub: String, postdata: Dictionary<String, AnyObject>, customselector: String?) -> Void {
        let URLStub: String! = NSBundle.mainBundle().objectForInfoDictionaryKey("URL Stub") as! String;
        //Clean Values by escaping
        var dictsend = Dictionary<String, String>()
        for (key, value) in postdata {
            if let stringArray = value as? [String] {
                for (var i=0; i<stringArray.count; i++) {
                    let newkey = (key as String) + "[" + (i.description) + "]";
                    dictsend[newkey] = Reachability.escapeString(stringArray[i]);
                }
            }
            else {
                dictsend[key as String] = Reachability.escapeString(value as! String);
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
        
        let urlstring = URLStub + (stub);
        let url = NSURL(string: urlstring)!;
        _ = NSURLSession.sharedSession();
        let request = NSMutableURLRequest(URL: url);
        request.HTTPMethod = "POST";
        request.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type");
        request.HTTPBody = contentBodyAsString.dataUsingEncoding(NSUTF8StringEncoding);
        let task = NSURLSession.sharedSession().dataTaskWithRequest(request) {
            (data, response, error) in
            //NSLog((NSString(data: data!, encoding: NSUTF8StringEncoding)?.description)!);
            //let subString = (response.description as NSString).containsString("Error") - Checks for error
            if let sendto = customselector {
                if (sendto == "MainGroupLoad") {
                    Group.saveGrouptoCoreData(data);
                } else if (sendto == "GroupRefresh") {
                    var params = Dictionary<String,AnyObject>();
                    params["type"] = "0";
                    Reachability.postToServer("group_get.php", postdata: params, customselector: "MainGroupLoad")
                } else if (sendto == "UpdateGroupMemberList") {
                    let friends:[Profile] = Group.parseProfileGet(data!);
                    let params:Dictionary = ["Friends":friends];
                    NSNotificationCenter.defaultCenter().postNotificationName("Eventory_Single_Group_List_Updated", object: self, userInfo: params);
                } else if (sendto == "UpdateGroupInvitedList") {
                    let friends:[Profile] = Group.parseProfileGet(data!);
                    let params:Dictionary = ["Friends":friends];
                    NSNotificationCenter.defaultCenter().postNotificationName("Eventory_Single_Group_Invited_List_Updated", object: self, userInfo: params);
                } else if (sendto == "ProfileUpdated") {
                    var paramstwo = Dictionary<String,AnyObject>();
                    paramstwo["type"] = "0";
                    Reachability.postToServer("group_get.php", postdata: paramstwo, customselector: "MainGroupLoad");
                    Notification.getNotifications(Constants.notificationloadlimit, page: 0);
                } else if (sendto == "DeclinedGroupLoad") {
                    Group.getGroupsfrom(data!, withtype: 1);
                } else if (sendto == "LeftGroupLoad") {
                    Group.getGroupsfrom(data!, withtype: 2);
                }
            } else {
            }
        }
        task.resume()
    }
    
    class func escapeString(input: String) -> String {
        var output = input;
        output = output.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())!;
        //output = output.stringByReplacingOccurrencesOfString("%", withString: "%25");
        //output = output.stringByReplacingOccurrencesOfString("'", withString: "''");
        output = output.stringByReplacingOccurrencesOfString("&", withString: "%26");
        output = output.stringByReplacingOccurrencesOfString("+", withString: "%2B");
        output = output.stringByReplacingOccurrencesOfString("/", withString: "%2F");
        output = output.stringByReplacingOccurrencesOfString("?", withString: "%3F");
        output = output.stringByReplacingOccurrencesOfString("#", withString: "%23");
        return output;
    }
}
var demonotif = [];
var demoprofile = Profile(name: "", url: "", profid: "", imagedata: nil, save: false);
var demogroup = Group(name: "", groupid: "", memberstring: "", invitedstring: "", isadmin: false, save: false);
var Globals = Main(currentprofile: demoprofile, currentgroup: demogroup,notifications: demonotif as! [Notification], unreadnotificationcount: 0, profloaded: false, groupschanged: false);