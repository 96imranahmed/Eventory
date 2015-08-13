//
//  GroupListPopoverVC.swift
//  Eventory
//
//  Created by Imran Ahmed on 24/07/2015.
//  Copyright (c) 2015 Imran Ahmed. All rights reserved.
//

import UIKit

class GroupListPopoverVC: UIViewController, UITableViewDataSource, UITableViewDelegate {
    @IBOutlet weak var container: UIView!
    var groupimage: UIImageView! = UIImageView(frame: CGRectMake(8, 10, 50, 50))
    var grouplabel: UILabel! = UILabel(frame: CGRectMake(66, 24, 400, 21))
    var groupnameholderview: UIView! = UIView(frame: CGRectMake(0, 70, 300, 65))
    var currentgroup:Group?;
    var width:CGFloat = 0;
    @IBOutlet weak var grouplist: UITableView!
    var memberlist:[Profile]! = [];
    var invitedlist:[Profile]! = [];
    override func viewDidLoad() {
        super.viewDidLoad()
        grouplist.delegate = self;
        grouplist.dataSource = self;
        memberlist = Group.returnSavedFriends(currentgroup!.memberstring!, membersfind: true);
        invitedlist = Group.returnSavedFriends(currentgroup!.invitedstring!, membersfind: false);
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "updateMemberList:", name: "Eventory_Group_List_Updated", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "updateMemberPicture:", name: "Eventory_Group_Picture_Updated", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "updateInvitedList:", name: "Eventory_Group_Invited_List_Updated", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "updateInvitedPicture:", name: "Eventory_Group_Invited_Picture_Updated", object: nil)
        groupimage.layer.masksToBounds = true;
        groupimage.layer.cornerRadius = 25;
        groupimage.image = Group.generateGroupImage(currentgroup?.memberstring)
        if (currentgroup?.isadmin == true) {
        grouplabel.text = (currentgroup?.name)!;
        } else {
        grouplabel.text = currentgroup?.name;
        }
        grouplabel.frame.size = grouplabel.sizeThatFits(CGSizeMake(width - 66, 65))
        //NSLog(grouplabel.frame.width.description);
        //NSLog((grouplabel.frame.width + 66).description)
        groupnameholderview.addSubview(groupimage)
        groupnameholderview.addSubview(grouplabel)
        groupnameholderview.frame.size = CGSize(width: grouplabel.frame.width + 66, height: 65)
        //groupnameholderview.sizeThatFits(CGSizeMake(width, 65))
        //NSLog(groupnameholderview.center.x.description);
        //container.setNeedsDisplayInRect(CGRectMake(0,0,50 + 8 + grouplabel.frame.size.width, 65));
        container.addSubview(groupnameholderview)
        groupnameholderview.center = CGPointMake(width/2 - 2 , 32.5)
        // Do any additional setup after loading the view.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func updateMemberList(notification:NSNotification) {
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
    
    //MARK: Table View Methods
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        var i = 0;
        if (memberlist.count>0) {
            i = i + 1;
        }
        if (invitedlist.count>0) {
            i = i + 1;
        }
        return i;
    }
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
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
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
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
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if (indexPath.section==0) {
            if (memberlist.count>0) {
                //Members First
                var cell = tableView.dequeueReusableCellWithIdentifier("Friend") as! FriendCell;
                cell.friendlabel.text = memberlist[indexPath.row].name;
                cell.friendimage.image = UIImage(data: memberlist[indexPath.row].imagedata!);
                cell.profid = memberlist[indexPath.row].profid;
                return cell;
            } else if (invitedlist.count>0 && memberlist.count == 0) {
                //Invited Only
                var cell = tableView.dequeueReusableCellWithIdentifier("Friend") as! FriendCell;
                cell.friendlabel.text = invitedlist[indexPath.row].name;
                cell.friendimage.image = UIImage(data: invitedlist[indexPath.row].imagedata!);
                cell.profid = invitedlist[indexPath.row].profid;
                return cell;
            } else {
                return UITableViewCell();
            }
        } else if (indexPath.section == 1) {
            //Invited Second
            var cell = tableView.dequeueReusableCellWithIdentifier("Friend") as! FriendCell;
            cell.friendlabel.text = invitedlist[indexPath.row].name;
            cell.friendimage.image = UIImage(data: invitedlist[indexPath.row].imagedata!);
            cell.profid = invitedlist[indexPath.row].profid;
            return cell;
        } else {
            return UITableViewCell();
        }
           }
    
}
