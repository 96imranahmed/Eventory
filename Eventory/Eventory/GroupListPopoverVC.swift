//
//  GroupListPopoverVC.swift
//  Eventory
//
//  Created by Imran Ahmed on 24/07/2015.
//  Copyright (c) 2015 Imran Ahmed. All rights reserved.
//

import UIKit

class GroupListPopoverVC: UIViewController, UITableViewDataSource, UITableViewDelegate, UISearchControllerDelegate, UISearchResultsUpdating{
    @IBOutlet weak var container: UIView!
    var groupimage: UIImageView! = UIImageView(frame: CGRectMake(8, 10, 50, 50))
    var grouplabel: UILabel! = UILabel(frame: CGRectMake(66, 24, 400, 21))
    var groupnameholderview: UIView! = UIView(frame: CGRectMake(0, 70, 300, 65))
    var currentgroup:Group?;
    var width:CGFloat = 0;
    @IBOutlet weak var grouplist: UITableView!
    var memberlist:[Profile]! = [];
    var filteredmemberlist:[Profile]! = [];
    var invitedlist:[Profile]! = [];
    var filteredinvitelist:[Profile]! = [];
    let searchController = UISearchController(searchResultsController: nil);
    override func viewDidLoad() {
        super.viewDidLoad()
        grouplist.delegate = self;
        grouplist.dataSource = self;
        memberlist = Group.returnSavedFriends(currentgroup!.memberstring!, membersfind: true);
        invitedlist = Group.returnSavedFriends(currentgroup!.invitedstring!, membersfind: false);
        NSNotificationCenter.defaultCenter().removeObserver(self);
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "updateMemberList:", name: "Eventory_Group_List_Updated", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "updateMemberPicture:", name: "Eventory_Group_Picture_Updated", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "updateInvitedList:", name: "Eventory_Group_Invited_List_Updated", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "updateInvitedPicture:", name: "Eventory_Group_Invited_Picture_Updated", object: nil)
        groupimage.layer.masksToBounds = true;
        groupimage.layer.cornerRadius = 25;
        let image = Group.generateGroupImage(currentgroup?.memberstring);
        groupimage.image = image;
        if (currentgroup?.isadmin == true) {
            grouplabel.text = (currentgroup?.name)!;
        } else {
            grouplabel.text = currentgroup?.name;
        }
        grouplabel.frame.size = grouplabel.sizeThatFits(CGSizeMake(width - 66, 65))
        groupnameholderview.addSubview(groupimage)
        groupnameholderview.addSubview(grouplabel)
        groupnameholderview.frame.size = CGSize(width: grouplabel.frame.width + 66, height: 60)
        var tap = UITapGestureRecognizer(target: self, action: "tableViewTapped:");
        self.container.addGestureRecognizer(tap);
        container.addSubview(groupnameholderview)
        container.bringSubviewToFront(groupnameholderview);
        groupnameholderview.center = CGPointMake(width/2 - 2 , 32.5)
        searchController.searchResultsUpdater = self
        searchController.hidesNavigationBarDuringPresentation = false
        searchController.dimsBackgroundDuringPresentation = false
        searchController.searchBar.sizeToFit()
        searchController.searchBar.placeholder = "Search Members"
        self.grouplist.tableHeaderView = searchController.searchBar
        self.grouplist.bringSubviewToFront(searchController.searchBar);
        var checktap = UITapGestureRecognizer(target: self, action: "tableViewTapped:");
        checktap.cancelsTouchesInView = false;
        self.grouplist.addGestureRecognizer(checktap);
        self.definesPresentationContext = true;
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func updateMemberList(notification:NSNotification) {
        NSLog("Members updated");
        let currentinsert = notification.userInfo!["Friends"] as! [Profile]!;
        for (var i = 0; i<currentinsert.count; i++){
            Profile.downloadUnknownPictureAsync(currentinsert[i], membersfind: true);
        }
        memberlist.extend(currentinsert);
        dispatch_async(dispatch_get_main_queue()){
            UIView.transitionWithView(self.grouplist, duration:0.1, options: UIViewAnimationOptions.TransitionCrossDissolve,
                animations: {
                    self.grouplist.reloadData();
                },
                completion: nil)
        }
    }
    
    func updateMemberPicture(notification: NSNotification) {
        NSLog("Member pic updated");
        let id = notification.userInfo!["ID"] as! String;
        let data = notification.userInfo!["Data"] as! NSData;
        for (var i = 0; i < memberlist.count; i++) {
            if (memberlist[i].profid == id) {
                memberlist[i].imagedata = data;
                dispatch_async(dispatch_get_main_queue()){
                    UIView.transitionWithView(self.grouplist, duration:0.1, options: UIViewAnimationOptions.TransitionCrossDissolve,
                        animations: {
                            self.grouplist.reloadData();
                        },
                        completion: nil)
                }
                break
            }
        }
    }
    func updateInvitedList(notification:NSNotification) {
        NSLog("Invites updated");
        let currentinsert = notification.userInfo!["Friends"] as! [Profile]!;
        invitedlist.extend(currentinsert);
        for (var i = 0; i<currentinsert.count; i++){
            Profile.downloadUnknownPictureAsync(currentinsert[i], membersfind:false);
        }
        dispatch_async(dispatch_get_main_queue()){
            UIView.transitionWithView(self.grouplist, duration:0.1, options: UIViewAnimationOptions.TransitionCrossDissolve,
                animations: {
                    self.grouplist.reloadData();
                },
                completion: nil)
        }
    }
    
