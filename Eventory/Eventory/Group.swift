//
//  Group.swift
//  Eventory
//
//  Created by Imran Ahmed on 18/07/2015.
//  Copyright (c) 2015 Imran Ahmed. All rights reserved.
//

import Foundation
import CoreData

class Group: NSManagedObject {
    @NSManaged var name:String?;
    @NSManaged var groupid:String?;
    @NSManaged var memberstring:String?;
    @NSManaged var invitedstring:String?;
    @NSManaged var isadmin:Bool;
    convenience init (name:String?, groupid:String?, memberstring: String?, invitedstring: String?, isadmin:Bool, save:Bool) {
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        let ctx = appDelegate.managedObjectContext;
        var entity = NSEntityDescription.entityForName("Group", inManagedObjectContext: ctx!)
        if (save) {
            self.init(entity: entity!, insertIntoManagedObjectContext: ctx);
        } else {
            self.init(entity: entity!, insertIntoManagedObjectContext: nil);
        }
        self.name = name;
        self.groupid = groupid;
        self.memberstring = memberstring;
        self.isadmin = isadmin
        self.invitedstring = invitedstring;
    }
    //MARK: Core Data Methods
    class func createInManagedObjectContext(moc: NSManagedObjectContext,name:String?, groupid:String?, memberstring:String?, invitedstring: String?,isadmin:Bool) -> Group {
        let savedprofile = NSEntityDescription.insertNewObjectForEntityForName("Group", inManagedObjectContext: moc) as! Group
        savedprofile.name = name;
        savedprofile.groupid = groupid;
        savedprofile.memberstring = memberstring;
        savedprofile.invitedstring = invitedstring;
        savedprofile.isadmin = isadmin
        return savedprofile;
    }
    class func ClearGroups () {
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        let ctx = appDelegate.managedObjectContext
        let fetchRequest = NSFetchRequest(entityName: "Group")
        let fetchResults = (ctx!.executeFetchRequest(fetchRequest, error: nil) as? [Group])!
        for (var i = 0; i < fetchResults.count ; i++) {
            ctx?.deleteObject(fetchResults[i]);
        }
        ctx?.save(nil)
    }
    class func ClearGroupNils () {
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        let ctx = appDelegate.managedObjectContext
        let fetchRequest = NSFetchRequest(entityName: "Group")
        let predicate = NSPredicate(format: "groupid == nil OR groupid == ''");
        fetchRequest.predicate = predicate;
        let fetchResults = (ctx!.executeFetchRequest(fetchRequest, error: nil) as? [Group])!
        for (var i = 0; i < fetchResults.count ; i++) {
            ctx?.deleteObject(fetchResults[i]);
        }
        ctx?.save(nil)
    }
    class func CheckGroupifContains(column: String, identifier: String) -> Bool {
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        let ctx = appDelegate.managedObjectContext
        let fetchRequest = NSFetchRequest(entityName: "Group")
        fetchRequest.fetchLimit = 1;
        var formatted = column + " == '" + identifier + "'";
        let predicate = NSPredicate(format: formatted);
        fetchRequest.predicate = predicate
        let fetchResults = ctx!.executeFetchRequest(fetchRequest, error: nil) as? [Group];
        if (fetchResults!.count>0){
            return true;
        } else {
            return false;
        }
    }
    class func saveGrouptoCoreData(outputdata: NSData?){
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        let ctx = appDelegate.managedObjectContext
        var error: NSError?
        var grouplist:[Group!]!=[];
        if outputdata?.length == 0 {
            Group.ClearGroups();
            var params:Dictionary = ["Groups":grouplist];
            NSNotificationCenter.defaultCenter().postNotificationName("Eventory_Group_Saved", object: self, userInfo: params);
        } else {
            if let results: Dictionary = NSJSONSerialization.JSONObjectWithData(outputdata!, options: nil, error: &error) as? Dictionary<String,AnyObject>
            {
                Group.ClearGroups();
                var currententry: Group;
                for (grouplistindex, currentgroup) in results {
                    let name:String = ((currentgroup as? NSDictionary)?.valueForKey("Name")!)! as! String;
                    let admin:Bool = ((currentgroup as? NSDictionary)?.valueForKey("Admin")!)! as! Bool;
                    let id:String = ((currentgroup as? NSDictionary)?.valueForKey("GroupID")!)! as! String;
                    let members:NSArray = ((currentgroup as? NSDictionary)?.valueForKey("Members")!)! as! NSArray;
                    let invited:NSArray = ((currentgroup as? NSDictionary)?.valueForKey("Invited")!)! as! NSArray;
                    let memberstring = members.componentsJoinedByString(";");
                    let invitedstring = invited.componentsJoinedByString(";");
                    if (Group.CheckGroupifContains("groupid", identifier: id)) {
                        let fetchRequest = NSFetchRequest(entityName: "Group")
                        fetchRequest.fetchLimit = 1;
                        let predicate = NSPredicate(format: "groupid == %@", id)
                        fetchRequest.predicate = predicate
                        if let fetchResults = ctx!.executeFetchRequest(fetchRequest, error: nil) as? [Group]{
                            currententry = fetchResults[0];
                            ctx?.deleteObject(currententry)
                            currententry = Group.createInManagedObjectContext(ctx!, name: name, groupid: id, memberstring: memberstring, invitedstring: invitedstring, isadmin: admin);
                            grouplist.append(currententry);
                        }
                    } else {
                        currententry = Group.createInManagedObjectContext(ctx!, name: name, groupid: id, memberstring: memberstring, invitedstring: invitedstring, isadmin: admin);
                        grouplist.append(currententry);
                    }
                }
                ctx?.save(nil);
                var params:Dictionary = ["Groups":grouplist];
                NSNotificationCenter.defaultCenter().postNotificationName("Eventory_Group_Saved", object: self, userInfo: params);
            }
        }
    }
    //MARK: Group Sort Methods
    class func SortGroups(input:[Group]!) -> [Group]! {
        var groups = input;
        groups.sort({($0.name!)>($1.name!)});
        groups = groups.reverse();
        return groups;
    }
    class func shuffle<C: MutableCollectionType where C.Index == Int>(var list: C) -> C {
        let c = count(list)
        if c < 2 { return list }
        for i in 0..<(c - 1) {
            let j = Int(arc4random_uniform(UInt32(c - i))) + i
            swap(&list[i], &list[j])
        }
        return list
    }
    //MARK: Group Parse Methods
    class func returnSavedFriends(memberlist:String, membersfind:Bool) ->[Profile]? {
        if (memberlist == "") {
            return nil;
        } else {
            let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
            let ctx = appDelegate.managedObjectContext
            let fetchRequest = NSFetchRequest(entityName: "Profile");
            fetchRequest.fetchLimit = 1;
            var members:[String] = (memberlist.componentsSeparatedByString(";"));
            if (members[0] != "") {
                var output:[Profile]!=[];
                var nonfriends:[String]! = [];
                for (var i = 0; i<members.count; i++){
                    let predicate = NSPredicate(format: "profid == %@", members[i]);
                    fetchRequest.predicate = predicate;
                    var currentprof:[Profile]? = ctx!.executeFetchRequest(fetchRequest, error: nil) as? [Profile]
                    if let check = currentprof {
                        /*if (check[0].profid == FBSDKAccessToken.currentAccessToken().userID) {
                            let myprofile = Profile(name: "You", url: Globals.currentprofile!.url, profid: FBSDKAccessToken.currentAccessToken().userID, imagedata: Globals.currentprofile!.imagedata, save: false)
                            output.insert(myprofile, atIndex: 0)
                        } else { */
                            output.append(check[0]);
                        //}
                    } else {
                        nonfriends.append(members[i]);
                    }
                }
                if (Reachability.isConnectedToNetwork() && nonfriends.count>0) {
                    var params = Dictionary<String,AnyObject>();
                    params["id"] = nonfriends;
                    if (membersfind) {
                        Reachability.postToServer("profile_get.php", postdata: params, customselector: "UpdateGroupMemberList");
                    } else {
                        Reachability.postToServer("profile_get.php", postdata: params, customselector: "UpdateGroupInvitedList");
                    }
                } else {
                    if (nonfriends.count>1) {
                        var name:String = "And " + nonfriends.count.description + " other non-friends";
                        var others:Profile = Profile(name: name, url: nil, profid: nil, imagedata: UIImagePNGRepresentation(UIImage(named: "unknownprofile.png")), save: false);
                        output.append(others);
                    } else if (nonfriends.count == 1) {
                        var name:String = "And one other non-friend";
                        var others:Profile = Profile(name: name, url: nil, profid: nil, imagedata: UIImagePNGRepresentation(UIImage(named: "unknownprofile.png")), save: false);
                        output.append(others);
                    }
                }
                return output;
            } else {
                return nil;
            }
        }
    }
    class func parseProfileGet(input: NSData) -> [Profile]! {
        var error: NSError?
        if let results: Dictionary = NSJSONSerialization.JSONObjectWithData(input, options: nil, error: &error) as? Dictionary<String,AnyObject>
        {
            var output:[Profile]!=[];
            for (var i = 0; i < results.count; i++) {
                var currentprofile: AnyObject? = (results as NSDictionary).valueForKey((i).description);
                let name:String = ((currentprofile as? NSDictionary)?.valueForKey("Name")!)! as! String;
                let id:String = ((currentprofile as? NSDictionary)?.valueForKey("Profid")!)! as! String;
                let url:String = ((currentprofile as? NSDictionary)?.valueForKey("Url")!)! as! String;
                var insert:Profile = Profile(name: name, url: url, profid: id, imagedata: UIImagePNGRepresentation(UIImage(named: "unknownprofile.png")), save: false);
                output.append(insert)
            }
            return output;
        } else {
            return nil;
        }
    }
    class func downloadGroupASync(id: String) {
        if (Reachability.isConnectedToNetwork()) {
            let URLStub: String! = NSBundle.mainBundle().objectForInfoDictionaryKey("URL Stub") as! String;
            //Clean Values by escaping
            var dictsend = Dictionary<String, String>()
            dictsend["profid"] = FBSDKAccessToken.currentAccessToken().userID;
            dictsend["token"] = FBSDKAccessToken.currentAccessToken().tokenString;
            dictsend["groupid"] = id;
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
            let urlstring = URLStub + "group_single_get.php";
            let url = NSURL(string: urlstring)!;
            let session = NSURLSession.sharedSession();
            let request = NSMutableURLRequest(URL: url);
            var error: NSError? = nil;
            request.HTTPMethod = "POST";
            request.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type");
            request.HTTPBody = contentBodyAsString.dataUsingEncoding(NSUTF8StringEncoding);
            contentBodyAsString = contentBodyAsString.stringByAddingPercentEscapesUsingEncoding(NSUTF8StringEncoding)!
            let task = NSURLSession.sharedSession().dataTaskWithRequest(request) {
                (data, response, error) in
                if let results: Dictionary = NSJSONSerialization.JSONObjectWithData(data!, options: nil, error: nil) as? Dictionary<String,AnyObject>
                {
                    let name:String = results["Name"] as! String;
                    let admin:Bool = results["Admin"] as! Bool;
                    let id:String = results["GroupID"] as! String;
                    let members:NSArray = results["Members"] as! NSArray;
                    let invited:NSArray = results["Invited"] as! NSArray;
                    let memberstring = members.componentsJoinedByString(";");
                    let invitedstring = invited.componentsJoinedByString(";");
                    var params = Dictionary<String,AnyObject>();
                    params["Group"] = Group(name: name, groupid: id, memberstring: memberstring, invitedstring: invitedstring, isadmin: admin, save: false);
                    NSNotificationCenter.defaultCenter().postNotificationName("Eventory_Group_Single_Done", object: self, userInfo: params);
                }
            }
            task.resume()
        }
    }
    //MARK: Group Cell Methods
    class func generateGroupImage(memberlist: String?) -> UIImage {
        if (memberlist=="" || memberlist == nil) {
            return UIImage(named: "unknownprofile.png")!;
        } else {
            let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
            let ctx = appDelegate.managedObjectContext
            let fetchRequest = NSFetchRequest(entityName: "Profile")
            var FriendList = ctx!.executeFetchRequest(fetchRequest, error: nil) as? [Profile]
            var actualimage:[NSData!]=[];
            var members:[String] = (memberlist?.componentsSeparatedByString(";"))!;
            if (members[0] != "") {
                members = self.shuffle(members);
                for (var i = 0; i<members.count; i++){
                    var currentprof:Profile? = FriendList!.filter({return $0.profid == members[i]})[0]
                    if let check = currentprof {
                        actualimage.append(check.imagedata!);
                    }
                }
                if (members.count==0) {
                    return UIImage(named: "unknownprofile.png")!;
                } else if (members.count == 1) {
                    if (actualimage.count == 1) {
                        return UIImage(data: actualimage[0])!;
                    } else {
                        return UIImage(named: "unknownprofile.png")!;
                    }
                } else if (members.count == 2) {
                    var imagearray:[UIImage]! = [];
                    for (var i=0; i<2; i++) {
                        if (i>actualimage.count-1) {
                            imagearray.append(UIImage(named: "unknownprofile.png")!);
                        } else {
                            if (actualimage[i].length > 0) {
                                var image:UIImage? = UIImage(data: actualimage[i]);
                                imagearray.append(UIImage(data: actualimage[i])!);
                            } else {
                                imagearray.append(UIImage(named: "unknownprofile.png")!);
                            }
                        }
                    }
                    var leftimage:UIImage! = self.cropimage(imagearray[0], toRect: CGRectMake(0, 0, imagearray[0].size.width/2, imagearray[0].size.height));
                    var rightimage:UIImage! = self.cropimage(imagearray[1], toRect: CGRectMake(imagearray[0].size.width/2, 0, imagearray[0].size.width/2, imagearray[0].size.height));
                    var size:CGSize = imagearray[0].size;
                    UIGraphicsBeginImageContext(size);
                    leftimage.drawInRect(CGRectMake(0, 0, imagearray[0].size.width/2, imagearray[0].size.height));
                    rightimage.drawInRect(CGRectMake(imagearray[0].size.width/2, 0, imagearray[0].size.width/2, imagearray[0].size.height));
                    var finalimage:UIImage = UIGraphicsGetImageFromCurrentImageContext();
                    UIGraphicsEndImageContext();
                    return finalimage;
                } else if (members.count == 3) {
                    var imagearray:[UIImage]! = [];
                    for (var i=0; i<3; i++) {
                        if (i>actualimage.count-1) {
                            imagearray.append(UIImage(named: "unknownprofile.png")!);
                        } else {
                            var image:UIImage? = UIImage(data: actualimage[i]);
                            imagearray.append(UIImage(data: actualimage[i])!);
                        }
                    }
                    var leftimage:UIImage! = self.cropimage(imagearray[0], toRect: CGRectMake(0, 0, imagearray[0].size.width/2, imagearray[0].size.height));
                    var righttopimage:UIImage! = imagearray[1];
                    var rightbottomimage:UIImage! = imagearray[2];
                    var size:CGSize = imagearray[0].size;
                    UIGraphicsBeginImageContext(size);
                    leftimage.drawInRect(CGRectMake(0, 0, imagearray[0].size.width/2, imagearray[0].size.height));
                    righttopimage.drawInRect(CGRectMake(imagearray[0].size.width/2, 0, imagearray[0].size.width/2, imagearray[0].size.height/2));
                    rightbottomimage.drawInRect(CGRectMake(imagearray[0].size.width/2, imagearray[0].size.height/2, imagearray[0].size.width/2, imagearray[0].size.height/2));
                    var finalimage:UIImage = UIGraphicsGetImageFromCurrentImageContext();
                    UIGraphicsEndImageContext();
                    return finalimage;
                } else
                {
                    var imagearray:[UIImage]! = [];
                    for (var i=0; i<3; i++) {
                        if (i>actualimage.count-1) {
                            imagearray.append(UIImage(named: "unknownprofile.png")!);
                        } else {
                            var image:UIImage? = UIImage(data: actualimage[i]);
                            imagearray.append(UIImage(data: actualimage[i])!);
                        }
                    }
                    var lefttopimage:UIImage! = imagearray[0];
                    var leftbottomimage:UIImage! = imagearray[1];
                    var righttopimage:UIImage! = imagearray[2];
                    var rightbottomimage:UIImage! = imagearray[3];
                    var size:CGSize = imagearray[0].size;
                    UIGraphicsBeginImageContext(size);
                    lefttopimage.drawInRect(CGRectMake(0, 0, imagearray[0].size.width/2, imagearray[0].size.height/2));
                    leftbottomimage.drawInRect(CGRectMake(0, imagearray[0].size.height/2, imagearray[0].size.width/2, imagearray[0].size.height/2));
                    righttopimage.drawInRect(CGRectMake(imagearray[0].size.width/2, 0, imagearray[0].size.width/2, imagearray[0].size.height/2));
                    rightbottomimage.drawInRect(CGRectMake(imagearray[0].size.width/2, imagearray[0].size.height/2, imagearray[0].size.width/2, imagearray[0].size.height/2));
                    var finalimage:UIImage = UIGraphicsGetImageFromCurrentImageContext();
                    UIGraphicsEndImageContext();
                    return finalimage;
                }
            } else {
                return UIImage(named: "unknownprofile.png")!;
            }
        }
    }
    class func cropimage(imageToCrop:UIImage, toRect rect:CGRect) -> UIImage{
        var imageRef:CGImageRef = CGImageCreateWithImageInRect(imageToCrop.CGImage, rect)
        var cropped:UIImage = UIImage(CGImage:imageRef)!
        return cropped
    }
    class func getMemberString(memberlist: String) -> String {
        if (memberlist==""){
            return "";
        } else {
            let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
            let ctx = appDelegate.managedObjectContext
            let fetchRequest = NSFetchRequest(entityName: "Profile")
            var FriendList = ctx!.executeFetchRequest(fetchRequest, error: nil) as? [Profile]
            var isingroup:Bool = false;
            var output:String = "";
            let limit = 3;
            var members:[String]! = (memberlist.componentsSeparatedByString(";"));
            members = self.shuffle(members);
            //Check me
            if (members[0] != "") {
                if memberlist.rangeOfString((Globals.currentprofile?.profid!)!) != nil {
                    var currentprof:String? = members.filter({return $0 == Globals.currentprofile?.profid})[0]
                    if let check = currentprof {
                        isingroup=true;
                        members = members.filter({return $0 != Globals.currentprofile?.profid})
                    }
                }
                //Check friends
                var actual:[String!]=[];
                for (var i = 0; i<members.count; i++){
                    var currentprof:Profile? = FriendList!.filter({return $0.profid == members[i]})[0]
                    if let check = currentprof {
                        actual.append(Profile.getFirstName(currentprof!.name!));
                    }
                }
                var number = actual.count;
                if (actual.count<limit) {
                    if (actual.count==0) {
                        if (isingroup) {
                            output = "Just you!";
                        }
                    } else {
                        if (actual.count == 1) {
                            if (isingroup) {
                                output = "You and " + actual[0];
                            } else {
                                output = actual[0];
                            }
                        } else {
                            if (actual.count == 2 && !isingroup) {
                                output = actual[0] + " and " + actual[1];
                            } else {
                                if (isingroup) {
                                    output = "You, ";
                                }
                                for (var i=0; i<actual.count-1;i++) {
                                    output =   output + actual[i] + ", ";
                                }
                                output = output + "and " + actual[actual.count-1];
                            }
                        }
                    }
                } else {
                    if (isingroup) {
                        output = "You, ";
                    }
                    for (var i=0; i<limit; i++){
                        output =   output + actual[i] + ", ";
                    }
                    let remaining = actual.count - limit;
                    if (remaining == 1) {
                        output = output + " and one other";
                    } else {
                        output = output + " and " + remaining.description + " others";
                    }
                }
                let remnants = members.count - actual.count;
                if (!isingroup && actual.count==0) {
                    if (members.count==0) {
                        output = "One non-friend";
                    } else if (members.count>0) {
                        output = members.count.description + " non friends";
                    }
                }
                if (remnants == 1) {
                    output = output + " (+ one non-friend)";
                } else if (remnants>1) {
                    output = output + " (+ " + remnants.description + " other non-friends)";
                }
                return output;
            } else {
                return "";
            }
        }
    }
}
