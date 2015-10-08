//
//  LocalStorageClasses.swift
//  Eventory
//
//  Created by Imran Ahmed on 08/10/2015.
//  Copyright © 2015 Imran Ahmed. All rights reserved.
//

import Foundation
class GroupData {
    var groupid:String;
    var image: UIImage;
    var descriptiontext: String;
    init (groupid:String, image:UIImage, description:String) {
        self.groupid = groupid;
        self.image = image;
        self.descriptiontext = description;
    }
    class func generateentry(inout list:[GroupData], input:Group) {
        var descriptiontext = "";
        if (input.memberstring == nil) {
            descriptiontext = "No Members!";
        } else {
            descriptiontext = Group.getMemberString(input.memberstring!);
        }
        self.addentry(&list, GroupData(groupid: input.groupid!, image: Group.generateGroupImage(input.memberstring), description: descriptiontext), replace: false);
    }
    class func addentry(inout list:[GroupData], _ input:GroupData, replace:Bool) {
        let replacement = list.filter({return $0.groupid == input.groupid});
        if (replacement.count > 0) {
            if (replace) {
                list[list.indexOf({return $0.groupid == input.groupid})!] = input;
            }
        } else {
            list.append(input);
        }
    }
    class func updateimage(inout list:[GroupData], inout _ groupid:String, inout _ imageupdate: UIImage) {
        let index = list.indexOf({return $0.groupid == groupid});
        list[index!].image = imageupdate;
    }
    class func updatemember(inout list:[GroupData], inout _ groupid:String, inout _ description: String) {
        let index = list.indexOf({return $0.groupid == groupid});
        list[index!].descriptiontext = description;
    }
    class func getGroupData(inout list:[GroupData], id: String) -> GroupData! {
        let check = list.filter({return $0.groupid == id});
        if check.count > 0 {
            return check[0];
        } else {
            return GroupData(groupid: "0", image: UIImage(named: "unknownprofile.png")!, description: "Generating Details");
        }
    }
}