    func updateInvitedPicture(notification: NSNotification) {
        NSLog("Invites pic updated");
        let id = notification.userInfo!["ID"] as! String;
        let data = notification.userInfo!["Data"] as! NSData;
        for (var i = 0; i < memberlist.count; i++) {
            if (invitedlist[i].profid == id) {
                invitedlist[i].imagedata = data;
                dispatch_async(dispatch_get_main_queue()){
                    UIView.transitionWithView(self.grouplist, duration:0.1, options: UIViewAnimationOptions.TransitionCrossDissolve,
                        animations: {
                            self.grouplist.reloadData();
                        },
                        completion: nil)
                }
                break
            }
        }
    }
    //MARK: Search Bar Methods
    func updateSearchResultsForSearchController(searchinputController: UISearchController) {
        filteredmemberlist.removeAll(keepCapacity: false);
        filteredinvitelist.removeAll(keepCapacity: false);
        var predicate:NSPredicate = NSPredicate(format: "SELF.name CONTAINS[c] %@", searchinputController.searchBar.text);
        filteredmemberlist = memberlist.filter({predicate.evaluateWithObject($0)});
        filteredinvitelist = invitedlist.filter({predicate.evaluateWithObject($0)});
        self.grouplist.reloadData();
    }
    
    //MARK: Table View Methods
    func tableViewTapped (tap: UITapGestureRecognizer) {
        if self.searchController.searchBar.isFirstResponder() {
            self.searchController.searchBar.resignFirstResponder();
        }
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        var i = 0;
        if searchController.active && count(searchController.searchBar.text) > 0 {
            if (filteredmemberlist.count>0) {
                i = i + 1;
            }
            if (filteredinvitelist.count>0) {
                i = i + 1;
            }
        } else {
            if (memberlist.count>0) {
                i = i + 1;
            }
            if (invitedlist.count>0) {
                i = i + 1;
            }
        }
        return i;
    }
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if searchController.active && count(searchController.searchBar.text) > 0 {
            if filteredinvitelist.count > 0 && filteredmemberlist.count > 0 {
                if section == 0 {
                    return "Group Members";
                } else if section == 1 {
                    return "Invited Members";
                } else { return "";}
            } else if filteredinvitelist.count > 0 || filteredmemberlist.count > 0 {
                if filteredinvitelist.count > 0 {
                    return "Invited Members";
                } else {
                    return "Group Members";
                }
            } else {
                return "";
            }
        } else {
            if (section==0) {
                if (memberlist.count>0) {
                    //Members First
                    return "Group Members" //"'" + currentgroup!.name! + "' Group Members";
                } else if (invitedlist.count>0 && memberlist.count == 0) {
                    //Invited Only
                    return  "Invited Members" //"'" + currentgroup!.name! + "' Invited Members";
                } else {
                    return nil;
                }
            } else if (section == 1) {
                //Invited Second
                return "Invited Members" //"'" + currentgroup!.name! + "' Invited Members";
            } else {
                return nil;
            }
        }
    }
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if searchController.active && count(searchController.searchBar.text) > 0 {
            if filteredinvitelist.count > 0 && filteredmemberlist.count > 0 {
                if section == 0 {
                    return filteredmemberlist.count;
                } else if section == 1 {
                    return filteredinvitelist.count;
                } else { return 0;}
            } else if filteredinvitelist.count > 0 || filteredmemberlist.count > 0 {
                if filteredinvitelist.count > 0 {
                    return filteredinvitelist.count;
                } else {
                    return filteredmemberlist.count;
                }
            } else {
                return 0;
            }
        } else {
            if (section==0) {
                if (memberlist.count>0) {
                    //Members First
                    return memberlist.count;
                } else if (invitedlist.count>0 && memberlist.count == 0) {
                    //Invited Only
                    return invitedlist.count;
                } else {
                    return 0;
                }
            } else if (section == 1) {
                //Invited Second
                return invitedlist.count;
            } else {
                return 0;
            }
        }
        
    }
    func getFriendCell(inputprofile: Profile) -> UITableViewCell {
        var cell = grouplist.dequeueReusableCellWithIdentifier("Friend") as! FriendCell;
        if Globals.currentprofile?.profid == inputprofile.profid {
            cell.friendlabel.text = "You";
        } else {
            cell.friendlabel.text = inputprofile.name;
        }
        cell.friendimage.image = UIImage(data: inputprofile.imagedata!);
        cell.profid = inputprofile.profid;
        return cell;
    }
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if searchController.active && count(searchController.searchBar.text) > 0 {
            if filteredinvitelist.count > 0 && filteredmemberlist.count > 0 {
                if indexPath.section == 0 {
                    return getFriendCell(filteredmemberlist[indexPath.row]);
                } else if indexPath.section == 1 {
                    return getFriendCell(filteredinvitelist[indexPath.row]);
                } else { return UITableViewCell();}
            } else if filteredinvitelist.count > 0 || filteredmemberlist.count > 0 {
                if filteredinvitelist.count > 0 {
                    return getFriendCell(filteredinvitelist[indexPath.row]);
                } else {
                    return getFriendCell(filteredmemberlist[indexPath.row]);
                }
            } else {
                return UITableViewCell();
            }
        } else {
            if (indexPath.section==0) {
                if (memberlist.count>0) {
                    //Members First
                    return getFriendCell(memberlist[indexPath.row]);
                } else if (invitedlist.count>0 && memberlist.count == 0) {
                    //Invited Only
                    return getFriendCell(invitedlist[indexPath.row]);
                } else {
                    return UITableViewCell();
                }
            } else if (indexPath.section == 1) {
                //Invited Second
                return getFriendCell(invitedlist[indexPath.row]);
            } else {
                return UITableViewCell();
            }
        }
    }
    
}
