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
        let checktap = UITapGestureRecognizer(target: self, action: "tableViewTapped:");
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
        if added.count > 1 || groupname.text!.characters.count > 0 {
            if (hasverifiedquit) {
                return true
            } else {
                let alert = UIAlertController(title: "Exit Group Create?", message: ("Are you sure you want to quit making this group?"), preferredStyle: UIAlertControllerStyle.Alert)
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
                    let currentprof:Profile? = filter[0]
                    if let _ = currentprof {
                        if (!names.contains(getName(currentprof!.name!))) {
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
                let copystring = copy.joinWithSeparator(", ");
                final = "Invite " + copystring + " and " + names[names.count-1] +  "?";
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
        return (input.characters.split {$0 == " "}.map { String($0) })[0];
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
        let predicate:NSPredicate = NSPredicate(format: "SELF.name CONTAINS[c] %@", searchinputController.searchBar.text!);
        filteredFriendList = FriendList.filter({predicate.evaluateWithObject($0)});
        filteredGroupList = GroupList.filter({predicate.evaluateWithObject($0)});
        self.invitetable.reloadData();
    }
    //MARK: Table View Methods
    func tableViewTapped (tap: UITapGestureRecognizer) {
        let point:CGPoint = tap.locationInView(tap.view);
        if (!CGRectContainsPoint(groupname.frame, point)) {
            if groupname.isFirstResponder() {
                groupname.resignFirstResponder();
            }
        }
        if (!CGRectContainsPoint(searchController.searchBar.frame, point)) {
            if searchController.searchBar.isFirstResponder() {
                searchController.searchBar.resignFirstResponder();
            }
        }
    }
    func tableView(tableView: UITableView, willSelectRowAtIndexPath indexPath: NSIndexPath) -> NSIndexPath? {
        var resigned:Bool = false;
        if groupname.isFirstResponder() {
            groupname.resignFirstResponder();
            resigned = true;
        }
        if searchController.searchBar.isFirstResponder() {
            searchController.resignFirstResponder();
            resigned = true;
        }
        if (resigned) {
            return nil;
        } else {
            return indexPath;
        }
    }
    func tableView(tableView: UITableView, willDeselectRowAtIndexPath indexPath: NSIndexPath) -> NSIndexPath? {
        var resigned:Bool = false;
        if groupname.isFirstResponder() {
            groupname.resignFirstResponder();
            resigned = true;
        }
        if searchController.searchBar.isFirstResponder() {
            searchController.resignFirstResponder();
            resigned = true;
        }
        if (resigned) {
            return nil;
        } else {
            return indexPath;
        }
    }
    func getsection() -> Int! {
        if (nogroups) {
            if (searchController.active && searchController.searchBar.text!.characters.count > 0) {
                if filteredFriendList.count > 0 {
                    return 0;
                } else {
                    return nil;
                }
            } else {
                return 0;
            }
        } else  {
            if (searchController.active && searchController.searchBar.text!.characters.count > 0) {
                if filteredFriendList.count > 0 && filteredGroupList.count > 0{
                    return 1;
                } else if filteredFriendList.count > 0 || filteredGroupList.count > 0 {
                    if filteredFriendList.count > 0 {
                        return 0;
                    } else {
                        return nil;
                    }
                } else {
                    return 0;
                }
            } else {
                return 1;
            }
        }
        
    }
    func cellcheck(check: Bool, profid: String) {
        if (profid != Globals.currentprofile?.profid) {
            if let section = getsection() {
                let currentprof:Profile? = FriendList.filter({return $0.profid == profid})[0]
                if searchController.active && searchController.searchBar.text!.characters.count > 0 {
                    if let cellfriend = self.invitetable.cellForRowAtIndexPath(NSIndexPath(forRow: self.filteredFriendList.indexOf(currentprof!)!, inSection: section))
                    {
                        if cellfriend.tintColor != UIColor.grayColor() {
                            if (check) {
                                cellfriend.accessoryType = UITableViewCellAccessoryType.Checkmark;
                            } else {
                                cellfriend.accessoryType = UITableViewCellAccessoryType.None;
                            }
                            cellfriend.setSelected(check, animated: true)
                        }
                    }
                } else {
                    if let cellfriend = invitetable.cellForRowAtIndexPath(NSIndexPath(forRow: FriendList.indexOf(currentprof!)!, inSection: section))
                    {
                        if cellfriend.tintColor != UIColor.grayColor() {
                            if (check) {
                                cellfriend.accessoryType = UITableViewCellAccessoryType.Checkmark;
                            } else {
                                cellfriend.accessoryType = UITableViewCellAccessoryType.None;
                            }
                            cellfriend.setSelected(check, animated: true)
                        }
                    }
                }
            }
        }
    }
    func groupcheck() {
        if (!nogroups) {
            if searchController.active && searchController.searchBar.text!.characters.count > 0 {
                for (var i = 0 ; i < self.filteredGroupList.count; i++ ) {
                    var combined:[String] = added;
                    let members:[String] = memberstring.characters.split {$0 == ";"}.map { String($0) }
                    combined.appendContentsOf(members);
                    let combinedSet = NSSet(array: combined);
                    let check = NSSet(array: (filteredGroupList[i].memberstring!).characters.split {$0 == ";"}.map { String($0) }).isSubsetOfSet(combinedSet as Set<NSObject>);
                    if let cellgroup = invitetable.cellForRowAtIndexPath(NSIndexPath(forRow: i, inSection: 0)) {
                        if cellgroup.tintColor != UIColor.grayColor() {
                            if (check) {
                                let index = NSIndexPath(forRow: i, inSection: 0)
                                invitetable.selectRowAtIndexPath(index, animated: true, scrollPosition: UITableViewScrollPosition.None)
                                cellgroup.accessoryType = UITableViewCellAccessoryType.Checkmark;
                                cellgroup.setSelected(true, animated: true)
                            } else {
                                let index = NSIndexPath(forRow: i, inSection: 0)
                                invitetable.deselectRowAtIndexPath(index, animated: true)
                                cellgroup.accessoryType = UITableViewCellAccessoryType.None;
                                cellgroup.setSelected(false, animated: true)
                            }
                        }
                    }
                }
            } else {
                for (var i = 0 ; i < GroupList.count; i++ ) {
                    var combined:[String] = added;
                    let members:[String] = memberstring.characters.split {$0 == ";"}.map { String($0) }
                    combined.appendContentsOf(members);
                    let combinedSet = NSSet(array: combined);
                    let check = NSSet(array: (GroupList[i].memberstring!).characters.split {$0 == ";"}.map { String($0) }).isSubsetOfSet(combinedSet as Set<NSObject>);
                    if let cellgroup = invitetable.cellForRowAtIndexPath(NSIndexPath(forRow: i, inSection: 0)) {
                        if cellgroup.tintColor != UIColor.grayColor() {
                            if (check) {
                                let index = NSIndexPath(forRow: i, inSection: 0)
                                invitetable.selectRowAtIndexPath(index, animated: true, scrollPosition: UITableViewScrollPosition.None)
                                cellgroup.accessoryType = UITableViewCellAccessoryType.Checkmark;
                                cellgroup.setSelected(true, animated: true)
                            } else {
                                let index = NSIndexPath(forRow: i, inSection: 0)
                                invitetable.deselectRowAtIndexPath(index, animated: true)
                                cellgroup.accessoryType = UITableViewCellAccessoryType.None;
                                cellgroup.setSelected(false, animated: true)
                            }
                        }
                    }
                }
            }
        }
        
    }
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let cell = invitetable.cellForRowAtIndexPath(indexPath);
        if (cell?.tintColor != UIColor.grayColor()) {
            if (nogroups) {
                if (searchController.active && searchController.searchBar.text!.characters.count > 0) {
                    if filteredFriendList.count > 0 {
                        if !added.contains((filteredFriendList[indexPath.row].profid!)) {
                            added.append(filteredFriendList[indexPath.row].profid!);
                        }
                        cellcheck(true, profid: filteredFriendList[indexPath.row].profid!)
                    } else {
                    }
                } else {
                    if !added.contains((FriendList[indexPath.row].profid!)) {
                        added.append(FriendList[indexPath.row].profid!);
                    }
                    cellcheck(true, profid: FriendList[indexPath.row].profid!)
                }
            } else {
                if (searchController.active && searchController.searchBar.text!.characters.count > 0) {
                    if filteredFriendList.count > 0 && filteredGroupList.count > 0{
                        if indexPath.section == 0 {
                            let array = (filteredGroupList[indexPath.row].memberstring!).characters.split {$0 == ";"}.map { String($0) }
                            for (var i = 0; i < array.count ; i++ ) {
                                if !added.contains(array[i]) {
                                    added.append(array[i]);
                                }
                                let section:Int;
                                if (nogroups) {
                                    section = 0
                                } else {
                                    section = 1
                                }
                                if (array[i] != Globals.currentprofile?.profid) {
                                    let currentprof:Profile? = filteredFriendList.filter({return $0.profid == array[i]})[0]
                                    if (currentprof != nil) {
                                        let index = NSIndexPath(forRow: filteredFriendList.indexOf(currentprof!)!, inSection: section)
                                        invitetable.selectRowAtIndexPath(index, animated: true, scrollPosition: UITableViewScrollPosition.None)
                                        cellcheck(true, profid: array[i])
                                    }
                                }
                            }
                        } else if indexPath.section == 1 {
                            if !added.contains((filteredFriendList[indexPath.row].profid!)) {
                                added.append(filteredFriendList[indexPath.row].profid!);
                            }
                            cellcheck(true, profid: filteredFriendList[indexPath.row].profid!)
                        }
                    } else if filteredFriendList.count > 0 || filteredGroupList.count > 0 {
                        if filteredFriendList.count > 0 {
                            if !added.contains((filteredFriendList[indexPath.row].profid!)) {
                                added.append(filteredFriendList[indexPath.row].profid!);
                            }
                            cellcheck(true, profid: filteredFriendList[indexPath.row].profid!)
                        } else {
                            let array = (filteredGroupList[indexPath.row].memberstring!).characters.split {$0 == ";"}.map { String($0) }
                            for (var i = 0; i < array.count ; i++ ) {
                                if !added.contains(array[i]) {
                                    added.append(array[i]);
                                }
                                let section:Int;
                                if (nogroups) {
                                    section = 0
                                } else {
                                    section = 1
                                }
                                if (array[i] != Globals.currentprofile?.profid) {
                                    let currentprof:Profile? = filteredFriendList.filter({return $0.profid == array[i]})[0]
                                    if (currentprof != nil) {
                                        let index = NSIndexPath(forRow: filteredFriendList.indexOf(currentprof!)!, inSection: section)
                                        invitetable.selectRowAtIndexPath(index, animated: true, scrollPosition: UITableViewScrollPosition.None)
                                        cellcheck(true, profid: array[i])
                                    }
                                }
                            }
                        }
                    }
                } else {
                    if indexPath.section == 0 {
                        let array = (GroupList[indexPath.row].memberstring!).characters.split {$0 == ";"}.map { String($0) }
                        for (var i = 0; i < array.count ; i++ ) {
                            if !added.contains(array[i]) {
                                added.append(array[i]);
                            }
                            let section:Int;
                            if (nogroups) {
                                section = 0
                            } else {
                                section = 1
                            }
                            if (array[i] != Globals.currentprofile?.profid) {
                                let currentprof:Profile? = FriendList.filter({return $0.profid == array[i]})[0]
                                if (currentprof != nil) {
                                    let index = NSIndexPath(forRow: FriendList.indexOf(currentprof!)!, inSection: section)
                                    invitetable.selectRowAtIndexPath(index, animated: true, scrollPosition: UITableViewScrollPosition.None)
                                    cellcheck(true, profid: array[i])
                                }
                            }
                        }
                    } else if indexPath.section == 1 {
                        if !added.contains((FriendList[indexPath.row].profid!)) {
                            added.append(FriendList[indexPath.row].profid!);
                        }
                        cellcheck(true, profid: FriendList[indexPath.row].profid!)
                    }
                }
            }
        }
        format();
        groupcheck();
    }
    func tableView(tableView: UITableView, didDeselectRowAtIndexPath indexPath: NSIndexPath) {
        let cell = invitetable.cellForRowAtIndexPath(indexPath);
        if (cell?.tintColor != UIColor.grayColor()) {
            if (nogroups) {
                if (searchController.active && searchController.searchBar.text!.characters.count > 0) {
                    if filteredFriendList.count > 0 {
                        added.removeAtIndex(added.indexOf((self.filteredFriendList[indexPath.row].profid!))!)
                        cellcheck(false, profid: filteredFriendList[indexPath.row].profid!)
                    }
                } else {
                    added.removeAtIndex(added.indexOf((self.FriendList[indexPath.row].profid!))!)
                    cellcheck(false, profid: FriendList[indexPath.row].profid!)
                }
            } else {
                if (searchController.active && searchController.searchBar.text!.characters.count > 0) {
                    if filteredFriendList.count > 0 && filteredGroupList.count > 0{
                        if indexPath.section == 0 {
                            let array = (filteredGroupList[indexPath.row].memberstring!).characters.split {$0 == ";"}.map { String($0) }
                            for (var i = 0; i < array.count ; i++ ) {
                                if added.contains(array[i]) {
                                    if (array[i] != Globals.currentprofile?.profid){
                                        added.removeAtIndex(added.indexOf(array[i])!);
                                        cellcheck(false, profid: array[i]);
                                    } else {
                                    }
                                }
                            }
                        } else if indexPath.section == 1 {
                            added.removeAtIndex(added.indexOf((self.filteredFriendList[indexPath.row].profid!))!)
                            cellcheck(false, profid: filteredFriendList[indexPath.row].profid!)
                        }
                    } else if filteredFriendList.count > 0 || filteredGroupList.count > 0 {
                        if filteredFriendList.count > 0 {
                            added.removeAtIndex(added.indexOf((self.filteredFriendList[indexPath.row].profid!))!)
                            cellcheck(false, profid: filteredFriendList[indexPath.row].profid!)
                        } else {
                            let array = (filteredGroupList[indexPath.row].memberstring!).characters.split {$0 == ";"}.map { String($0) }
                            for (var i = 0; i < array.count ; i++ ) {
                                if added.contains(array[i]) {
                                    if (array[i] != Globals.currentprofile?.profid){
                                        added.removeAtIndex(added.indexOf(array[i])!);
                                        cellcheck(false, profid: array[i]);
                                    } else {
                                    }
                                }
                            }
                        }
                    } else {
                    }
                } else {
                    if indexPath.section == 0 {
                        let array = (GroupList[indexPath.row].memberstring!).characters.split {$0 == ";"}.map { String($0) }
                        for (var i = 0; i < array.count ; i++ ) {
                            if added.contains(array[i]) {
                                if (array[i] != Globals.currentprofile?.profid){
                                    added.removeAtIndex(added.indexOf(array[i])!);
                                    cellcheck(false, profid: array[i]);
                                } else {
                                }
                            }
                        }
                    } else if indexPath.section == 1 {
                        added.removeAtIndex(added.indexOf((self.FriendList[indexPath.row].profid!))!)
                        cellcheck(false, profid: FriendList[indexPath.row].profid!)
                    }
                    
                }
            }
        }
        format();
        groupcheck();
    }
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        if (nogroups) {
            if (searchController.active && searchController.searchBar.text!.characters.count > 0) {
                if filteredFriendList.count > 0 {
                    return 1;
                } else {
                    return 0;
                }
            } else {
                return 1;
            }
        } else {
            if (searchController.active && searchController.searchBar.text!.characters.count > 0) {
                if filteredFriendList.count > 0 && filteredGroupList.count > 0{
                    return 2;
                } else if filteredFriendList.count > 0 || filteredGroupList.count > 0 {
                    return 1;
                } else {
                    return 0;
                }
            } else {
                return 2;
            }
        }
    }
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if (nogroups) {
            if (searchController.active && searchController.searchBar.text!.characters.count > 0) {
                if filteredFriendList.count > 0 {
                    if (section == 0) {
                        return "Invite Friends";
                    } else { return nil; };
                } else {
                    return nil;
                }
            } else {
                return "Invite Friends";
            }
        } else  {
            if (searchController.active && searchController.searchBar.text!.characters.count > 0) {
                if filteredFriendList.count > 0 && filteredGroupList.count > 0{
                    if (section == 0) {
                        return "Invite Groups";
                    } else if (section == 1) {
                        return "Invite Friends";
                    } else {
                        return nil;
                    }
                } else if filteredFriendList.count > 0 || filteredGroupList.count > 0 {
                    if filteredFriendList.count > 0 {
                        if (section == 0) {
                            return "Invite Friends";
                        } else { return nil; };
                    } else {
                        if (section == 0) {
                            return "Invite Groups";
                        } else { return nil; };
                    }
                } else {
                    return nil;
                }
            } else {
                if (section == 0) {
                    return "Invite Groups";
                } else if (section == 1) {
                    return "Invite Friends";
                } else {
                    return nil;
                }
            }
        }
    }
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if (nogroups) {
            if (searchController.active && searchController.searchBar.text!.characters.count > 0) {
                if filteredFriendList.count > 0 {
                    if (section == 0) {
                        return filteredFriendList.count;
                    } else { return 0; };
                } else {
                    return 0;
                }
            } else {
                if (section == 0) {
                    return FriendList.count;
                } else { return 0; };
            }
        } else  {
            if (searchController.active && searchController.searchBar.text!.characters.count > 0) {
                if filteredFriendList.count > 0 && filteredGroupList.count > 0{
                    if (section == 0) {
                        return filteredGroupList.count;
                    } else if (section == 1) {
                        return filteredFriendList.count;
                    } else {
                        return 0;
                    }
                } else if filteredFriendList.count > 0 || filteredGroupList.count > 0 {
                    if filteredFriendList.count > 0 {
                        if (section == 0) {
                            return filteredFriendList.count;
                        } else { return 0; };
                    } else {
                        if (section == 0) {
                            return filteredGroupList.count;
                        } else { return 0; };
                    }
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
    }
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if (nogroups) {
            if (searchController.active && searchController.searchBar.text!.characters.count > 0) {
                if filteredFriendList.count > 0 {
                    if (indexPath.section == 0) {
                        return getFriendCell(filteredFriendList[indexPath.row]);
                    } else { return UITableViewCell(); };
                } else {
                    return UITableViewCell();
                }
            } else {
                if (indexPath.section == 0) {
                    return getFriendCell(FriendList[indexPath.row]);
                } else { return UITableViewCell(); };
            }
        } else  {
            if (searchController.active && searchController.searchBar.text!.characters.count > 0) {
                if filteredFriendList.count > 0 && filteredGroupList.count > 0{
                    if (indexPath.section == 0) {
                        return getGroupEmptyCell(filteredGroupList[indexPath.row]);
                    } else if (indexPath.section == 1) {
                        return getFriendCell(filteredFriendList[indexPath.row]);
                    } else {
                        return UITableViewCell();
                    }
                } else if filteredFriendList.count > 0 || filteredGroupList.count > 0 {
                    if filteredFriendList.count > 0 {
                        if (indexPath.section == 0) {
                            return getFriendCell(filteredFriendList[indexPath.row]);
                        } else { return UITableViewCell(); };
                    } else {
                        if (indexPath.section == 0) {
                            return getGroupEmptyCell(filteredGroupList[indexPath.row]);
                        } else { return UITableViewCell(); };
                    }
                } else {
                    return UITableViewCell();
                }
            } else {
                if (indexPath.section == 0) {
                    return getGroupEmptyCell(GroupList[indexPath.row]);
                } else if (indexPath.section == 1) {
                    return getFriendCell(FriendList[indexPath.row]);
                } else {
                    return UITableViewCell();
                }
            }
        }
    }
    func getFriendCell(inputprofile: Profile) -> UITableViewCell {
        let cell = invitetable.dequeueReusableCellWithIdentifier("Friend") as! FriendCell;
        cell.friendlabel.text = inputprofile.name;
        cell.friendimage.image = UIImage(data: inputprofile.imagedata!);
        cell.profid = inputprofile.profid;
        cell.selectionStyle = UITableViewCellSelectionStyle.None;
        if (added.contains((inputprofile.profid!)) == false) {
            if (memberstring.characters.split {$0 == ";"}.map { String($0) }.contains((inputprofile.profid!)) == true) {
                cell.accessoryType = UITableViewCellAccessoryType.Checkmark;
                cell.setSelected(true , animated: true)
                cell.tintColor = UIColor.grayColor();
            } else {
                cell.accessoryType = UITableViewCellAccessoryType.None;
                cell.setSelected(true , animated: true)
            }
        } else {
            cell.accessoryType = UITableViewCellAccessoryType.Checkmark;
            cell.setSelected(true , animated: true)
        }
        return cell;
        
    }
    func getGroupEmptyCell(inputgroup: Group) -> UITableViewCell {
        let cell = invitetable.dequeueReusableCellWithIdentifier("GroupEmpty") as! GroupCellEmpty;
        let currentgroup = inputgroup
        cell.grouptextfield.text = currentgroup.name;
        cell.groupimage.image = UIImage(named: "unkownprofile.png");
        cell.memberlabel.text = Group.getMemberString(currentgroup.memberstring!);
        cell.memberlist = currentgroup.memberstring;
        cell.groupimage.image = Group.generateGroupImage(currentgroup.memberstring);
        var combined:[String] = added;
        let members:[String] = memberstring.characters.split {$0 == ";"}.map { String($0) }
        combined.appendContentsOf(members);
        let combinedSet = NSSet(array: combined)
        let memberSet = NSSet(array: members)
        let CheckCombined:Bool;
        let CheckMembers: Bool;
        if (combined.count>0) {
            CheckCombined = NSSet(array: (array: cell.memberlist.characters.split {$0 == ";"}.map { String($0) })).isSubsetOfSet(combinedSet as Set<NSObject>); //Check if the input members + added members are in group
        } else {
            CheckCombined = false;
        }
        if (members.count > 0) {
            CheckMembers =  NSSet(array: (array: cell.memberlist.characters.split {$0 == ";"}.map { String($0) })).isSubsetOfSet(memberSet as Set<NSObject>); //Check if only the input members are in group
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
    }
}