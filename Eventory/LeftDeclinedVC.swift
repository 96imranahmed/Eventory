//
//  LeftDeclinedVC.swift
//  Eventory
//
//  Created by Imran Ahmed on 16/09/2015.
//  Copyright (c) 2015 Imran Ahmed. All rights reserved.
//

import UIKit
var leftGroups:[Group] = [];
var declinedGroups:[Group] = [];
class LeftDeclinedVC: UIViewController {//, UITableViewDelegate, UITableViewDataSource {

    override func viewDidLoad() {
        super.viewDidLoad()
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
    
    func refresh() {
        var params = Dictionary<String,AnyObject>();
        params["type"] = "1";
        Reachability.postToServer("group_get.php", postdata: params, customselector: "DeclinedGroupLoad");
        params["type"] = "2";
        Reachability.postToServer("group_get.php", postdata: params, customselector: "LeftGroupLoad");
    }
    
    func groupupdated(notification:NSNotification) {
        let type = notification.userInfo!["Type"] as! Int;
        let data = notification.userInfo!["Groups"] as! [Group];
        if (type == 1) {
            declinedGroups = data;
        } else if (type == 2) {
            leftGroups = data;
        }
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
