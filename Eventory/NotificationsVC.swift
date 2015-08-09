//
//  NotificationsVC.swift
//  Eventory
//
//  Created by Imran Ahmed on 30/07/2015.
//  Copyright (c) 2015 Imran Ahmed. All rights reserved.
//

import UIKit

class NotificationsVC: UIViewController, UITableViewDelegate, UITableViewDataSource, UIScrollViewDelegate, SWTableViewCellDelegate{
    @IBOutlet weak var notificationtable: UITableView!
    //Cell swipe
    var preoffset = 0;
    var lastOffset: CGPoint = CGPointMake(0, 0);
    var lastOffsetCapture: NSTimeInterval = 0.0;
    var isScrollingFast: Bool = false;
    var notificationlist:[Notification] = [];
    var cellcheck = ["Disabled" : false, "Index" : NSIndexPath(forRow: 0, inSection: 0)]
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.title = "Notifications"
        notificationtable.dataSource = self;
        notificationtable.delegate = self;
        for (var i = 0; i < 6; i++) {
            notificationlist.append(Notification(type: 1, sourceID: "Me", destinationID: "To", decided: nil, text: i.description, data: nil));
        }
        notificationlist.sort({($0.notificationtype! < $1.notificationtype)});
        // Do any additional setup after loading the view.
    }
    override func viewDidAppear(animated: Bool) {
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
