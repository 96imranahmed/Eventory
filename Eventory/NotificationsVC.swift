//
//  NotificationsVC.swift
//  Eventory
//
//  Created by Imran Ahmed on 30/07/2015.
//  Copyright (c) 2015 Imran Ahmed. All rights reserved.
//

import UIKit

class NotificationsVC: UIViewController, UITableViewDelegate, UITableViewDataSource, UIScrollViewDelegate, SWTableViewCellDelegate, UIPopoverPresentationControllerDelegate {
    @IBOutlet weak var notificationtable: UITableView!
    //Cell swipe
    let refreshControl = UIRefreshControl()
    var messageFrame = UIView();
    var activityIndicator = UIActivityIndicatorView();
    var strLabel = UILabel();
    //For SWTableviewCell
    var preoffset = 0;
    var lastOffset: CGPoint = CGPointMake(0, 0);
    var lastOffsetCapture: NSTimeInterval = 0.0;
    var isScrollingFast: Bool = false;
    //Other
    var notificationlist:[Notification] = [];
    var cellcheck = ["Disabled" : false, "Index" : NSIndexPath(forRow: 0, inSection: 0)]
    var pagenumber = 0;
    var isUpdating:Bool = false;
    var isScrolling:Bool = false;
    //Notification Types
    var decisiontypes = [1];
    override func viewDidDisappear(animated: Bool) {
        NSNotificationCenter.defaultCenter().removeObserver(self);
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.title = "Notifications"
        notificationlist = Globals.notifications;
        notificationtable.dataSource = self;
        notificationtable.delegate = self;
        refreshControl.addTarget(self, action: "refresh:", forControlEvents: .ValueChanged)
        refreshControl.attributedTitle = NSAttributedString(string: "Refreshing...");
        notificationtable.addSubview(refreshControl)
        if (Reachability.isConnectedToNetwork()) {
            Notification.getNotifications(Constants.notificationloadlimit, page: 0);
            pagenumber++;
            progressBarDisplayer("Loading...", indicator:true);
            _ = NSTimer.scheduledTimerWithTimeInterval(3, target: self, selector: "timeout", userInfo: nil, repeats: false);
        } else {
            RKDropdownAlert.title("Offline!", message: "You are currently not connected to the internet! :(");
        }
        NSNotificationCenter.defaultCenter().removeObserver(self);
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "refreshnotifications:", name: "Eventory_Notifications_Done", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "autorefresh:", name: "Eventory_Refresh_Trigger", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "groupdownload:", name: "Eventory_Group_Single_Done", object: nil)
        // Do any additional setup after loading the view.
    }
    func adaptivePresentationStyleForPresentationController(controller: UIPresentationController) -> UIModalPresentationStyle {
        return UIModalPresentationStyle.None
    }
    override func viewDidAppear(animated: Bool) {
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
        messageFrame.addSubview(strLabel);
        dispatch_async(dispatch_get_main_queue()){
        self.view.addSubview(self.messageFrame);
        }
    }
    //MARK: Update/Refresh functions
    func refreshnotifications(notification: NSNotification) {
        if let info = notification.userInfo {
            let count = info["Count"] as! Int;
            if (count >= Constants.notificationloadlimit) {
            } else {
                pagenumber--;
            }
        }
        if (Globals.notifications.count>0) {
            notificationlist = Globals.notifications;
            notificationlist.sortInPlace({ $0.date.timeIntervalSince1970 < $1.date.timeIntervalSince1970});
            dispatch_async(dispatch_get_main_queue()){
                UIView.transitionWithView(self.notificationtable, duration:0.0, options: UIViewAnimationOptions.TransitionCrossDissolve,
                    animations: {
                        if self.activityIndicator.isAnimating() {
                            self.messageFrame.removeFromSuperview();
                        }
                        self.refreshControl.endRefreshing();
                        self.notificationtable.reloadData();
                        self.isUpdating = false;
                    },
                    completion: nil)
            }
        } else {
            dispatch_async(dispatch_get_main_queue()){
                if self.activityIndicator.isAnimating() {
                    self.messageFrame.removeFromSuperview();
                }
                self.refreshControl.endRefreshing();
                self.isUpdating = false;
            }
        }
        //NSLog(pagenumber.description);
    }
    func groupdownload(notification: NSNotification) {
        dispatch_async(dispatch_get_main_queue()){
            let currentgroup = notification.userInfo!["Group"] as! Group!;
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
    }
    //MARK: Refresh & Timeout
    func timeout() {
        self.messageFrame.removeFromSuperview();
        refreshControl.endRefreshing();
    }
    func autorefresh(notification: NSNotification) {
        pagenumber = 0;
        if (Reachability.isConnectedToNetwork()) {
            Notification.getNotifications(Constants.notificationloadlimit, page: 0);
        }
        progressBarDisplayer("Loading...", indicator:true);
    }
    func refresh(refreshControl: UIRefreshControl) {
        pagenumber = 0;
        if (Reachability.isConnectedToNetwork()) {
            Notification.getNotifications(Constants.notificationloadlimit, page: 0);
        } else {
            RKDropdownAlert.title("Offline!", message: "You are currently not connected to the internet! :(");
        }
    }
    func cellselect(input: Notification) {
        if (input.notificationtype == 1 || input.notificationtype == 2) {
            if Reachability.isConnectedToNetwork() {
                let pos = input.notifdata!.rangeOfString(":", options: .BackwardsSearch)?.startIndex
                var groupidpost = input.notifdata!.substringFromIndex(pos!)
                groupidpost = String(groupidpost.characters.dropFirst());
                Group.downloadGroupASync(groupidpost);
            } else {
                RKDropdownAlert.title("Offline!", message: "You are currently not connected to the internet! :(");
            }
        }
    }
    //MARK: Table View Methods
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        if notificationlist.count > 0 {
            return 1
        } else {
            return 0
        }
    }
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "Notifications"
    }
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return notificationlist.count;
    }
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        let currentnotification = notificationlist[indexPath.row];
        if (decisiontypes.contains(currentnotification.notificationtype!)){
            return 85.0;
        } else {
            return 67.0;
        }

    }
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let currentnotification = notificationlist[indexPath.row];
        if (decisiontypes.contains(currentnotification.notificationtype!)){
            let cell = tableView.dequeueReusableCellWithIdentifier("DecisionCell") as! NotificationDecisionCell;
            cell.notification = currentnotification;
            cell.picture.image = Profile.getPicturefromCoreData(currentnotification.sourceID!);
            cell.unseen = !currentnotification.read;
            cell.title.text = currentnotification.text;
            cell.setDecisionLayout(currentnotification.notificationtype);
            cell.delegate = self;
            return cell;
        } else {
            let cell = tableView.dequeueReusableCellWithIdentifier("StandardCell") as! NotificationStandardCell;
            cell.notification = currentnotification;
            cell.picture.image = Profile.getPicturefromCoreData(currentnotification.sourceID!);
            cell.unseen = !currentnotification.read;
            cell.title.text = currentnotification.text;
            cell.setDecisionLayout(currentnotification.notificationtype);
            return cell;
        }
    }
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let notif = notificationlist[indexPath.row];
        //Read notification
        var paramsread = Dictionary<String,AnyObject>();
        paramsread["type"] = notif.notificationtype?.description;
        paramsread["data"] = notif.notifdata;
        Reachability.postToServer("notification_read.php", postdata: paramsread, customselector: nil);
        if (notif.read == false) {
            notif.read = true;
            Globals.unreadnotificationcount = Globals.unreadnotificationcount - 1;
            self.notificationtable.reloadData();
        }
        cellselect(notif);
        tableView.deselectRowAtIndexPath(indexPath, animated: true);
    }
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        let currentOffset = scrollView.contentOffset.y;
        let maximumOffset = scrollView.contentSize.height - scrollView.frame.size.height;
        if (maximumOffset - currentOffset <= 5.0 && isUpdating == false && isScrolling == false) || (currentOffset > maximumOffset && isUpdating == false && isScrolling == false){
            isUpdating = true;
            isScrolling = true;
            Notification.getNotifications(Constants.notificationloadlimit, page: pagenumber);
            pagenumber++;
            progressBarDisplayer("Loading...", indicator:true);
            _ = NSTimer.scheduledTimerWithTimeInterval(3, target: self, selector: "timeout", userInfo: nil, repeats: false);
        }
    }
    func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
        isScrolling = false;
    }
    //MARK: SWTableViewCell Methods
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
        if let index = notificationtable.indexPathForCell(cell) {
            var canproceed: Bool = true;
            if (cellcheck["Index"] == index && cellcheck["Disabled"] == true) {
                canproceed = false;
            }
            if (canproceed) {
                cellcheck["Disabled"] = false;
                cellcheck["Index"] = index;
                if (offset == 1 && preoffset == 0 && isScrollingFast) {
                    notificationDecision(true, index: index)
                } else if (offset == 2 && preoffset == 0 && isScrollingFast) {
                    notificationDecision(false, index: index)
                }
            }
        }
        preoffset = offset
    }
    func notificationDecision(accepted: Bool, index: NSIndexPath) {
        var animation: UITableViewRowAnimation;
        animation = UITableViewRowAnimation.Fade;
        if Reachability.isConnectedToNetwork() {
            let procnotif = notificationlist[index.row];
            if (procnotif.notificationtype == 1) {
                if let text = procnotif.notifdata {
                    let pos = text.rangeOfString(":", options: .BackwardsSearch)?.startIndex
                    var groupidpost = text.substringFromIndex(pos!)
                    groupidpost = String(groupidpost.characters.dropFirst());
                    var params = Dictionary<String,AnyObject>();
                    if (accepted) {
                        params["accepted"] = 1.description;
                    } else {
                        params["accepted"] = 0.description;
                    }
                    params["groupid"] = groupidpost;
                    Reachability.postToServer("group_decision.php", postdata: params, customselector: "Refresh");
                }
            }
            notificationlist.removeAtIndex(index.row);
            Globals.unreadnotificationcount = Globals.unreadnotificationcount - 1;
            pagenumber = 0;
            notificationtable.beginUpdates();
            if (notificationtable.numberOfRowsInSection(index.section) == 1) {
                //Delete section
                notificationtable.deleteSections(NSIndexSet(index: index.section), withRowAnimation: animation);
            } else {
                //Delete row
                notificationtable.deleteRowsAtIndexPaths([index], withRowAnimation: animation)
            }
            notificationtable.endUpdates();
        } else {
            RKDropdownAlert.title("Offline!", message: "You are currently not connected to the internet! :(");
        }
    }
    func swipeableTableViewCell(cell: SWTableViewCell!, scrollingToState state: SWCellState) {
        if (state.rawValue == 0) {
            cellcheck["Disabled"] = true;
            cellcheck["Index"] = notificationtable.indexPathForCell(cell!);
        } else {
            cellcheck["Disabled"] = false;
            cellcheck["Index"] = notificationtable.indexPathForCell(cell!);
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
        let cellfind:NSIndexPath? = notificationtable.indexPathForCell(cell);
        if let nonnilindex = cellfind
        {
            notificationDecision(true, index: nonnilindex)
        }
    }
    func swipeableTableViewCell(cell: SWTableViewCell!, didTriggerRightUtilityButtonWithIndex index: Int) {
        let cellfind:NSIndexPath? = notificationtable.indexPathForCell(cell);
        if let nonnilindex = cellfind
        {
            notificationDecision(false, index: nonnilindex)
        }
    }
}
