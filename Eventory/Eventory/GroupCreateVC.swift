//
//  GroupCreateVC.swift
//  Eventory
//
//  Created by Imran Ahmed on 29/07/2015.
//  Copyright (c) 2015 Imran Ahmed. All rights reserved.
//
import UIKit
class GroupCreateVC: UIViewController, UITableViewDelegate, UITableViewDataSource, UIPopoverPresentationControllerDelegate, UITextFieldDelegate,UISearchControllerDelegate, UISearchResultsUpdating {
    @IBOutlet weak var invitetable: UITableView!
    @IBOutlet weak var invitetext: MarqueeLabel!
    @IBOutlet weak var invitedetail: UINavigationItem!
    @IBOutlet weak var groupname: UITextField!
    var memberstring:String = "";
    var itemname:String = "";
    var FriendList:[Profile] = [];
    var GroupList:[Group] = [];
    var filteredFriendList:[Profile]! = [];
    var filteredGroupList:[Group]! = [];
    var nogroups:Bool = false;
    var added:[String] = [];
    var groupsadded:[String] = [];
    let searchController = UISearchController(searchResultsController: nil);
    var hasverifiedquit:Bool = false;
    override func viewDidLoad() {
        super.viewDidLoad()
        invitetext.scrollDuration = 2;
        invitetable.delegate = self;
        invitetable.dataSource = self;
        groupname.delegate = self;
        added.append(Globals.currentprofile!.profid!);
        self.popoverPresentationController?.delegate = self;
        self.definesPresentationContext = true;
        searchController.searchResultsUpdater = self
        searchController.hidesNavigationBarDuringPresentation = false
        searchController.dimsBackgroundDuringPresentation = false
        searchController.searchBar.sizeToFit()
        searchController.searchBar.placeholder = "Search Friends/Groups"
        self.invitetable.tableHeaderView = searchController.searchBar
        var checktap = UITapGestureRecognizer(target: self, action: "tableViewTapped:");
        checktap.cancelsTouchesInView = false;
        self.view.addGestureRecognizer(checktap);
        if (GroupList.count==0) {
            nogroups = true;
        }
        invitedetail.title = "Create Group"
        sort();
        format();
        // Do any additional setup after loading the view.
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    func popoverPresentationControllerShouldDismissPopover(popoverController: UIPopoverPresentationController) -> Bool {
        if groupname.isFirstResponder() {
            groupname.resignFirstResponder();
        }
        if added.count > 1 {
            if (hasverifiedquit) {
                return true
            } else {
                var alert = UIAlertController(title: "Exit Group Create?", message: ("Are you sure you want to quit making this group?"), preferredStyle: UIAlertControllerStyle.Alert)
                alert.addAction(UIAlertAction(title: "Nope!", style: .Default, handler: { action in
                }))
                alert.addAction(UIAlertAction(title: "Yep!", style: .Cancel, handler: { action in
                    self.hasverifiedquit = true;
                    self.dismissViewControllerAnimated(true, completion: nil);
                }))
                self.presentViewController(alert, animated: true, completion: nil)
                return false;
            }
        } else {
            return true;
        }
    }
    func sort() {
        FriendList = Profile.SortFriends(FriendList);
        GroupList = Group.SortGroups(GroupList);
        dispatch_async(dispatch_get_main_queue()){
            UIView.transitionWithView(self.invitetable, duration:0.1, options: UIViewAnimationOptions.TransitionCrossDissolve,
                animations: {
                    self.invitetable.reloadData();
                },
                completion: nil)
        }
    }
    func format() {
        if added.count>0 {
            invitedetail.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Done, target: self, action: "InvitePressed:");
            var names:[String] = [];
            for (var i = 0; i < added.count; i++) {
                let filter = FriendList.filter({return $0.profid == self.added[i]})
                if (filter.count>0) {
                    var currentprof:Profile? = filter[0]
                    if let check = currentprof {
                        if (!contains(names, getName(currentprof!.name!))) {
                            names.append(getName(currentprof!.name!));
                        }
                    }
                }
            }
            //Inviting label creation
            var final:String = ""
            if (names.count>1) {
                var copy = names;
                copy.removeLast();
                final = "Invite " + ", ".join(copy) + " and " + names[names.count-1] +  "?";
            } else {
                if (names.count == 1) {
                    final = "Invite " +  (names[0]) + "?"
                } else if (names.count == 0) {
                    if (added[0] == Globals.currentprofile!.profid) {
                        final = "No-one has been invited as yet!";
                        invitedetail.rightBarButtonItem = nil;
                    }
                }
            }
            invitetext.text = final;
        } else {
            invitedetail.rightBarButtonItem = nil;
            invitetext.text = "No-one has been invited as yet!";
        }
    }
    func getName(input: String) -> String {
        return (split(input) {$0 == " "})[0];
    }
    func InvitePressed(sender: UIBarButtonItem) {
        if (searchController.active) {
            searchController.active = false;
        }
        if (groupname.text == "") {
            let color = Schemes.returnColor("Peter River", alpha: 1.0);
            RKDropdownAlert.title("No Name!", message: "Please enter a name for your group!", backgroundColor: color, textColor: UIColor.whiteColor())
        } else {
            if (!Reachability.isConnectedToNetwork()) {
                RKDropdownAlert.title("Offline!", message: "You are currently not connected to the internet! :(");
            } else {
                var params = Dictionary<String,AnyObject>();
                params["name"] = groupname.text;
                params["id"] = added;
                Reachability.postToServer("group_create.php", postdata: params, customselector: "GroupRefresh");
                self.dismissViewControllerAnimated(true, completion: nil);
            }
        }
    }
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder();
        return true;
    }
    //MARK: Search Bar Methods
    func updateSearchResultsForSearchController(searchinputController: UISearchController) {
        filteredFriendList.removeAll(keepCapacity: false);
        filteredGroupList.removeAll(keepCapacity: false);
        var predicate:NSPredicate = NSPredicate(format: "SELF.name CONTAINS[c] %@", searchinputController.searchBar.text);
        filteredFriendList = FriendList.filter({predicate.evaluateWithObject($0)});
        filteredGroupList = GroupList.filter({predicate.evaluateWithObject($0)});
        self.invitetable.reloadData();
    }
    //MARK: Table View Methods
    func tableViewTapped (tap: UITapGestureRecognizer) {
        var point:CGPoint = tap.locationInView(tap.view);
        if (!CGRectContainsPoint(groupname.frame, point)) {
            if groupname.isFirstResponder() {
                groupname.resignFirstResponder();
            }
            if searchController.searchBar.isFirstResponder() {
                searchController.searchBar.resignFirstResponder();
            }
        }
    }
    func tableView(tableView: UITableView, willSelectRowAtIndexPath indexPath: NSIndexPath) -> NSIndexPath? {
        if groupname.isFirstResponder() {
            groupname.resignFirstResponder();
            return nil;
        }
        if searchController.searchBar.isFirstResponder() {
            searchController.resignFirstResponder();
            return nil;
        }
        return indexPath;
    }
    func tableView(tableView: UITableView, willDeselectRowAtIndexPath indexPath: NSIndexPath) -> NSIndexPath? {
        if groupname.isFirstResponder() {
            groupname.resignFirstResponder();
            return nil;
        }
        if searchController.searchBar.isFirstResponder() {
            searchController.resignFirstResponder();
            return nil;
        }
        return indexPath;
    }
    func cellcheck(check: Bool, profid: String) {
        if (profid != Globals.currentprofile?.profid) {
            let section:Int;
            if (nogroups) {
                section = 0
            } else {
                section = 1
            }
            var currentprof:Profile? = FriendList.filter({return $0.profid == profid})[0]
            if let cellfriend = invitetable.cellForRowAtIndexPath(NSIndexPath(forRow: find(FriendList, currentprof!)!, inSection: section)) {
                if (check) {
                    cellfriend.accessoryType = UITableViewCellAccessoryType.Checkmark;
                } else {
                    cellfriend.accessoryType = UITableViewCellAccessoryType.None;
                }
                cellfriend.setSelected(check, animated: true)
            }
        }
    }
    func groupcheck() {
        if (!nogroups) {
            for (var i = 0 ; i < GroupList.count; i++ ) {
                var combined:[String] = added;
                var members:[String] = split(memberstring) {$0 == ";"}
                combined.extend(members);
                let combinedSet = NSSet(array: combined);
                let check = NSSet(array: split(GroupList[i].memberstring!) {$0 == ";"}).isSubsetOfSet(combinedSet as Set<NSObject>);
                if let cellgroup = invitetable.cellForRowAtIndexPath(NSIndexPath(forRow: i, inSection: 0)) {
                    if (check) {
                        var index = NSIndexPath(forRow: i, inSection: 0)
                        invitetable.selectRowAtIndexPath(index, animated: true, scrollPosition: UITableViewScrollPosition.None)
                        cellgroup.accessoryType = UITableViewCellAccessoryType.Checkmark;
                        cellgroup.setSelected(true, animated: true)
                    } else {
                        var index = NSIndexPath(forRow: i, inSection: 0)
                        invitetable.deselectRowAtIndexPath(index, animated: true)
                        cellgroup.accessoryType = UITableViewCellAccessoryType.None;
                        cellgroup.setSelected(false, animated: true)
                    }
                }
            }
        }
        
    }
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        var cell = invitetable.cellForRowAtIndexPath(indexPath);
        if (cell?.tintColor != UIColor.grayColor()) {
            if (searchController.active && count(searchController.searchBar.text) > 0) {
                if (nogroups) {
                    if !contains(added, filteredFriendList[indexPath.row].profid!) {
                        added.append(filteredFriendList[indexPath.row].profid!);
                    }
                    cellcheck(true, profid: filteredFriendList[indexPath.row].profid!)
                } else {
                    if (indexPath.section == 1) {
                        if !contains(added, filteredFriendList[indexPath.row].profid!) {
                            added.append(filteredFriendList[indexPath.row].profid!);
                        }
                        cellcheck(true, profid: filteredFriendList[indexPath.row].profid!)
                        groupcheck();
                    }
                    if (indexPath.section == 0) {
                        let array = split(filteredGroupList[indexPath.row].memberstring!) {$0 == ";"}
                        for (var i = 0; i < array.count ; i++ ) {
                            if !contains(added, array[i]) {
                                added.append(array[i]);
                            }
                            let section:Int;
                            if (nogroups) {
                                section = 0
                            } else {
                                section = 1
                            }
                            if (array[i] != Globals.currentprofile?.profid) {
                                var currentprof:Profile? = filteredFriendList.filter({return $0.profid == array[i]})[0]
                                if (currentprof != nil) {
                                    var index = NSIndexPath(forRow: find(filteredFriendList, currentprof!)!, inSection: section)
                                    invitetable.selectRowAtIndexPath(index, animated: true, scrollPosition: UITableViewScrollPosition.None)
                                    cellcheck(true, profid: array[i])
                                }
                            }
                        }
                    }
                }
            } else {
                if (nogroups) {
                    if !contains(added, FriendList[indexPath.row].profid!) {
                        added.append(FriendList[indexPath.row].profid!);
                    }
                    cellcheck(true, profid: FriendList[indexPath.row].profid!)
                } else {
                    if (indexPath.section == 1) {
                        if !contains(added, FriendList[indexPath.row].profid!) {
                            added.append(FriendList[indexPath.row].profid!);
                        }
                        cellcheck(true, profid: FriendList[indexPath.row].profid!)
                        groupcheck();
                    }
                    if (indexPath.section == 0) {
                        let array = split(GroupList[indexPath.row].memberstring!) {$0 == ";"}
                        for (var i = 0; i < array.count ; i++ ) {
                            if !contains(added, array[i]) {
                                added.append(array[i]);
                            }
                            let section:Int;
                            if (nogroups) {
                                section = 0
                            } else {
                                section = 1
                            }
                            if (array[i] != Globals.currentprofile?.profid) {
                                var currentprof:Profile? = FriendList.filter({return $0.profid == array[i]})[0]
                                if (currentprof != nil) {
                                    var index = NSIndexPath(forRow: find(FriendList, currentprof!)!, inSection: section)
                                    invitetable.selectRowAtIndexPath(index, animated: true, scrollPosition: UITableViewScrollPosition.None)
                                    cellcheck(true, profid: array[i])
                                }
                            }
                        }
                    }
                }
            }
        }
        format();
    }
    func tableView(tableView: UITableView, didDeselectRowAtIndexPath indexPath: NSIndexPath) {
        format();
        var cell = invitetable.cellForRowAtIndexPath(indexPath);
        if (cell?.tintColor != UIColor.grayColor()) { //i.e. can be selected and deselected
            if (searchController.active && count(searchController.searchBar.text) > 0) {
                if (nogroups) {
                    added.removeAtIndex(find(added,self.filteredFriendList[indexPath.row].profid!)!)
                    cellcheck(false, profid: filteredFriendList[indexPath.row].profid!)
                } else {
                    if (indexPath.section == 1) {
                        added.removeAtIndex(find(added,filteredFriendList[indexPath.row].profid!)!)
                        cellcheck(false, profid: filteredFriendList[indexPath.row].profid!)
                        for (var i = 0 ; i < filteredGroupList.count; i++ ) {
                            if (filteredGroupList[i].memberstring?.rangeOfString(filteredFriendList[indexPath.row].profid!) != nil) {
                                let cellgroup = invitetable.cellForRowAtIndexPath(NSIndexPath(forRow: i, inSection: 0));
                                cellgroup?.accessoryType = UITableViewCellAccessoryType.None;
                                cellgroup?.setSelected(false, animated: true)
                            }
                        }
                    }
                    if (indexPath.section == 0) {
                        let array = split(filteredGroupList[indexPath.row].memberstring!) {$0 == ";"}
                        for (var i = 0; i < array.count ; i++ ) {
                            if contains(added, array[i]) {
                                if (array[i] != Globals.currentprofile?.profid){
                                    added.removeAtIndex(find(added, array[i])!);
                                    cellcheck(false, profid: array[i]);
                                } else {
                                }
                            }
                        }
                    }
                }
            } else {
                if (nogroups) {
                    added.removeAtIndex(find(added,self.FriendList[indexPath.row].profid!)!)
                    cellcheck(false, profid: FriendList[indexPath.row].profid!)
                } else {
                    if (indexPath.section == 1) {
                        added.removeAtIndex(find(added,FriendList[indexPath.row].profid!)!)
                        cellcheck(false, profid: FriendList[indexPath.row].profid!)
                        for (var i = 0 ; i < GroupList.count; i++ ) {
                            if (GroupList[i].memberstring?.rangeOfString(FriendList[indexPath.row].profid!) != nil) {
                                let cellgroup = invitetable.cellForRowAtIndexPath(NSIndexPath(forRow: i, inSection: 0));
                                cellgroup?.accessoryType = UITableViewCellAccessoryType.None;
                                cellgroup?.setSelected(false, animated: true)
                            }
                        }
                    }
                    if (indexPath.section == 0) {
                        let array = split(GroupList[indexPath.row].memberstring!) {$0 == ";"}
                        for (var i = 0; i < array.count ; i++ ) {
                            if contains(added, array[i]) {
                                if (array[i] != Globals.currentprofile?.profid){
                                    added.removeAtIndex(find(added, array[i])!);
                                    cellcheck(false, profid: array[i]);
                                } else {
                                }
                            }
                        }
                    }
                }
            }
        }
        format();
    }
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        if (nogroups) {
            return 1;
        } else {
            return 2;
        }
    }
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if (nogroups) {
            return "Invite Friends";
        } else  {
            if (section == 0) {
                return "Invite Groups";
            } else if (section == 1) {
                return "Invite Friends";
            } else {
                return nil;
            }
        }
    }
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if (nogroups) {
            if searchController.active && count(searchController.searchBar.text) > 0 {
                return filteredFriendList.count;
            } else {
                return FriendList.count;
            }
        } else {
            if (section == 0) {
                if searchController.active && count(searchController.searchBar.text) > 0{
                    return filteredGroupList.count;
                } else {
                    return GroupList.count;
                }
            } else if (section == 1) {
                if searchController.active && count(searchController.searchBar.text) > 0{
                    return filteredFriendList.count;
                } else {
                    return FriendList.count;
                }
            } else {
                return 0;
            }
        }
    }
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if (nogroups) { //i.e. can be selected and deselected
            var cell = tableView.dequeueReusableCellWithIdentifier("Friend") as! FriendCell;
            if searchController.active && count(searchController.searchBar.text) > 0{
                cell.friendlabel.text = filteredFriendList[indexPath.row].name;
                cell.friendimage.image = UIImage(data: filteredFriendList[indexPath.row].imagedata!);
                cell.profid = filteredFriendList[indexPath.row].profid;
                cell.selectionStyle = UITableViewCellSelectionStyle.None;
                if (contains(added, filteredFriendList[indexPath.row].profid!) == false) {
                    if (contains(split(memberstring) {$0 == ";"}, filteredFriendList[indexPath.row].profid!) == true) {
                        //Check if member was part of the input members
                        cell.accessoryType = UITableViewCellAccessoryType.Checkmark;
                        cell.setSelected(true , animated: true)
                        cell.tintColor = UIColor.grayColor();
                    } else {
                        cell.accessoryType = UITableViewCellAccessoryType.None;
                        cell.setSelected(true , animated: true)
                    }
                } else {
                    //Already added
                }
            } else {
                cell.friendlabel.text = FriendList[indexPath.row].name;
                cell.friendimage.image = UIImage(data: FriendList[indexPath.row].imagedata!);
                cell.profid = FriendList[indexPath.row].profid;
                cell.selectionStyle = UITableViewCellSelectionStyle.None;
                if (contains(added, FriendList[indexPath.row].profid!) == false) {
                    if (contains(split(memberstring) {$0 == ";"}, FriendList[indexPath.row].profid!) == true) {
                        //Check if member was part of the input members
                        cell.accessoryType = UITableViewCellAccessoryType.Checkmark;
                        cell.setSelected(true , animated: true)
                        cell.tintColor = UIColor.grayColor();
                    } else {
                        cell.accessoryType = UITableViewCellAccessoryType.None;
                        cell.setSelected(true , animated: true)
                    }
                } else {
                    //Already added
                }
            }
            return cell;
        } else {
            if (indexPath.section == 0) {
                var cell = tableView.dequeueReusableCellWithIdentifier("GroupEmpty") as! GroupCellEmpty;
                if (searchController.active && count(searchController.searchBar.text) > 0) {
                    var currentgroup = filteredGroupList[indexPath.row];
                    cell.grouptextfield.text = currentgroup.name;
                    cell.groupimage.image = UIImage(named: "unkownprofile.png");
                    cell.memberlabel.text = Group.getMemberString(currentgroup.memberstring!);
                    cell.memberlist = currentgroup.memberstring;
                    cell.groupimage.image = Group.generateGroupImage(currentgroup.memberstring);
                } else {
                    var currentgroup = GroupList[indexPath.row];
                    cell.grouptextfield.text = currentgroup.name;
                    cell.groupimage.image = UIImage(named: "unkownprofile.png");
                    cell.memberlabel.text = Group.getMemberString(currentgroup.memberstring!);
                    cell.memberlist = currentgroup.memberstring;
                    cell.groupimage.image = Group.generateGroupImage(currentgroup.memberstring);
                }
                var combined:[String] = added;
                var members:[String] = split(memberstring) {$0 == ";"}
                combined.extend(members);
                let combinedSet = NSSet(array: combined)
                let memberSet = NSSet(array: members)
                let CheckCombined:Bool;
                let CheckMembers: Bool;
                if (combined.count>0) {
                    CheckCombined = NSSet(array: (array: split(cell.memberlist) {$0 == ";"})).isSubsetOfSet(combinedSet as Set<NSObject>); //Check if the input members + added members are in group
                } else {
                    CheckCombined = false;
                }
                if (members.count > 0) {
                    CheckMembers =  NSSet(array: (array: split(cell.memberlist) {$0 == ";"})).isSubsetOfSet(memberSet as Set<NSObject>); //Check if only the input members are in group
                } else {
                    CheckMembers = false;
                }
                cell.selectionStyle = UITableViewCellSelectionStyle.None;
                if (CheckCombined) {
                    if (CheckMembers) {
                        //All group members are input members
                        cell.tintColor = UIColor.grayColor();
                        cell.accessoryType = UITableViewCellAccessoryType.Checkmark;
                        cell.setSelected(true , animated: true);
                    } else {
                        //All group members are a combination of input and invited members
                        cell.accessoryType = UITableViewCellAccessoryType.Checkmark;
                        cell.setSelected(true , animated: true);
                    }
                } else {
                    //All group members include members not on combined list
                    cell.accessoryType = UITableViewCellAccessoryType.None
                    cell.setSelected(false , animated: true);
                }
                return cell;
            } else if (indexPath.section == 1) {
                var cell = tableView.dequeueReusableCellWithIdentifier("Friend") as! FriendCell;
                if searchController.active && count(searchController.searchBar.text) > 0 {
                    cell.friendlabel.text = filteredFriendList[indexPath.row].name;
                    cell.friendimage.image = UIImage(data: filteredFriendList[indexPath.row].imagedata!);
                    cell.profid = filteredFriendList[indexPath.row].profid;
                    cell.selectionStyle = UITableViewCellSelectionStyle.None;
                    if (contains(added, filteredFriendList[indexPath.row].profid!) == false) {
                        if (contains(split(memberstring) {$0 == ";"}, filteredFriendList[indexPath.row].profid!) == true) {
                            //Check if member was part of the input members
                            cell.accessoryType = UITableViewCellAccessoryType.Checkmark;
                            cell.setSelected(true , animated: true)
                            cell.tintColor = UIColor.grayColor();
                        } else {
                            cell.accessoryType = UITableViewCellAccessoryType.None;
                            cell.setSelected(true , animated: true)
                        }
                    } else {
                        //Already added
                    }
                } else {
                    cell.friendlabel.text = FriendList[indexPath.row].name;
                    cell.friendimage.image = UIImage(data: FriendList[indexPath.row].imagedata!);
                    cell.profid = FriendList[indexPath.row].profid;
                    cell.selectionStyle = UITableViewCellSelectionStyle.None;
                    if (contains(added, FriendList[indexPath.row].profid!) == false) {
                        if (contains(split(memberstring) {$0 == ";"}, FriendList[indexPath.row].profid!) == true) {
                            //Check if member was part of the input members
                            cell.accessoryType = UITableViewCellAccessoryType.Checkmark;
                            cell.setSelected(true, animated: true)
                            cell.tintColor = UIColor.grayColor();
                        } else {
                            cell.accessoryType = UITableViewCellAccessoryType.None;
                            cell.setSelected(false, animated: true);
                        }
                    } else {
                        //Already added
                    }
                }
                return cell;
            } else {
                return UITableViewCell();
            }
        }
    }
}