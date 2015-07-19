//
//  FriendListVC.swift
//  Eventory
//
//  Created by Imran Ahmed on 14/07/2015.
//  Copyright (c) 2015 Imran Ahmed. All rights reserved.
//

import UIKit
import CoreData
class FriendListVC: UIViewController, UITableViewDelegate, UITableViewDataSource {
    var groupsupdated:Bool = false;
    var friendsupdated:Bool = false;
    @IBOutlet weak var friendview: UITableView!
    let refreshControl = UIRefreshControl()
    let managedObjectContext = (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext
    var FriendList:[Profile]! = []
    var GroupList:[Group]! = []
    override func viewDidLoad() {
        super.viewDidLoad()
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "groupsUpdated:", name: "Eventory_Group_Saved", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "friendsUpdated:", name: "Eventory_Friends_Saved", object: nil)
        friendview.dataSource = self;
        friendview.delegate = self;
        refreshControl.addTarget(self, action: "refresh:", forControlEvents: .ValueChanged)
        refreshControl.attributedTitle = NSAttributedString(string: "Refreshing...");
        friendview.addSubview(refreshControl)
        //Deletes empty stuff
        if (Reachability.isConnectedToNetwork()) {
            friendsupdated = true; //Overrides friendsupdated function -> found another solution to problem
            Profile.ClearProfileNils();
            var fetchRequest = NSFetchRequest(entityName: "Profile")
            FriendList = (self.managedObjectContext!.executeFetchRequest(fetchRequest, error: nil) as? [Profile])!
            fetchRequest = NSFetchRequest(entityName: "Group")
            GroupList = (self.managedObjectContext!.executeFetchRequest(fetchRequest, error: nil) as? [Group])!
            sort()
            getData();
        } else {
            groupsupdated = true;
            friendsupdated = true;
            RKDropdownAlert.title("Offline!", message: "You are currently not connected to the internet! :(");
            Profile.ClearProfileNils();
            var fetchRequest = NSFetchRequest(entityName: "Profile")
            FriendList = (self.managedObjectContext!.executeFetchRequest(fetchRequest, error: nil) as? [Profile])!
            fetchRequest = NSFetchRequest(entityName: "Group")
            GroupList = (self.managedObjectContext!.executeFetchRequest(fetchRequest, error: nil) as? [Group])!
            sort()
        }
        // Do any additional setup after loading the view.
    }
    func groupsUpdated(notification: NSNotification) {
        let currentgroupslist = notification.userInfo!["Groups"] as! [Group]!;
        GroupList = currentgroupslist;
        groupsupdated = true;
        sort()
    }
    func friendsUpdated(notification: NSNotification) {
        friendsupdated = true;
    }
    func refresh(refreshControl: UIRefreshControl) {
        if (Reachability.isConnectedToNetwork()) {
            groupsupdated=false;
            friendsupdated = false;
            getData();
        } else {
            groupsupdated=true;
            friendsupdated = true;
            RKDropdownAlert.title("Offline!", message: "You are currently not connected to the internet! :(");
            var fetchRequest = NSFetchRequest(entityName: "Profile")
            let predicate = NSPredicate(format: "profid == nil OR profid == ''");
            fetchRequest.predicate = predicate;
            FriendList = (self.managedObjectContext!.executeFetchRequest(fetchRequest, error: nil) as? [Profile])!
            for (var i = 0; i < FriendList.count ; i++) {
                self.managedObjectContext?.deleteObject(FriendList[i]);
            }
            self.managedObjectContext?.save(nil)
            fetchRequest = NSFetchRequest(entityName: "Profile")
            FriendList = (self.managedObjectContext!.executeFetchRequest(fetchRequest, error: nil) as? [Profile])!
            sort()
        }
    }
    func sort() {
        if (friendsupdated) {
        FriendList = Profile.SortFriends(FriendList);
        }
        GroupList = Group.SortGroups(GroupList);
        dispatch_async(dispatch_get_main_queue()){
            UIView.transitionWithView(self.friendview, duration:0.1, options: UIViewAnimationOptions.TransitionCrossDissolve,
                animations: {
                    self.friendview.reloadData();
                },
                completion: nil)
        }
        refreshControl.endRefreshing()
    }
    func getData() {
        let connection = FBSDKGraphRequestConnection();
        let parameters = ["method": "GET"];
        let friendrequest = FBSDKGraphRequest(graphPath: "/me?fields=friends.limit(5000)%7Bpicture.width(150).height(150),name%7D", parameters: parameters, HTTPMethod: "POST");
        connection.addRequest(friendrequest, completionHandler: { (connection:FBSDKGraphRequestConnection!, result:AnyObject!, error:NSError!) -> Void in
            var friendid = Profile.saveFriendstoCoreData(result);
            var fetchRequest = NSFetchRequest(entityName: "Profile")
            self.FriendList = self.managedObjectContext!.executeFetchRequest(fetchRequest, error: nil) as? [Profile]
            var paramstwo = Dictionary<String,AnyObject>();
            paramstwo["type"] = "0";
            Reachability.postToServer("group_get.php", postdata: paramstwo, customselector: "MainGroupLoad")
        })
        connection.start();
        
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    //Table View methods
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 2
    }
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if (section == 0) {
            return "Groups";
        } else if (section == 1) {
            return "Friends";
        } else {
            return nil;
        }
    }
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if (section == 0) {
            return GroupList.count;
        } else if (section == 1) {
            return FriendList.count;
        } else {
            return 0;
        }
    }
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if (indexPath.section == 0) {
            var cell = tableView.dequeueReusableCellWithIdentifier("Group") as! GroupCell;
            var currentprof = GroupList[indexPath.row];
            var ting = GroupList;
            cell.grouplabel.text = currentprof.name;
            cell.groupimage.image = UIImage(named: "unkownprofile.png");
            cell.memberlabel.text = Group.getMemberString(currentprof.memberstring);
            cell.memberlist = currentprof.memberstring;
            if (groupsupdated) {
            cell.groupimage.image = Group.generateGroupImage(currentprof.memberstring);
            }
            return cell;
        } else if (indexPath.section == 1) {
            var cell = tableView.dequeueReusableCellWithIdentifier("Friend") as! FriendCell;
            cell.friendlabel.text = FriendList[indexPath.row].name;
            cell.friendimage.image = UIImage(data: FriendList[indexPath.row].imagedata!);
            cell.profid = FriendList[indexPath.row].profid;
            return cell;
        } else {
            return UITableViewCell();
        }
    }
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
    }
    
}