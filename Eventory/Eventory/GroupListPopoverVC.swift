//
//  GroupListPopoverVC.swift
//  Eventory
//
//  Created by Imran Ahmed on 24/07/2015.
//  Copyright (c) 2015 Imran Ahmed. All rights reserved.
//

import UIKit

class GroupListPopoverVC: UIViewController {
    var currentgroup:Group?;
    var memberlist:[Profile]! = [];
    override func viewDidLoad() {
        super.viewDidLoad()
        memberlist = Group.returnSavedFriends(currentgroup?.memberstring);
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "updateMemberList:", name: "Eventory_Group_List_Updated", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "updatePicture:", name: "Eventory_Group_Picture_Updated", object: nil)
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func updateMemberList(notification:NSNotification) {
        let currentinsert = notification.userInfo!["Friends"] as! [Profile]!;
        for (var i = 0; i<currentinsert.count; i++){
            Profile.downloadUnknownPictureAsync(currentinsert[i]);
        }
        memberlist.extend(currentinsert);
        //Update Table
    }
    
    func updatePicture(notification: NSNotification) {
        let id = notification.userInfo!["ID"] as! String;
        let data = notification.userInfo!["Data"] as! NSData;
        for (var i = 0; i < memberlist.count; i++) {
            if (memberlist[i].profid == id) {
                memberlist[i].imagedata = data;
                //Update Table
                break
            }
        }
    }
}
