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
    //Progress bar
    var messageFrame = UIView();
    var activityIndicator = UIActivityIndicatorView();
    var strLabel = UILabel();
    //For SWTableviewCell
    var preoffset = 0;
    var lastOffset: CGPoint = CGPointMake(0, 0);
    var lastOffsetCapture: NSTimeInterval = 0.0;
    var isScrollingFast: Bool = false;
    var cellcheck = ["Disabled" : false, "Index" : NSIndexPath(forRow: 0, inSection: 0)]
    var declinedload:Bool = false;
    var leftload:Bool = false;
    var displayed:Bool = false;
    let refreshControl = UIRefreshControl()
    @IBOutlet weak var grouptable: UITableView!
    override func viewDidLoad() {
        super.viewDidLoad()
        grouptable.delegate = self;
        grouptable.dataSource = self;
        refreshControl.addTarget(self, action: "refresh", forControlEvents: .ValueChanged)
        refreshControl.attributedTitle = NSAttributedString(string: "Refreshing...");
        grouptable.addSubview(refreshControl)
        if (Reachability.isConnectedToNetwork()) {
            var params = Dictionary<String,AnyObject>();
            params["type"] = "1";
            Reachability.postToServer("group_get.php", postdata: params, customselector: "DeclinedGroupLoad");
            params["type"] = "2";
            Reachability.postToServer("group_get.php", postdata: params, customselector: "LeftGroupLoad");
            progressBarDisplayer("Loading...", indicator: true);
        } else {
            RKDropdownAlert.title("Offline!", message: "You are currently not connected to the internet! :(");
        }
        NSNotificationCenter.defaultCenter().removeObserver(self);
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "groupupdated:", name: "Eventory_Group_Saved", object: nil);
        // Do any additional setup after loading the view.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    func trigrefresh(timer:NSTimer) {
        refresh();
    }
    func refresh() {
        dispatch_async(dispatch_get_main_queue()){
            self.grouptable.reloadData();
        }
        var params = Dictionary<String,AnyObject>();
        leftload = false;
        declinedload = false;
        self.displayed = false;
        if (Reachability.isConnectedToNetwork()) {
            params["type"] = "1";
            Reachability.postToServer("group_get.php", postdata: params, customselector: "DeclinedGroupLoad");
            params["type"] = "2";
            Reachability.postToServer("group_get.php", postdata: params, customselector: "LeftGroupLoad");
            self.progressBarDisplayer("Loading...", indicator: true);
        } else {
            dispatch_async(dispatch_get_main_queue()){
                RKDropdownAlert.title("Offline!", message: "You are currently not connected to the internet! :(");
                self.refreshControl.endRefreshing();
            }
        }
    }
    func groupupdated(notification:NSNotification) {
        let type = notification.userInfo!["Type"] as! Int!;
        let data = notification.userInfo!["Groups"] as! [Group]!;
        if (type != 0) {
            if (type == 1) {
                declinedGroups = Group.SortGroups(data);
                declinedload = true;
            } else if (type == 2) {
                leftGroups = Group.SortGroups(data);
                leftload = true;
            }
            dispatch_async(dispatch_get_main_queue()){
                if (self.declinedGroups.count == 0 && self.leftGroups.count == 0 && self.declinedload && self.leftload && !self.displayed) {
                    RKDropdownAlert.title("No Left or Declined Groups!", backgroundColor: Schemes.returnColor("Amethyst", alpha: 1.0), textColor: UIColor.whiteColor())
                    self.displayed = true;
                }
                if (self.declinedload && self.leftload) {
                    self.refreshControl.endRefreshing();
                    self.messageFrame.removeFromSuperview();
                    self.grouptable.reloadData();
                }
            }
            
        }
    }
    
    func groupoverlayload(inputgroup: Group) {
        let currentgroup = inputgroup;
        let popoverVC = self.storyboard?.instantiateViewControllerWithIdentifier("PopoverGroupList") as! GroupListPopoverVC!
        popoverVC.currentgroup = currentgroup;
        let members:[String] = (currentgroup.memberstring?.componentsSeparatedByString(";"))!;
        let invited:[String] = (currentgroup.invitedstring?.componentsSeparatedByString(";"))!;
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
        self.presentViewController(popoverVC, animated: true, completion: nil);
    }
    func adaptivePresentationStyleForPresentationController(controller: UIPresentationController) -> UIModalPresentationStyle {
        return UIModalPresentationStyle.None
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
    //MARK: - Table view delegate
    func getGroup(atindex: NSIndexPath) -> Group {
        if (leftGroups.count>0 && declinedGroups.count>0) {
            if (atindex.section == 0) {
                return leftGroups[atindex.row];
            } else if (atindex.section == 1) {
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
            } else if (section == 1) {
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
            } else if (section == 1) {
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
                let cell = tableView.dequeueReusableCellWithIdentifier("LeftDeclinedDecisionCell") as! LeftDeclinedDecisionCell;
                let inputgroup = leftGroups[indexPath.row];
                cell.group = inputgroup;
                cell.type = 1;
                cell.detail.text = Group.getMemberString(inputgroup.memberstring!);
                cell.title.text = inputgroup.name;
                cell.picture.image = Group.generateGroupImage(inputgroup.memberstring!);
                cell.delegate = self;
                cell.setDecisionLayout();
                return cell;
            } else if (indexPath.section == 1) {
                let cell = tableView.dequeueReusableCellWithIdentifier("LeftDeclinedDecisionCell") as! LeftDeclinedDecisionCell;
                let inputgroup = declinedGroups[indexPath.row];
                cell.group = inputgroup;
                cell.type = 2;
                cell.detail.text = Group.getMemberString(inputgroup.memberstring!);
                cell.title.text = inputgroup.name;
                cell.picture.image = Group.generateGroupImage(inputgroup.memberstring!);
                cell.delegate = self;
                cell.setDecisionLayout();
                return cell;
            } else {
                return UITableViewCell();
            }
            
        } else if (leftGroups.count>0 || declinedGroups.count>0){
            if (leftGroups.count>0) {
                if (indexPath.section == 0) {
                    let cell = tableView.dequeueReusableCellWithIdentifier("LeftDeclinedDecisionCell") as! LeftDeclinedDecisionCell;
                    let inputgroup = leftGroups[indexPath.row];
                    cell.group = inputgroup;
                    cell.type = 1;
                    cell.detail.text = Group.getMemberString(inputgroup.memberstring!);
                    cell.title.text = inputgroup.name;
                    cell.picture.image = Group.generateGroupImage(inputgroup.memberstring!);
                    cell.delegate = self;
                    cell.setDecisionLayout();
                    return cell;
                } else {
                    return UITableViewCell();
                }
            } else {
                if (indexPath.section == 0) {
                    let cell = tableView.dequeueReusableCellWithIdentifier("LeftDeclinedDecisionCell") as! LeftDeclinedDecisionCell;
                    let inputgroup = declinedGroups[indexPath.row];
                    cell.group = inputgroup;
                    cell.type = 2;
                    cell.detail.text = Group.getMemberString(inputgroup.memberstring!);
                    cell.title.text = inputgroup.name;
                    cell.picture.image = Group.generateGroupImage(inputgroup.memberstring!);
                    cell.delegate = self;
                    cell.setDecisionLayout();
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
        grouptable.deselectRowAtIndexPath(indexPath, animated: true);
    }
    //MARK: - SWTableViewCell delegate
    func swipeableTableViewCell(cell: SWTableViewCell!, didScroll scrollView: UIScrollView!) {
        let currentOffset: CGPoint = scrollView.contentOffset;
        let currentTime: NSTimeInterval = NSDate.timeIntervalSinceReferenceDate();
        let timeDiff: NSTimeInterval = currentTime - lastOffsetCapture;
        if(timeDiff > 0.1) {
            let distance: CGFloat = currentOffset.x - lastOffset.x;
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
        _ = cell.frame.size.width;
        let offset = cell.cellState.rawValue
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
                }
            }
        }
        preoffset = offset
    }
    func reaccept(index: NSIndexPath) {
        let group = getGroup(index);
        let result = leftGroups.filter { $0.groupid == group.groupid};
        var message = "";
        var title = "";
        if (!result.isEmpty) {
            message = "Are you sure you want to re-join " + group.name! + "?";
            title = "Re-join Group";
        } else {
            message = "Are you sure you want to accept your invite to " + group.name! + "?";
            title = "Accept Group Invite";
        }
        dispatch_async(dispatch_get_main_queue()) {
            let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.Alert)
            alert.addAction(UIAlertAction(title: "Nope!", style: .Cancel, handler: { action in
            }))
            alert.addAction(UIAlertAction(title: "Yep!", style: .Default, handler: { action in
                var params = Dictionary<String,AnyObject>();
                params["accepted"] = 1.description;
                params["groupid"] = group.groupid;
                if (Reachability.isConnectedToNetwork()) {
                    Reachability.postToServer("group_decision.php", postdata: params, customselector: "");
                    if (!result.isEmpty) {
                        self.leftGroups = self.leftGroups.filter({$0.groupid != group.groupid});
                    } else {
                        self.declinedGroups = self.declinedGroups.filter({$0.groupid != group.groupid});
                    }
                    _ = NSTimer.scheduledTimerWithTimeInterval(1, target: self, selector: "trigrefresh:", userInfo: nil, repeats: false);
                } else {
                    RKDropdownAlert.title("Offline!", message: "You are currently not connected to the internet! :(");
                }
            }))
            self.presentViewController(alert, animated: true, completion: nil)
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
    func swipeableTableViewCell(cell: SWTableViewCell!, canSwipeToState state: SWCellState) -> Bool {
        return true;
    }
}
