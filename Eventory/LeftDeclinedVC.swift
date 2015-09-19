//
//  LeftDeclinedVC.swift
//  Eventory
//
//  Created by Imran Ahmed on 16/09/2015.
//  Copyright (c) 2015 Imran Ahmed. All rights reserved.
//

import UIKit

class LeftDeclinedVC: UIViewController, UITableViewDelegate, UITableViewDataSource, SWTableViewCellDelegate, UIPopoverPresentationControllerDelegate {
    var leftGroups:[Group] = [];
    var declinedGroups:[Group] = [];
    //For SWTableviewCell
    var preoffset = 0;
    var lastOffset: CGPoint = CGPointMake(0, 0);
    var lastOffsetCapture: NSTimeInterval = 0.0;
    var isScrollingFast: Bool = false;
    var cellcheck = ["Disabled" : false, "Index" : NSIndexPath(forRow: 0, inSection: 0)]
    //Load Cell
    var messageFrame = UIView();
    var activityIndicator = UIActivityIndicatorView();
    var strLabel = UILabel();
    @IBOutlet weak var grouptable: UITableView!
    override func viewDidLoad() {
        super.viewDidLoad()
        grouptable.delegate = self;
        grouptable.dataSource = self;
        var params = Dictionary<String,AnyObject>();
        params["type"] = "1";
        Reachability.postToServer("group_get.php", postdata: params, customselector: "DeclinedGroupLoad");
        params["type"] = "2";
        Reachability.postToServer("group_get.php", postdata: params, customselector: "LeftGroupLoad");
        NSNotificationCenter.defaultCenter().removeObserver(self);
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "groupupdated:", name: "Eventory_Group_Saved", object: nil);
        // Do any additional setup after loading the view.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func progressBarDisplayer(msg:String, indicator:Bool ) {
        strLabel = UILabel(frame: CGRect(x: 50, y: 0, width: 200, height: 50))
        strLabel.text = msg
        strLabel.textColor = UIColor.whiteColor()
        messageFrame = UIView(frame: CGRect(x: view.frame.midX - 90, y: view.frame.midY - 25 , width: 180, height: 50))
        messageFrame.layer.cornerRadius = 15
        messageFrame.backgroundColor = UIColor(white: 0, alpha: 0.7)
        if indicator {
            activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.White)
            activityIndicator.frame = CGRect(x: 0, y: 0, width: 50, height: 50)
            activityIndicator.startAnimating()
            messageFrame.addSubview(activityIndicator)
        }
        messageFrame.addSubview(strLabel)
        view.addSubview(messageFrame)
    }
    func refresh() {
        var params = Dictionary<String,AnyObject>();
        params["type"] = "1";
        Reachability.postToServer("group_get.php", postdata: params, customselector: "DeclinedGroupLoad");
        params["type"] = "2";
        Reachability.postToServer("group_get.php", postdata: params, customselector: "LeftGroupLoad");
        dispatch_async(dispatch_get_main_queue()){
            UIView.transitionWithView(self.grouptable, duration:0.0, options: UIViewAnimationOptions.TransitionCrossDissolve,
                animations: {
                    self.grouptable.reloadData();
                },
                completion: nil)
        }
    }
    func groupupdated(notification:NSNotification) {
        let type = notification.userInfo!["Type"] as! Int;
        let data = notification.userInfo!["Groups"] as! [Group];
        if (type == 1) {
            declinedGroups = Group.SortGroups(data);
        } else if (type == 2) {
            leftGroups = Group.SortGroups(data);
        }
        if (declinedGroups.count == 0 && leftGroups.count == 0) {
            dispatch_async(dispatch_get_main_queue()){
                self.progressBarDisplayer("No declined/left groups!", indicator: false);
                var timer = NSTimer.scheduledTimerWithTimeInterval(2, target: self, selector: "timeout", userInfo: nil, repeats: false);
            }
        }
    }
    func timeout() {
        dispatch_async(dispatch_get_main_queue()){
            self.messageFrame.removeFromSuperview();
        }
    }
    func groupoverlayload(inputgroup: Group) {
        let currentgroup = inputgroup;
        let popoverVC = self.storyboard?.instantiateViewControllerWithIdentifier("PopoverGroupList") as! GroupListPopoverVC!
        popoverVC.currentgroup = currentgroup;
        var members:[String] = (currentgroup.memberstring?.componentsSeparatedByString(";"))!;
        var invited:[String] = (currentgroup.invitedstring?.componentsSeparatedByString(";"))!;
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
        var width = (Int(self.view.frame.size.width)-75);
        popoverVC.width = CGFloat(width);
        popoverVC.preferredContentSize = CGSizeMake(CGFloat(width), CGFloat(height))
        popoverVC.modalPresentationStyle = .Popover
        let popover = popoverVC.popoverPresentationController!
        popover.delegate = self
        popover.sourceView  = self.view
        popover.sourceRect = self.view.frame;
        popover.permittedArrowDirections = UIPopoverArrowDirection.allZeros;
        self.presentViewController(popoverVC, animated: true, completion: nil);
    }
    func adaptivePresentationStyleForPresentationController(controller: UIPresentationController) -> UIModalPresentationStyle {
        return UIModalPresentationStyle.None
    }
    
    //MARK: - Table view delegate
    func getGroup(atindex: NSIndexPath) -> Group {
        if (leftGroups.count>0 && declinedGroups.count>0) {
            if (atindex.section == 0) {
                return leftGroups[atindex.row];
            } else if (atindex.section == 0) {
                return declinedGroups[atindex.row];
            } else {
                return Group(name: nil, groupid: nil, memberstring: nil, invitedstring: nil, isadmin: false, save: false);
            }
        } else if (leftGroups.count>0 || declinedGroups.count>0){
            if (leftGroups.count>0) {
                if (atindex.section == 0) {
                    return leftGroups[atindex.row];
                } else {
                    return Group(name: nil, groupid: nil, memberstring: nil, invitedstring: nil, isadmin: false, save: false);
                }
            } else {
                if (atindex.section == 0) {
                    return declinedGroups[atindex.row];
                } else {
                    return Group(name: nil, groupid: nil, memberstring: nil, invitedstring: nil, isadmin: false, save: false);
                }
            }
        } else {
            return Group(name: nil, groupid: nil, memberstring: nil, invitedstring: nil, isadmin: false, save: false);
        }
    }
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if (leftGroups.count>0 && declinedGroups.count>0) {
            if (section == 0) {
                return leftGroups.count;
            } else if (section == 0) {
                return declinedGroups.count;
            } else {
                return 0;
            }
        } else if (leftGroups.count>0 || declinedGroups.count>0){
            if (leftGroups.count>0) {
                if (section == 0) {
                    return leftGroups.count;
                } else {
                    return 0;
                }
            } else {
                if (section == 0) {
                    return declinedGroups.count;
                } else {
                    return 0;
                }
            }
        } else {
            return 0;
        }
    }
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        if (leftGroups.count>0 && declinedGroups.count>0) {
            return 2;
        } else if (leftGroups.count>0 || declinedGroups.count>0){
            return 1;
        } else {
            return 0;
        }
    }
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if (leftGroups.count>0 && declinedGroups.count>0) {
            if (section == 0) {
                return "Left Groups";
            } else if (section == 0) {
                return "Declined Groups";
            } else {
                return "";
            }
        } else if (leftGroups.count>0 || declinedGroups.count>0){
            if (leftGroups.count>0) {
                if (section == 0) {
                    return "Left Groups";
                } else {
                    return "";
                }
            } else {
                if (section == 0) {
                    return "Declined Groups";
                } else {
                    return "";
                }
            }
        } else {
            return "";
        }
    }
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
    {
        if (leftGroups.count>0 && declinedGroups.count>0) {
            if (indexPath.section == 0) {
                var cell = tableView.dequeueReusableCellWithIdentifier("LeftDeclinedDecisionCell") as! LeftDeclinedDecisionCell;
                let inputgroup = leftGroups[indexPath.row];
                cell.group = inputgroup;
                cell.type = 1;
                cell.detail.text = Group.getMemberString(inputgroup.memberstring!);
                cell.title.text = inputgroup.name;
                cell.picture.image = Group.generateGroupImage(inputgroup.memberstring!);
                return cell;
            } else if (indexPath.section == 1) {
                var cell = tableView.dequeueReusableCellWithIdentifier("LeftDeclinedDecisionCell") as! LeftDeclinedDecisionCell;
                let inputgroup = declinedGroups[indexPath.row];
                cell.group = inputgroup;
                cell.type = 2;
                cell.detail.text = Group.getMemberString(inputgroup.memberstring!);
                cell.title.text = inputgroup.name;
                cell.picture.image = Group.generateGroupImage(inputgroup.memberstring!);
                return cell;
            } else {
                return UITableViewCell();
            }
            
        } else if (leftGroups.count>0 || declinedGroups.count>0){
            if (leftGroups.count>0) {
                if (indexPath.section == 0) {
                    var cell = tableView.dequeueReusableCellWithIdentifier("LeftDeclinedDecisionCell") as! LeftDeclinedDecisionCell;
                    let inputgroup = leftGroups[indexPath.row];
                    cell.group = inputgroup;
                    cell.type = 1;
                    cell.detail.text = Group.getMemberString(inputgroup.memberstring!);
                    cell.title.text = inputgroup.name;
                    cell.picture.image = Group.generateGroupImage(inputgroup.memberstring!);
                    return cell;
                } else {
                    return UITableViewCell();
                }
            } else {
                if (indexPath.section == 0) {
                    var cell = tableView.dequeueReusableCellWithIdentifier("LeftDeclinedDecisionCell") as! LeftDeclinedDecisionCell;
                    let inputgroup = declinedGroups[indexPath.row];
                    cell.group = inputgroup;
                    cell.type = 2;
                    cell.detail.text = Group.getMemberString(inputgroup.memberstring!);
                    cell.title.text = inputgroup.name;
                    cell.picture.image = Group.generateGroupImage(inputgroup.memberstring!);
                    return cell;
                } else {
                    return UITableViewCell();
                }
            }
        } else {
            return UITableViewCell();
        }
    }
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        groupoverlayload(getGroup(indexPath));
    }
    //MARK: - SWTableViewCell delegate
    func swipeableTableViewCell(cell: SWTableViewCell!, didScroll scrollView: UIScrollView!) {
        var currentOffset: CGPoint = scrollView.contentOffset;
        var currentTime: NSTimeInterval = NSDate.timeIntervalSinceReferenceDate();
        var timeDiff: NSTimeInterval = currentTime - lastOffsetCapture;
        if(timeDiff > 0.1) {
            var distance: CGFloat = currentOffset.x - lastOffset.x;
            let scrollSpeedNotAbs:CGFloat = (distance * 10) / 1000;
            let scrollSpeed = fabsf(Float(scrollSpeedNotAbs));
            //NSLog(scrollSpeed.description);
            if (scrollSpeed > 0.2) {
                isScrollingFast = true;
            } else {
                isScrollingFast = false;
            }
            lastOffset = currentOffset;
            lastOffsetCapture = currentTime;
        }
        var cellwidth = cell.frame.size.width;
        var offset = cell.cellState.rawValue
        if let index = grouptable.indexPathForCell(cell) {
            var canproceed: Bool = true;
            if (cellcheck["Index"] == index && cellcheck["Disabled"] == true) {
                canproceed = false;
            }
            if (canproceed) {
                cellcheck["Disabled"] = false;
                cellcheck["Index"] = index;
                if (offset == 1 && preoffset == 0 && isScrollingFast) {
                    reaccept(index);
                } else if (offset == 2 && preoffset == 0 && isScrollingFast) {
                    reaccept(index);
                }
            }
        }
        preoffset = offset
    }
    func reaccept(index: NSIndexPath) {
        let cell = grouptable.cellForRowAtIndexPath(index) as! NotificationDecisionCell;
        var animation: UITableViewRowAnimation;
        animation = UITableViewRowAnimation.Fade;
        let group = getGroup(index);
        let result = leftGroups.filter { $0.groupid == group.groupid};
        var params = Dictionary<String,AnyObject>();
        params["accepted"] = true.description;
        params["groupid"] = group.groupid;
        if (Reachability.isConnectedToNetwork()) {
            Reachability.postToServer("group_decision.php", postdata: params, customselector: "");
            refresh();
            if (grouptable.numberOfRowsInSection(index.section) == 1) {
                //Delete section
                grouptable.deleteSections(NSIndexSet(index: index.section), withRowAnimation: animation);
            } else {
                //Delete row
                grouptable.deleteRowsAtIndexPaths([index], withRowAnimation: animation)
            }
        } else {
            RKDropdownAlert.title("Offline!", message: "You are currently not connected to the internet! :(");
        }
    }
    func swipeableTableViewCell(cell: SWTableViewCell!, scrollingToState state: SWCellState) {
        if (state.rawValue == 0) {
            cellcheck["Disabled"] = true;
            cellcheck["Index"] = grouptable.indexPathForCell(cell!);
        } else {
            cellcheck["Disabled"] = false;
            cellcheck["Index"] = grouptable.indexPathForCell(cell!);
        }
    }
    func swipeableTableViewCellShouldHideUtilityButtonsOnSwipe(cell: SWTableViewCell!) -> Bool {
        return true;
    }
    func swipeableTableViewCellDidEndScrolling(cell: SWTableViewCell!) {
        cell.hideUtilityButtonsAnimated(true);
        preoffset = 0;
    }
    func swipeableTableViewCell(cell: SWTableViewCell!, didTriggerLeftUtilityButtonWithIndex index: Int) {
        let cellfind:NSIndexPath? = grouptable.indexPathForCell(cell);
        if let nonnilindex = cellfind
        {
            reaccept(nonnilindex);
        }
    }
}
