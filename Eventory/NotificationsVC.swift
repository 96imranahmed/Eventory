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
    var activityIndicator = UIActivityIndicatorView();
    var preoffset = 0;
    var lastOffset: CGPoint = CGPointMake(0, 0);
    var lastOffsetCapture: NSTimeInterval = 0.0;
    var isScrollingFast: Bool = false;
    var notificationlist:[Notification] = [];
    var cellcheck = ["Disabled" : false, "Index" : NSIndexPath(forRow: 0, inSection: 0)]
    var pagenumber = 0;
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
            activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.White)
            activityIndicator.frame = CGRect(x: 0, y: 0, width: 50, height: 50)
            activityIndicator.center = notificationtable.center;
            activityIndicator.startAnimating()
            notificationtable.addSubview(activityIndicator)
        } else {
            RKDropdownAlert.title("Offline!", message: "You are currently not connected to the internet! :(");
        }
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
    //MARK: Update/Refresh functions
    func refreshnotifications(notification: NSNotification) {
        if (Globals.notifications.count>0) {
            notificationlist = Globals.notifications;
            notificationlist.sort({($0.notificationtype! < $1.notificationtype)});
            dispatch_async(dispatch_get_main_queue()){
                UIView.transitionWithView(self.notificationtable, duration:0.1, options: UIViewAnimationOptions.TransitionCrossDissolve,
                    animations: {
                        self.notificationtable.reloadData();
                        if self.activityIndicator.isAnimating() {
                        self.activityIndicator.stopAnimating();
                        }
                    },
                    completion: nil)
            }
        }
    }
    func groupdownload(notification: NSNotification) {
        let currentgroup = notification.userInfo!["Group"] as! Group!;
        let popoverVC = storyboard?.instantiateViewControllerWithIdentifier("PopoverGroupList") as! GroupListPopoverVC!
        popoverVC.currentgroup = currentgroup;
        var members:[String] = (currentgroup.memberstring?.componentsSeparatedByString(";"))!;
        var invited:[String] = (currentgroup.invitedstring?.componentsSeparatedByString(";"))!;
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
    func autorefresh(notification: NSNotification) {
        if (Reachability.isConnectedToNetwork()) {
            Notification.getNotifications(Constants.notificationloadlimit, page: 0);
        }
    }
    func refresh(refreshControl: UIRefreshControl) {
        if (Reachability.isConnectedToNetwork()) {
            Notification.getNotifications(Constants.notificationloadlimit, page: 0);
        } else {
            RKDropdownAlert.title("Offline!", message: "You are currently not connected to the internet! :(");
        }
        refreshControl.endRefreshing();
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
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let currentnotification = notificationlist[indexPath.row];
        var cell = tableView.dequeueReusableCellWithIdentifier("DecisionCell") as! NotificationDecisionCell;
        cell.notification = currentnotification;
        cell.picture.image = Profile.getPicturefromCoreData(currentnotification.sourceID!);
        cell.unseen = true;
        cell.title.text = currentnotification.text;
        cell.setDecisionLayout(currentnotification.notificationtype)
        cell.delegate = self;
        return cell;
    }
    //MARK: SWTableViewCell Methods
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
        let cell = notificationtable.cellForRowAtIndexPath(index) as! NotificationDecisionCell;
        var animation: UITableViewRowAnimation;
        animation = UITableViewRowAnimation.Fade;
        let procnotif = notificationlist[index.row];
            if (procnotif.notificationtype == 1) {
                if let text = procnotif.notifdata {
                    let pos = text.rangeOfString(":", options: .BackwardsSearch)?.startIndex
                    var groupidpost = text.substringFromIndex(pos!)
                    groupidpost = dropFirst(groupidpost);
                    var params = Dictionary<String,AnyObject>();
                    params["accepted"] = accepted;
                    params["groupid"] = groupidpost;
                    Reachability.postToServer("group_decision.php", postdata: params, customselector: "Refresh");
                }
               
        }
        
        notificationlist.removeAtIndex(index.row);
        if (notificationtable.numberOfRowsInSection(index.section) == 1) {
            //Delete section
            notificationtable.deleteSections(NSIndexSet(index: index.section), withRowAnimation: animation);
        } else {
            //Delete row
            notificationtable.deleteRowsAtIndexPaths([index], withRowAnimation: animation)
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
