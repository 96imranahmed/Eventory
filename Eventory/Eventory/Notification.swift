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
    var image: UIImage?;
    
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
        self.image = UIImage(named: "unknownprofile.png");1
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
    class func getUnreadCount() -> UInt {
        var count = 0;
        for (var i = 0; i < Globals.notifications.count; i++) {
            let curr = Globals.notifications[i];
            if curr.read == false {
                count = count + 1;
            }
        }
        return UInt(count);
    }
    class func getNotifications(limit: Int?, page: Int?) {
        if (Reachability.isConnectedToNetwork()) {
            let URLStub: String! = NSBundle.mainBundle().objectForInfoDictionaryKey("URL Stub") as! String;
            //Clean Values by escaping
            var dictsend = Dictionary<String, String>()
            dictsend["profid"] = FBSDKAccessToken.currentAccessToken().userID;
            dictsend["token"] = FBSDKAccessToken.currentAccessToken().tokenString;
            if (limit != nil) {
                dictsend["limit"] = limit?.description;
            }
            if (page != nil) {
                dictsend["page"] = page?.description;
            }
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
                if data?.length == 0 {
                    Globals.unreadnotificationcount = 0;
                    NSNotificationCenter.defaultCenter().postNotificationName("Eventory_Notifications_Done", object: self, userInfo: nil);
                } else {
                    if let results:NSArray = (NSJSONSerialization.JSONObjectWithData(data!, options: nil, error: nil) as? NSArray)
                    {
                        if (results.count > 0) {
                            if page == 0 {
                                Globals.notifications = [];
                            }
                            let countstore: NSDictionary = results[0] as! NSDictionary;
                            let count = countstore.valueForKey("numberunseen") as! String;
                            if results.count > 1 {
                                //let currenter:NSArray = results[1] as! NSArray;
                                for (var i = 1; i<results.count; i++) {
                                    let current:NSDictionary = results[i] as! NSDictionary;
                                    let sourceid:String = (current.valueForKey("sourceid")!) as! String;
                                    let interval:Double = (current.valueForKey("date"))! as! Double;
                                    let date:NSDate = NSDate(timeIntervalSince1970: interval);
                                    let type:Int = (current.valueForKey("type")!) as! Int;
                                    let read:Bool = (current.valueForKey("isread")!) as! Bool;
                                    let text:String = (current.valueForKey("text")!) as! String;
                                    let data:String = (current.valueForKey("data")!) as! String;
                                    let results = Globals.notifications.filter({$0.date == date})
                                    if (results.count > 0) {
                                    } else {
                                        Globals.notifications.append(Notification(type: type, sourceID: sourceid, decided: nil, text: text, read: read, notifdata: data, date: date));
                                    }
                                }
                            }
                            Globals.unreadnotificationcount = count.toInt()!;
                            NSNotificationCenter.defaultCenter().postNotificationName("Eventory_Notifications_Done", object: self, userInfo: nil);
                        }
                    }
                }
            }
            task.resume();
        }
        
    }
}