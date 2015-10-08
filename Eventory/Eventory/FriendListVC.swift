//
//  FriendListVC.swift
//  Eventory
//
//  Created by Imran Ahmed on 14/07/2015.
//  Copyright (c) 2015 Imran Ahmed. All rights reserved.
//

import UIKit
import CoreData
class FriendListVC: UIViewController, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate, SWTableViewCellDelegate, UIPopoverPresentationControllerDelegate, UISearchControllerDelegate, UISearchResultsUpdating {
    var groupsupdated:Bool = false;
    var friendsupdated:Bool = false;
    @IBOutlet weak var friendview: UITableView!
    let refreshControl = UIRefreshControl()
    let managedObjectContext = (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext
    var FriendList:[Profile]! = [];
    var GroupList:[Group]! = [];
    var filteredFriendList:[Profile]! = [];
    var filteredGroupList:[Group]! = [];
    var currentfield:UITextField?;
    let searchController = UISearchController(searchResultsController: nil);
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.title = "Friends & Groups";
        //Setup left button
        let left:UIBarButtonItem = UIBarButtonItem(image: imageResize(UIImage(named: "exit.png")!, sizeChange: CGSizeMake(21, 21)).imageWithRenderingMode(UIImageRenderingMode.AlwaysTemplate), style: UIBarButtonItemStyle.Plain, target: self, action: "LeftDeclinedLoad:");
        self.navigationItem.rightBarButtonItems = NSArray(array: [UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Add, target: self, action: "CreateGroup:"), left]) as? [UIBarButtonItem];
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "groupsUpdated:", name: "Eventory_Group_Saved", object: nil)
        //NSNotificationCenter.defaultCenter().addObserver(self, selector: "friendsUpdated:", name: "Eventory_Friends_Saved", object: nil) //NOT IMPLEMENTED AS YET - FRIEND LIST NEVER REFRESHED!!
        friendview.dataSource = self;
        friendview.delegate = self;
        refreshControl.addTarget(self, action: "refresh:", forControlEvents: .ValueChanged)
        refreshControl.attributedTitle = NSAttributedString(string: "Refreshing...");
        friendview.addSubview(refreshControl)
        //Add search bar
        self.definesPresentationContext = true;
        searchController.searchResultsUpdater = self
        searchController.hidesNavigationBarDuringPresentation = false
        searchController.dimsBackgroundDuringPresentation = false
        searchController.searchBar.sizeToFit()
        searchController.searchBar.placeholder = "Search Friends/Groups"
        self.friendview.tableHeaderView = searchController.searchBar
        let checktap = UITapGestureRecognizer(target: self, action: "tableViewTapped:");
        checktap.cancelsTouchesInView = false;
        self.friendview.addGestureRecognizer(checktap);
        //Deletes empty stuff
        if (Reachability.isConnectedToNetwork()) {
            friendsupdated = true;
            groupsupdated = true;
            var fetchRequest = NSFetchRequest(entityName: "Profile")
            FriendList = Profile.SortFriends(((try? self.managedObjectContext!.executeFetchRequest(fetchRequest)) as? [Profile])!);
            fetchRequest = NSFetchRequest(entityName: "Group")
            GroupList = Group.SortGroups(((try? self.managedObjectContext!.executeFetchRequest(fetchRequest)) as? [Group])!);
            for (var i = 0; i < GroupList.count; i++) {
                GroupData.generateentry(&Globals.localgroups, input: GroupList[i]);
            }
            sort()
        } else {
            groupsupdated = true;
            friendsupdated = true;
            RKDropdownAlert.title("Offline!", message: "You are currently not connected to the internet! :(");
            //Group.ClearGroupNils();
            //Profile.ClearProfileNils();
            var fetchRequest = NSFetchRequest(entityName: "Profile")
            FriendList = Profile.SortFriends(((try? self.managedObjectContext!.executeFetchRequest(fetchRequest)) as? [Profile])!);
            fetchRequest = NSFetchRequest(entityName: "Group")
            GroupList = Group.SortGroups(((try? self.managedObjectContext!.executeFetchRequest(fetchRequest)) as? [Group])!);
            sort()
        }
        // Do any additional setup after loading the view.
    }
    override func viewWillAppear(animated: Bool) {
        if (Reachability.isConnectedToNetwork() && Globals.profloaded && Globals.groupschanged) {
            getData();
        }
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    func imageResize (imageObj:UIImage, sizeChange:CGSize)-> UIImage{
        let hasAlpha = true;
        let scale: CGFloat = 0.0 // Automatically use scale factor of main screen
        UIGraphicsBeginImageContextWithOptions(sizeChange, !hasAlpha, scale)
        imageObj.drawInRect(CGRect(origin: CGPointZero, size: sizeChange))
        let scaledImage = UIGraphicsGetImageFromCurrentImageContext()
        return scaledImage
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
        let height = 2*((Int(self.view.center.y)-64));
        let width = (Int(self.view.frame.size.width)-75);
        popoverVC.preferredContentSize = CGSizeMake(CGFloat(width), CGFloat(height))
        popoverVC.modalPresentationStyle = .Popover
        let popover = popoverVC.popoverPresentationController!
        popover.delegate = self
        popover.sourceView  = self.view
        popover.sourceRect = self.view.frame;
        popover.permittedArrowDirections = UIPopoverArrowDirection();
        presentViewController(popoverVC, animated: true, completion: nil);
    }
    func LeftDeclinedLoad(sender: UIBarButtonItem) {
        dispatch_async(dispatch_get_main_queue(), {
            self.performSegueWithIdentifier("FriendtoLeftDeclined", sender: nil);
        })
    }
    func tableViewTapped (tap: UITapGestureRecognizer) {
        if self.searchController.searchBar.isFirstResponder() {
            self.searchController.searchBar.resignFirstResponder();
        }
        if (searchController.active) {
            for (var i = 0; i<filteredGroupList.count; i++) {
                let index = NSIndexPath(forRow: i, inSection: 0);
                let cell: SWTableViewCell = (self.friendview.cellForRowAtIndexPath(index) as? SWTableViewCell)!
                cell.hideUtilityButtonsAnimated(true);
            }
            let textField = findFirstResponder(inView: friendview) as? UITextField;
            if let _ = textField {
                let point:CGPoint = textField!.convertPoint(CGPointZero, toView: self.friendview);
                let index:NSIndexPath = self.friendview.indexPathForRowAtPoint(point)!;
                if (index.section == 0) {
                    if (textField!.text!.characters.count>0) {
                        if (filteredGroupList[index.row].name! != textField!.text) {
                            let alert = UIAlertController(title: "Rename Group", message: ("Would you like to rename '" + filteredGroupList[index.row].name! + "' to '" + textField!.text! + "'?"), preferredStyle: UIAlertControllerStyle.Alert)
                            alert.addAction(UIAlertAction(title: "Nope!", style: .Default, handler: { action in
                                textField!.text = self.filteredGroupList[index.row].name!;
                                textField?.resignFirstResponder();
                            }))
                            alert.addAction(UIAlertAction(title: "Yep!", style: .Cancel, handler: { action in
                                if (Reachability.isConnectedToNetwork()) {
                                    var params = Dictionary<String,AnyObject>();
                                    params["groupid"] = self.filteredGroupList[index.row].groupid;
                                    params["name"] = textField!.text;
                                    Reachability.postToServer("group_rename.php", postdata: params, customselector: "GroupRefresh")
                                    textField?.resignFirstResponder();
                                } else {
                                    RKDropdownAlert.title("Can't Rename!", message: "You are currently not connected to the internet! :(");
                                    textField!.text = self.filteredGroupList[index.row].name!;
                                    textField?.resignFirstResponder();
                                }
                            }))
                            self.presentViewController(alert, animated: true, completion: nil)
                        }
                    } else {
                        textField!.text = filteredGroupList[index.row].name!
                    }
                }
            }
        } else {
            for (var i = 0; i<GroupList.count; i++) {
                let index = NSIndexPath(forRow: i, inSection: 0);
                let cell: SWTableViewCell = (self.friendview.cellForRowAtIndexPath(index) as? SWTableViewCell)!
                cell.hideUtilityButtonsAnimated(true);
            }
            let textField = findFirstResponder(inView: friendview) as? UITextField;
            if let _ = textField {
                let point:CGPoint = textField!.convertPoint(CGPointZero, toView: self.friendview);
                let index:NSIndexPath = self.friendview.indexPathForRowAtPoint(point)!;
                if (index.section == 0) {
                    if (textField!.text!.characters.count>0) {
                        if (GroupList[index.row].name! != textField!.text) {
                            let alert = UIAlertController(title: "Rename Group", message: ("Would you like to rename '" + GroupList[index.row].name! + "' to '" + textField!.text! + "'?"), preferredStyle: UIAlertControllerStyle.Alert)
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
        }
        self.view.endEditing(true);
    }
    //MARK: Search Bar Methods
    func updateSearchResultsForSearchController(searchinputController: UISearchController) {
        filteredFriendList.removeAll(keepCapacity: false);
        filteredGroupList.removeAll(keepCapacity: false);
        let predicate:NSPredicate = NSPredicate(format: "SELF.name CONTAINS[c] %@", searchinputController.searchBar.text!);
        filteredFriendList = FriendList.filter({predicate.evaluateWithObject($0)});
        filteredGroupList = GroupList.filter({predicate.evaluateWithObject($0)});
        self.friendview.reloadData();
    }
    //MARK: Updating Methods
    func timeout() {
        if refreshControl.refreshing {
            refreshControl.endRefreshing();
            groupsupdated=true;
            friendsupdated = true;
        }
    }
    func groupsUpdated(notification: NSNotification) {
        let fetchRequest = NSFetchRequest(entityName: "Group")
        self.GroupList = Group.SortGroups((try? self.managedObjectContext!.executeFetchRequest(fetchRequest)) as? [Group]);
        for (var i = 0; i < GroupList.count; i++) {
            GroupData.generateentry(&Globals.localgroups, input: GroupList[i]);
        }
        groupsupdated = true;
        sort()
    }
    func refresh(refreshControl: UIRefreshControl) {
        for (var i = 0; i<GroupList.count; i++) {
            let index = NSIndexPath(forRow: i, inSection: 0);
            let cell: SWTableViewCell = (self.friendview.cellForRowAtIndexPath(index) as? SWTableViewCell)!
            cell.hideUtilityButtonsAnimated(true);
        }
        if (Reachability.isConnectedToNetwork()) {
            groupsupdated=false;
            friendsupdated = false;
            getData();
            _ = NSTimer.scheduledTimerWithTimeInterval(4, target: self, selector: "timeout", userInfo: nil, repeats: false);
        } else {
            groupsupdated=true;
            friendsupdated = true;
            RKDropdownAlert.title("Offline!", message: "You are currently not connected to the internet! :(");
            var fetchRequest = NSFetchRequest(entityName: "Profile")
            FriendList = Profile.SortFriends(((try? self.managedObjectContext!.executeFetchRequest(fetchRequest)) as? [Profile])!);
            fetchRequest = NSFetchRequest(entityName: "Group")
            GroupList = Group.SortGroups(((try? self.managedObjectContext!.executeFetchRequest(fetchRequest)) as? [Group])!);
            for (var i = 0; i < GroupList.count; i++) {
                GroupData.generateentry(&Globals.localgroups, input: GroupList[i]);
            }
            sort()
        }
    }
    func sort() {
        if (self.refreshControl.refreshing) {
            self.refreshControl.endRefreshing()
        }
        dispatch_async(dispatch_get_main_queue()){
            UIView.transitionWithView(self.friendview, duration:0.1, options: UIViewAnimationOptions.TransitionCrossDissolve,
                animations: {
                    self.searchController.active = false;
                    self.friendview.reloadData();
                },
                completion: nil)
        }
    }
    func getData() {
        let connection = FBSDKGraphRequestConnection();
        let parameters = ["method": "GET"];
        let friendrequest = FBSDKGraphRequest(graphPath: "/me?fields=friends.limit(5000)%7Bpicture.width(150).height(150),name%7D", parameters: parameters, HTTPMethod: "POST");
        connection.addRequest(friendrequest, completionHandler: { (connection:FBSDKGraphRequestConnection!, result:AnyObject!, error:NSError!) -> Void in
            if (Reachability.isConnectedToNetwork()) {
                if (result != nil) {
                    _ = Profile.saveFriendstoCoreData(result);
                }
                let fetchRequest = NSFetchRequest(entityName: "Profile")
                self.FriendList = Profile.SortFriends(((try? self.managedObjectContext!.executeFetchRequest(fetchRequest)) as? [Profile])!);
                self.friendsupdated = true;
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
            if (searchController.active && searchController.searchBar.text!.characters.count > 0) {
                if (filteredGroupList.count > 0 && filteredFriendList.count > 0) {
                    return 2;
                } else if (filteredGroupList.count == 0 && filteredFriendList.count > 0) {
                    return 1;
                } else if (filteredGroupList.count > 0 && filteredFriendList.count == 0) {
                    return 1;
                    
                }else {
                    return 0;
                }
            } else {
                if (GroupList.count > 0 && FriendList.count > 0) {
                    return 2;
                } else if (GroupList.count == 0 && FriendList.count > 0) {
                    return 1;
                } else {
                    return 0;
                }
            }
        } else {
            return 0
        }
    }
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if (tableView == self.friendview) {
            if (searchController.active && searchController.searchBar.text!.characters.count > 0) {
                if (filteredGroupList.count == 0 && filteredFriendList.count == 0) {
                    return nil;
                }
                if (filteredGroupList.count == 0) {
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
            }
        } else {
            return nil;
        }
    }
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if (tableView == self.friendview) {
            if (searchController.active && searchController.searchBar.text!.characters.count > 0) {
                if (filteredGroupList.count == 0 && filteredFriendList.count == 0) {
                    return 0;
                }
                if (filteredGroupList.count == 0) {
                    if (section == 0) {
                        return filteredFriendList.count;
                    } else {
                        return 0;
                    }
                } else {
                    if (section == 0) {
                        return filteredGroupList.count;
                    } else if (section == 1) {
                        return filteredFriendList.count;
                    } else {
                        return 0;
                    }
                }
            } else {
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
            }
        } else {
            return 0;
        }
    }
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if (tableView == self.friendview) {
            if (searchController.active && searchController.searchBar.text!.characters.count > 0) {
                if (filteredGroupList.count == 0) {
                    if (indexPath.section == 0) {
                        let cell = tableView.dequeueReusableCellWithIdentifier("Friend") as! FriendCell;
                        cell.friendlabel.text = filteredFriendList[indexPath.row].name;
                        cell.friendimage.image = UIImage(data: filteredFriendList[indexPath.row].imagedata!);
                        cell.profid = filteredFriendList[indexPath.row].profid;
                        return cell;
                    } else {
                        return UITableViewCell();
                    }
                } else {
                    if (indexPath.section == 0) {
                        let cell = tableView.dequeueReusableCellWithIdentifier("Group") as! GroupCell;
                        let currentprof = filteredGroupList[indexPath.row];
                        cell.grouptextfield.text = currentprof.name;
                        let right:NSMutableArray = NSMutableArray();
                        let left:NSMutableArray = NSMutableArray();
                        let imagesize:CGSize = CGSizeMake(20,20);
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
                        let details = GroupData.getGroupData(&Globals.localgroups, id: currentprof.groupid!);
                        cell.memberlabel.text = details.descriptiontext;
                        if currentprof.memberstring != nil {
                        cell.memberlist = currentprof.memberstring;
                        }
                        if (groupsupdated) {
                            cell.groupimage.image = details.image;
                        }
                        cell.grouptextfield.delegate = self;
                        cell.delegate = self;
                        return cell;
                    } else if (indexPath.section == 1) {
                        let cell = tableView.dequeueReusableCellWithIdentifier("Friend") as! FriendCell;
                        cell.friendlabel.text = filteredFriendList[indexPath.row].name;
                        cell.friendimage.image = UIImage(data: filteredFriendList[indexPath.row].imagedata!);
                        cell.profid = filteredFriendList[indexPath.row].profid;
                        return cell;
                    } else {
                        return UITableViewCell();
                    }
                }
                
            } else {
                if (GroupList.count == 0) {
                    if (indexPath.section == 0) {
                        let cell = tableView.dequeueReusableCellWithIdentifier("Friend") as! FriendCell;
                        cell.friendlabel.text = FriendList[indexPath.row].name;
                        cell.friendimage.image = UIImage(data: FriendList[indexPath.row].imagedata!);
                        cell.profid = FriendList[indexPath.row].profid;
                        return cell;
                    } else {
                        return UITableViewCell();
                    }
                } else {
                    if (indexPath.section == 0) {
                        let cell = tableView.dequeueReusableCellWithIdentifier("Group") as! GroupCell;
                        let currentprof = GroupList[indexPath.row];
                        cell.grouptextfield.text = currentprof.name;
                        let right:NSMutableArray = NSMutableArray();
                        let left:NSMutableArray = NSMutableArray();
                        let imagesize:CGSize = CGSizeMake(20,20);
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
                        let details = GroupData.getGroupData(&Globals.localgroups, id: currentprof.groupid!);
                        cell.memberlabel.text = details.descriptiontext;
                        if currentprof.memberstring != nil {
                            cell.memberlist = currentprof.memberstring;
                        }
                        if (groupsupdated) {
                            cell.groupimage.image = details.image;
                        }
                        cell.grouptextfield.delegate = self;
                        cell.delegate = self;
                        return cell;
                    } else if (indexPath.section == 1) {
                        let cell = tableView.dequeueReusableCellWithIdentifier("Friend") as! FriendCell;
                        cell.friendlabel.text = FriendList[indexPath.row].name;
                        cell.friendimage.image = UIImage(data: FriendList[indexPath.row].imagedata!);
                        cell.profid = FriendList[indexPath.row].profid;
                        return cell;
                    } else {
                        return UITableViewCell();
                    }
                }
            }
        } else {
            return UITableViewCell();
        }
    }
    func scrollViewDidScroll(scrollView: UIScrollView) {
        if searchController.searchBar.isFirstResponder() {
            searchController.searchBar.resignFirstResponder();
        }
    }
    //MARK: Text Field Methods
    func textFieldShouldBeginEditing(textField: UITextField) -> Bool {
        return true;
    }
    func textFieldDidBeginEditing(textField: UITextField) {
        currentfield = textField;
        _ = NSTimer.scheduledTimerWithTimeInterval(0.1, target: self, selector: "timerticked", userInfo: nil, repeats: false);
    }
    func timerticked() {
        let textField = currentfield;
        var point:CGPoint = textField!.convertPoint(CGPointZero, toView: self.friendview);
        point = CGPointMake(0, point.y);
        let index:NSIndexPath = self.friendview.indexPathForRowAtPoint(point)!;
        let cell: GroupCell = (self.friendview.cellForRowAtIndexPath(index) as? GroupCell)!;
        if (cell.cellState != SWCellState.CellStateCenter) {
            cell.hideUtilityButtonsAnimated(true);
        }
        cell.hideUtilityButtonsAnimated(true);
    }
    func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
        _ = NSTimer.scheduledTimerWithTimeInterval(0.1, target: self, selector: "timerticked", userInfo: nil, repeats: false);
        return true;
    }
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        let point:CGPoint = textField.convertPoint(CGPointZero, toView: self.friendview);
        let index:NSIndexPath = self.friendview.indexPathForRowAtPoint(point)!;
        if (index.section == 0) {
            if (textField.text!.characters.count>0) {
                if (GroupList[index.row].name! != textField.text) {
                    let alert = UIAlertController(title: "Rename Group", message: ("Would you like to rename '" + GroupList[index.row].name! + "' to '" + textField.text! + "'?"), preferredStyle: UIAlertControllerStyle.Alert)
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
    func tableView(tableView: UITableView, willSelectRowAtIndexPath indexPath: NSIndexPath) -> NSIndexPath? {
        if indexPath.section == 0 {
            if searchController.active {
                for (var i = 0; i<filteredGroupList.count; i++) {
                    let index = NSIndexPath(forRow: i, inSection: 0);
                    if (indexPath.row != index.row) {
                        let cell: SWTableViewCell = (self.friendview.cellForRowAtIndexPath(index) as? SWTableViewCell)!
                        cell.hideUtilityButtonsAnimated(true);
                    }
                }
            } else {
                for (var i = 0; i<GroupList.count; i++) {
                    let index = NSIndexPath(forRow: i, inSection: 0);
                    if (indexPath.row != index.row) {
                        let cell: SWTableViewCell = (self.friendview.cellForRowAtIndexPath(index) as? SWTableViewCell)!
                        cell.hideUtilityButtonsAnimated(true);
                    }
                }
            }
        }
        return indexPath;
    }
    //MARK: Swipeable Table View Methods
    func findFirstResponder(inView view: UIView) -> UIView? {
        for subView in view.subviews {
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
        let indexpath:NSIndexPath = self.friendview.indexPathForCell(cell)!;
        if (index == 0) {
            let popoverVC = storyboard?.instantiateViewControllerWithIdentifier("PopoverGroupList") as! GroupListPopoverVC!
            popoverVC.currentgroup = Group(name: GroupList[indexpath.row].name, groupid: GroupList[indexpath.row].groupid, memberstring: GroupList[indexpath.row].memberstring, invitedstring: GroupList[indexpath.row].invitedstring, isadmin: GroupList[indexpath.row].isadmin, save: false)
            let members:[String] = (GroupList[indexpath.row].memberstring?.componentsSeparatedByString(";"))!;
            let invited:[String] = (GroupList[indexpath.row].invitedstring?.componentsSeparatedByString(";"))!;
            var height:Int;
            //Set Size of Popup
            if (members.count>0 && invited.count>0) {
                height = members.count*70 + invited.count*70 + 44;
            } else if (members.count>0){
                height = members.count*70 + 22;
            } else {
                height = invited.count*70 + 22;
            }
            height = height + 112;
            if (height > 2*((Int(self.view.center.y)-64))) {
                height = 2*((Int(self.view.center.y)-64));
            }
            let width = (Int(self.view.frame.size.width)-75);
            popoverVC.width = CGFloat(width);
            popoverVC.preferredContentSize = CGSizeMake(CGFloat(width), CGFloat(height))
            popoverVC.modalPresentationStyle = .Popover
            let popover = popoverVC.popoverPresentationController!
            popover.delegate = self
            popover.sourceView  = self.view
            popover.sourceRect = self.view.frame;
            popover.permittedArrowDirections = UIPopoverArrowDirection();
            presentViewController(popoverVC, animated: true, completion: nil);
        }
        if (index == 1) {
            let popoverVC = storyboard?.instantiateViewControllerWithIdentifier("InviteVC") as! InviteVC!
            popoverVC.memberstring = GroupList[indexpath.row].invitedstring!;
            popoverVC.itemname = GroupList[indexpath.row].name!
            popoverVC.itemtype = "Group";
            popoverVC.itemid = GroupList[indexpath.row].groupid!;
            var sendGroupList = GroupList;
            sendGroupList.removeAtIndex(indexpath.row);
            popoverVC.GroupList = sendGroupList;
            popoverVC.FriendList = FriendList;
            let height = 2*((Int(self.view.center.y)-64));
            let width = (Int(self.view.frame.size.width)-75);
            popoverVC.preferredContentSize = CGSizeMake(CGFloat(width), CGFloat(height))
            popoverVC.modalPresentationStyle = .Popover
            let popover = popoverVC.popoverPresentationController!
            popover.delegate = self
            popover.sourceView  = self.view
            popover.sourceRect = self.view.frame;
            popover.permittedArrowDirections = UIPopoverArrowDirection();
            presentViewController(popoverVC, animated: true, completion: nil);
            
        }
    }
    func swipeableTableViewCell(cell: SWTableViewCell!, didTriggerRightUtilityButtonWithIndex index: Int) {
        cell.hideUtilityButtonsAnimated(true);
        let indexpath:NSIndexPath = self.friendview.indexPathForCell(cell)!;
        if (index == 0) {
            let alert = UIAlertController(title: "Leave Group", message: ("Are you sure you want to leave the group '" + GroupList[indexpath.row].name! + "'?"), preferredStyle: UIAlertControllerStyle.Alert)
            alert.addAction(UIAlertAction(title: "Nope!", style: .Cancel, handler: { action in
            }))
            alert.addAction(UIAlertAction(title: "Yep!", style: .Default, handler: { action in
                if (Reachability.isConnectedToNetwork()) {
                    var params = Dictionary<String,AnyObject>();
                    params["groupid"] = self.GroupList[indexpath.row].groupid;
                    Reachability.postToServer("group_leave.php", postdata: params, customselector: "GroupRefresh");
                } else {
                    RKDropdownAlert.title("Can't Leave!", message: "You are currently not connected to the internet! :(");
                }
            }))
            self.presentViewController(alert, animated: true, completion: nil)
            
        }
        if (index == 1) {
            let alert = UIAlertController(title: "Delete Group", message: ("Are you sure you want to delete the group '" + GroupList[indexpath.row].name! + "'?"), preferredStyle: UIAlertControllerStyle.Alert)
            alert.addAction(UIAlertAction(title: "Nope!", style: .Cancel, handler: { action in
            }))
            alert.addAction(UIAlertAction(title: "Yep!", style: .Default, handler: { action in
                if (Reachability.isConnectedToNetwork()) {
                    var params = Dictionary<String,AnyObject>();
                    params["groupid"] = self.GroupList[indexpath.row].groupid;
                    Reachability.postToServer("group_delete.php", postdata: params, customselector: "GroupRefresh");
                } else {
                    RKDropdownAlert.title("Can't Delete!", message: "You are currently not connected to the internet! :(");
                }
            }))
            self.presentViewController(alert, animated: true, completion: nil)
            
        }
    }
    
}