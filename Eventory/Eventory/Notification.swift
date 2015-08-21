//
//  Notification.swift
//  Eventory
//
//  Created by Imran Ahmed on 05/08/2015.
//  Copyright (c) 2015 Imran Ahmed. All rights reserved.
//

import Foundation

class Notification {
    var notificationtype: Int?;
    var sourceID: String?;
    var decided: Bool?
    var text: String?
    var candecide: Bool;
    var read: Bool;
    var notifdata: String?;
    var date: NSDate;
    
    init (type: Int, sourceID: String?, decided: Bool?, text: String, read: Bool, notifdata: String?, date: NSDate) {
        self.notificationtype = type;
        self.sourceID = sourceID
        self.decided = decided
        self.text = text;
        self.read = read;
        if (self.notificationtype == 1) {
            self.candecide = true;
        } else {
            self.candecide = false;
        }
        self.notifdata = notifdata
        self.date = date
        self.performSetup()
    }
    func performSetup() {
        //Any additional setup if required
        if (self.notificationtype == 1) {
            //Group Decision Notification
        }
    }
    func performJump() {
        if (self.notificationtype == 1) {
            if let decision = self.decided {
                //Group Decision Notification
            }
        }
    }
    class func getNotifications() {
        if (Reachability.isConnectedToNetwork()) {
            let URLStub: String! = NSBundle.mainBundle().objectForInfoDictionaryKey("URL Stub") as! String;
            //Clean Values by escaping
            var dictsend = Dictionary<String, String>()
            dictsend["profid"] = FBSDKAccessToken.currentAccessToken().userID;
            dictsend["token"] = FBSDKAccessToken.currentAccessToken().tokenString;
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
            let urlstring = URLStub + "notification_get.php";
            let url = NSURL(string: urlstring)!;
            let session = NSURLSession.sharedSession();
            let request = NSMutableURLRequest(URL: url);
            request.HTTPMethod = "POST";
            request.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type");
            request.HTTPBody = contentBodyAsString.dataUsingEncoding(NSUTF8StringEncoding);
            contentBodyAsString = contentBodyAsString.stringByAddingPercentEscapesUsingEncoding(NSUTF8StringEncoding)!
            let task = NSURLSession.sharedSession().dataTaskWithRequest(request) {
                (data, response, error) in
                 NSLog((NSString(data: data!, encoding: NSUTF8StringEncoding)?.description)!);
                if let results: Dictionary = NSJSONSerialization.JSONObjectWithData(data!, options: nil, error: nil) as? Dictionary<String,AnyObject>
                {
                   
                    if (results.count > 0) {
                        var output = [Notification]();
                         for (notificationindex, current) in results {
                            let sourceid:String = ((current as? NSDictionary)?.valueForKey("sourceid")!)! as! String;
                            let interval:Double = ((current as? NSDictionary)?.valueForKey("date"))! as! Double;
                            let date:NSDate = NSDate(timeIntervalSinceNow: interval);
                            let type:Int = ((current as? NSDictionary)?.valueForKey("type")!)! as! Int;
                            let read:Bool = ((current as? NSDictionary)?.valueForKey("read")!)! as! Bool;
                            let text:String = ((current as? NSDictionary)?.valueForKey("text")!)! as! String;
                            let data:String = ((current as? NSDictionary)?.valueForKey("data")!)! as! String;
                            output.append(Notification(type: type, sourceID: sourceid, decided: nil, text: text, read: read, notifdata: data, date: date))
                        }
                        var params = Dictionary<String,AnyObject>();
                        params["Notifications"] = output
                    NSNotificationCenter.defaultCenter().postNotificationName("Eventory_Notifications_Done", object: self, userInfo: params);
                    }
                }
            }
            task.resume();
        }
        
    }
}