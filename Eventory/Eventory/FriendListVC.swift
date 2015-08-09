//
//  FriendListVC.swift
//  Eventory
//
//  Created by Imran Ahmed on 14/07/2015.
//  Copyright (c) 2015 Imran Ahmed. All rights reserved.
//

import UIKit
import CoreData
class FriendListVC: UIViewController, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate, SWTableViewCellDelegate, UIPopoverPresentationControllerDelegate{
    var groupsupdated:Bool = false;
    var friendsupdated:Bool = false;
    @IBOutlet weak var friendview: UITableView!
    let refreshControl = UIRefreshControl()
    let managedObjectContext = (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext
    var FriendList:[Profile]! = []
    var GroupList:[Group]! = []
    var currentfield:UITextField?;
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.title = "Friends & Groups";
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Add, target: self, action: "CreateGroup:")
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "groupsUpdated:", name: "Eventory_Group_Saved", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "friendsUpdated:", name: "Eventory_Friends_Saved", object: nil)
        friendview.dataSource = self;
        friendview.delegate = self;
        refreshControl.addTarget(self, action: "refresh:", forControlEvents: .ValueChanged)
        refreshControl.attributedTitle = NSAttributedString(string: "Refreshing...");
        friendview.addSubview(refreshControl)
        var checktap = UITapGestureRecognizer(target: self, action: "tableViewTapped:");
        checktap.cancelsTouchesInView = false;
        self.friendview.addGestureRecognizer(checktap);
        //Deletes empty stuff
        if (Reachability.isConnectedToNetwork()) {
            friendsupdated = true; //TRUE Overrides friendsupdated function -> find another solution to problem
            groupsupdated = true;
            //Group.ClearGroupNils();
            //Profile.ClearProfileNils();
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
            //Group.ClearGroupNils();
            //Profile.ClearProfileNils();
            var fetchRequest = NSFetchRequest(entityName: "Profile")
            FriendList = (self.managedObjectContext!.executeFetchRequest(fetchRequest, error: nil) as? [Profile])!
            fetchRequest = NSFetchRequest(entityName: "Group")
            GroupList = (self.managedObjectContext!.executeFetchRequest(fetchRequest, error: nil) as? [Group])!
            sort()
        }
        // Do any additional setup after loading the view.
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func adaptivePresentationStyleForPresentationController(controller: UIPresentationController) -> UIModalPresentationStyle {
        return UIModalPresentationStyle.None
    }
    func CreateGroup(sender: UIBarButtonItem) {
        let popoverVC = storyboard?.instantiateViewControllerWithIdentifier("GroupCreateVC") as! GroupCreateVC!
        popoverVC.memberstring = "";
        popoverVC.itemname = "";
        popoverVC.GroupList = GroupList;
        popoverVC.FriendList = FriendList;
        var height = 2*((Int(self.view.center.y)-64));
        var width = (Int(self.view.frame.size.width)-75);
        popoverVC.preferredContentSize = CGSizeMake(CGFloat(width), CGFloat(height))
        popoverVC.modalPresentationStyle = .Popover
        let popover = popoverVC.popoverPresentationController!
        popover.delegate = self
        popover.sourceView  = self.view
        popover.sourceRect = self.view.frame;
        popover.permittedArrowDirections = UIPopoverArrowDirection.allZeros;
        presentViewController(popoverVC, animated: true, completion: nil);
    }
    
    func tableViewTapped (tap: UITapGestureRecognizer) {
        var point:CGPoint = tap.locationInView(tap.view);
        for (var i = 0; i<GroupList.count; i++) {
            var index = NSIndexPath(forRow: i, inSection: 0);
            var cell: SWTableViewCell = (self.friendview.cellForRowAtIndexPath(index) as? SWTableViewCell)!
            cell.hideUtilityButtonsAnimated(true);
        }
        let textField = findFirstResponder(inView: friendview) as? UITextField;
        if let check = textField {
            var point:CGPoint = textField!.convertPoint(CGPointZero, toView: self.friendview);
            var index:NSIndexPath = self.friendview.indexPathForRowAtPoint(point)!;
            if (index.section == 0) {
                if (count(textField!.text)>0) {
                    if (GroupList[index.row].name! != textField!.text) {
                        var alert = UIAlertController(title: "Rename Group", message: ("Would you like to rename '" + GroupList[index.row].name! + "' to '" + textField!.text + "'?"), preferredStyle: UIAlertControllerStyle.Alert)
                        alert.addAction(UIAlertAction(title: "Nope!", style: .Default, handler: { action in
                            textField!.text = self.GroupList[index.row].name!;
                            textField?.resignFirstResponder();
                        }))
                        alert.addAction(UIAlertAction(title: "Yep!", style: .Cancel, handler: { action in
                            if (Reachability.isConnectedToNetwork()) {
                                var params = Dictionary<String,AnyObject>();
                                params["groupid"] = self.GroupList[index.row].groupid;
                                params["name"] = textField!.text;
                                Reachability.postToServer("group_rename.php", postdata: params, customselector: "GroupRefresh")
                                textField?.resignFirstResponder();
                            } else {
                                RKDropdownAlert.title("Can't Rename!", message: "You are currently not connected to the internet! :(");
                                textField!.text = self.GroupList[index.row].name!;
                                textField?.resignFirstResponder();
                            }
                        }))
                        self.presentViewController(alert, animated: true, completion: nil)
                    }
                } else {
                    textField!.text = GroupList[index.row].name!
                }
            }
        }
        self.view.endEditing(true);
    }
    //MARK: Updating Methods
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
        for (var i = 0; i<GroupList.count; i++) {
            var index = NSIndexPath(forRow: i, inSection: 0);
            var cell: SWTableViewCell = (self.friendview.cellForRowAtIndexPath(index) as? SWTableViewCell)!
            cell.hideUtilityButtonsAnimated(true);
        }
        if (Reachability.isConnectedToNetwork()) {
            groupsupdated=false;
            friendsupdated = false;
            getData();
        } else {
            groupsupdated=true;
            friendsupdated = true;
            RKDropdownAlert.title("Offline!", message: "You are currently not connected to the internet! :(");
            //Group.ClearGroupNils();
            //Profile.ClearProfileNils();
            var fetchRequest = NSFetchRequest(entityName: "Profile")
            FriendList = (self.managedObjectContext!.executeFetchRequest(fetchRequest, error: nil) as? [Profile])!
            fetchRequest = NSFetchRequest(entityName: "Group")
            GroupList = (self.managedObjectContext!.executeFetchRequest(fetchRequest, error: nil) as? [Group])!
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
            if (Reachability.isConnectedToNetwork()) {
                var friendid = Profile.saveFriendstoCoreData(result);
                var fetchRequest = NSFetchRequest(entityName: "Profile")
                self.FriendList = self.managedObjectContext!.executeFetchRequest(fetchRequest, error: nil) as? [Profile]
                var paramstwo = Dictionary<String,AnyObject>();
                paramstwo["type"] = "0";
                Reachability.postToServer("group_get.php", postdata: paramstwo, customselector: "MainGroupLoad")
            } else {
                RKDropdownAlert.title("Offline!", message: "You are currently not connected to the internet! :(");
            }
            
        })
        connection.start();
        
    }
    //MARK: Table View & UITextField methods
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        if (tableView == self.friendview) {
            return 2
        } else {
            return 0
        }
    }
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if (tableView == self.friendview) {
            if (GroupList.count == 0 && FriendList.count == 0) {
                return nil;
            }
            if (GroupList.count == 0) {
                if (section == 0) {
                    return "Friends";
                } else {
                    return nil;
                }
            } else {
                if (section == 0) {
                    return "Groups";
                } else if (section == 1) {
                    return "Friends";
                } else {
                    return nil;
                }
            }
        } else {
            return nil;
        }
    }
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if (tableView == self.friendview) {
            if (GroupList.count == 0 && FriendList.count == 0) {
                return 0;
            }
            if (GroupList.count == 0) {
                if (section == 0) {
                    return FriendList.count;
                } else {
                    return 0;
                }
            } else {
                if (section == 0) {
                    return GroupList.count;
                } else if (section == 1) {
                    return FriendList.count;
                } else {
                    return 0;
                }
            }
        } else {
            return 0;
        }
    }
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if (tableView == self.friendview) {
            if (GroupList.count == 0) {
                if (indexPath.section == 0) {
                    var cell = tableView.dequeueReusableCellWithIdentifier("Friend") as! FriendCell;
                    cell.friendlabel.text = FriendList[indexPath.row].name;
                    cell.friendimage.image = UIImage(data: FriendList[indexPath.row].imagedata!);
                    cell.profid = FriendList[indexPath.row].profid;
                    return cell;
                } else {
                    return UITableViewCell();
                }
            } else {
                if (indexPath.section == 0) {
                    var cell = tableView.dequeueReusableCellWithIdentifier("Group") as! GroupCell;
                    var currentprof = GroupList[indexPath.row];
                    cell.grouptextfield.text = currentprof.name;
                    var right:NSMutableArray = NSMutableArray();
                    var left:NSMutableArray = NSMutableArray();
                    var imagesize:CGSize = CGSizeMake(20,20);
                    left.sw_addUtilityButtonWithColor(Schemes.returnColor("Carrot", alpha: 1.0), icon: imageResize(UIImage(named:"group_list.png")!, sizeChange:imagesize));
                    left.sw_addUtilityButtonWithColor(Schemes.returnColor("Nephritis", alpha: 1.0), icon: imageResize(UIImage(named: "group_add.png")!, sizeChange: imagesize));
                    right.sw_addUtilityButtonWithColor(Schemes.returnColor("Concrete", alpha: 1.0), icon: imageResize(UIImage(named: "exit.png")!, sizeChange: imagesize));
                    if (currentprof.isadmin) {
                        cell.grouptextfield.enabled = true;
                        cell.adminlabel.hidden = false;
                        right.sw_addUtilityButtonWithColor(Schemes.returnColor("Alizarin", alpha: 1.0), icon: imageResize(UIImage(named: "delete.png")!, sizeChange: imagesize));
                    } else {
                        cell.grouptextfield.enabled = false;
                        cell.adminlabel.hidden = true;
                    }
                    cell.setLeftUtilityButtons(left as [AnyObject], withButtonWidth: 40);
                    cell.setRightUtilityButtons(right as [AnyObject], withButtonWidth: 40);
                    cell.groupimage.image = UIImage(named: "unkownprofile.png");
                    cell.memberlabel.text = Group.getMemberString(currentprof.memberstring!);
                    cell.grouptextfield.delegate = self;
                    cell.memberlist = currentprof.memberstring;
                    cell.delegate = self;
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
        } else {
            return UITableViewCell();
        }
    }
    func imageResize (imageObj:UIImage, sizeChange:CGSize)-> UIImage{
        let hasAlpha = true;
        let scale: CGFloat = 0.0 // Automatically use scale factor of main screen
        UIGraphicsBeginImageContextWithOptions(sizeChange, !hasAlpha, scale)
        imageObj.drawInRect(CGRect(origin: CGPointZero, size: sizeChange))
        let scaledImage = UIGraphicsGetImageFromCurrentImageContext()
        return scaledImage
    }
    //MARK: Text Field Methods
    func textFieldShouldBeginEditing(textField: UITextField) -> Bool {
        return true;
    }
    func textFieldDidBeginEditing(textField: UITextField) {
        currentfield = textField;
        var timer = NSTimer.scheduledTimerWithTimeInterval(0.1, target: self, selector: "timerticked", userInfo: nil, repeats: false);
    }
    func timerticked() {
        let textField = currentfield;
        var point:CGPoint = textField!.convertPoint(CGPointZero, toView: self.friendview);
        point = CGPointMake(0, point.y);
        var index:NSIndexPath = self.friendview.indexPathForRowAtPoint(point)!;
        var cell: GroupCell = (self.friendview.cellForRowAtIndexPath(index) as? GroupCell)!;
        if (cell.cellState != SWCellState.CellStateCenter) {
            cell.hideUtilityButtonsAnimated(true);
        }
        cell.hideUtilityButtonsAnimated(true);
    }
    func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
        var timer = NSTimer.scheduledTimerWithTimeInterval(0.1, target: self, selector: "timerticked", userInfo: nil, repeats: false);
        return true;
    }
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        var point:CGPoint = textField.convertPoint(CGPointZero, toView: self.friendview);
        var index:NSIndexPath = self.friendview.indexPathForRowAtPoint(point)!;
        if (index.section == 0) {
            if (count(textField.text)>0) {
                if (GroupList[index.row].name! != textField.text) {
                    var alert = UIAlertController(title: "Rename Group", message: ("Would you like to rename '" + GroupList[index.row].name! + "' to '" + textField.text + "'?"), preferredStyle: UIAlertControllerStyle.Alert)
                    alert.addAction(UIAlertAction(title: "Nope!", style: .Cancel, handler: { action in
                        textField.text = self.GroupList[index.row].name!;
                    }))
                    alert.addAction(UIAlertAction(title: "Yep!", style: .Default, handler: { action in
                        if (Reachability.isConnectedToNetwork()) {
                            var params = Dictionary<String,AnyObject>();
                            params["groupid"] = self.GroupList[index.row].groupid;
                            params["name"] = textField.text;
                            self.GroupList[index.row].name = textField.text;
                            Reachability.postToServer("group_rename.php", postdata: params, customselector: "GroupRefresh")
                        } else {
                            RKDropdownAlert.title("Can't Rename!", message: "You are currently not connected to the internet! :(");
                            textField.text = self.GroupList[index.row].name!;
                        }
                    }))
                    self.presentViewController(alert, animated: true, completion: nil)
                }
            } else {
                textField.text = GroupList[index.row].name!
            }
        }
        return true
    }
    //MARK: Swipeable Table View Methods
    func findFirstResponder(inView view: UIView) -> UIView? {
        for subView in view.subviews as! [UIView] {
            if subView.isFirstResponder() {
                return subView
            }
            
            if let recursiveSubView = self.findFirstResponder(inView: subView) {
                return recursiveSubView
            }
        }
        
        return nil
    }
    func swipeableTableViewCellShouldHideUtilityButtonsOnSwipe(cell: SWTableViewCell!) -> Bool {
        return true;
    }
    func swipeableTableViewCell(cell: SWTableViewCell!, scrollingToState state: SWCellState) {
        if (!(state == SWCellState.CellStateCenter)) {
            let textField = findFirstResponder(inView: friendview) as? UITextField;
            textField?.resignFirstResponder()
        }
    }
    func swipeableTableViewCell(cell: SWTableViewCell!, didTriggerLeftUtilityButtonWithIndex index: Int) {
        cell.hideUtilityButtonsAnimated(true);
        var indexpath:NSIndexPath = self.friendview.indexPathForCell(cell)!;
        if (index == 0) {
            let popoverVC = storyboard?.instantiateViewControllerWithIdentifier("PopoverGroupList") as! GroupListPopoverVC!
            popoverVC.currentgroup = Group(name: GroupList[indexpath.row].name, groupid: GroupList[indexpath.row].groupid, memberstring: GroupList[indexpath.row].memberstring, invitedstring: GroupList[indexpath.row].invitedstring, isadmin: GroupList[indexpath.row].isadmin, save: false)
            var members:[String] = (GroupList[indexpath.row].memberstring?.componentsSeparatedByString(";"))!;
            var invited:[String] = (GroupList[indexpath.row].invitedstring?.componentsSeparatedByString(";"))!;
            var height:Int;
            if (members.count>0 && invited.count>0) {
                height = members.count*70 + invited.count*70 + 44;
            } else if (members.count>0){
                height = members.count*70 + 22;
            } else {
                height = invited.count*70 + 22;
            }
            if (height > 2*((Int(self.view.center.y)-64))) {
                height = 2*((Int(self.view.center.y)-64));
            }
            var width = (Int(self.view.frame.size.width)-75);
            popoverVC.width = CGFloat(width);
            popoverVC.preferredContentSize = CGSizeMake(CGFloat(width), CGFloat(height))
            popoverVC.modalPresentationStyle = .Popover
            let popover = popoverVC.popoverPresentationController!
            popover.delegate = self
            popover.sourceView  = self.view
            popover.sourceRect = self.view.frame;
            popover.permittedArrowDirections = UIPopoverArrowDirection.allZeros;
            presentViewController(popoverVC, animated: true, completion: nil);
        }
        if (index == 1) {
            let popoverVC = storyboard?.instantiateViewControllerWithIdentifier("InviteVC") as! InviteVC!
            popoverVC.memberstring = GroupList[indexpath.row].invitedstring!;
            popoverVC.itemname = GroupList[indexpath.row].name!
            var sendGroupList = GroupList;
            sendGroupList.removeAtIndex(indexpath.row);
            popoverVC.GroupList = sendGroupList;
            popoverVC.FriendList = FriendList;
            var height = 2*((Int(self.view.center.y)-64));
            var width = (Int(self.view.frame.size.width)-75);
            popoverVC.preferredContentSize = CGSizeMake(CGFloat(width), CGFloat(height))
            popoverVC.modalPresentationStyle = .Popover
            let popover = popoverVC.popoverPresentationController!
            popover.delegate = self
            popover.sourceView  = self.view
            popover.sourceRect = self.view.frame;
            popover.permittedArrowDirections = UIPopoverArrowDirection.allZeros;
            presentViewController(popoverVC, animated: true, completion: nil);
            
        }
    }
    func swipeableTableViewCell(cell: SWTableViewCell!, didTriggerRightUtilityButtonWithIndex index: Int) {
        cell.hideUtilityButtonsAnimated(true);
        var indexpath:NSIndexPath = self.friendview.indexPathForCell(cell)!;
        if (index == 0) {
            var alert = UIAlertController(title: "Leave Group", message: ("Are you sure you want to leave the group '" + GroupList[indexpath.row].name! + "'?"), preferredStyle: UIAlertControllerStyle.Alert)
            alert.addAction(UIAlertAction(title: "Nope!", style: .Cancel, handler: { action in
            }))
            alert.addAction(UIAlertAction(title: "Yep!", style: .Default, handler: { action in
                if (Reachability.isConnectedToNetwork()) {
                    /*
                    var params = Dictionary<String,AnyObject>();
                    params["groupid"] = self.GroupList[indexpath.row].groupid;
                    params["name"] = textField.text;
                    Reachability.postToServer("group_rename.php", postdata: params, customselector: "GroupRefresh")
                    */
                } else {
                    RKDropdownAlert.title("Can't Leave!", message: "You are currently not connected to the internet! :(");
                }
            }))
            self.presentViewController(alert, animated: true, completion: nil)
            
        }
        if (index == 1) {
            var alert = UIAlertController(title: "Delete Group", message: ("Are you sure you want to delete the group '" + GroupList[indexpath.row].name! + "'?"), preferredStyle: UIAlertControllerStyle.Alert)
            alert.addAction(UIAlertAction(title: "Nope!", style: .Cancel, handler: { action in
            }))
            alert.addAction(UIAlertAction(title: "Yep!", style: .Default, handler: { action in
                if (Reachability.isConnectedToNetwork()) {
                    /*
                    var params = Dictionary<String,AnyObject>();
                    params["groupid"] = self.GroupList[indexpath.row].groupid;
                    params["name"] = textField.text;
                    Reachability.postToServer("group_rename.php", postdata: params, customselector: "GroupRefresh")
                    */
                } else {
                    RKDropdownAlert.title("Can't Delete!", message: "You are currently not connected to the internet! :(");
                }
            }))
            self.presentViewController(alert, animated: true, completion: nil)
            
        }
    }
    
}