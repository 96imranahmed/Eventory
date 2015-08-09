//
//  Notification.swift
//  Eventory
//
//  Created by Imran Ahmed on 05/08/2015.
//  Copyright (c) 2015 Imran Ahmed. All rights reserved.
//

import Foundation

class Notification {
    var notificationtype: Int?;
    var sourceID: String?;
    var destinationID: String?;
    var decided: Bool?
    var text: String?
    var candecide: Bool;
    var data: String?
    
    init (type: Int?, sourceID: String?, destinationID: String?, decided: Bool?, text: String?, data: String?) {
        self.notificationtype = type;
        self.sourceID = sourceID
        self.destinationID = destinationID;
        self.decided = decided
        self.text = text;
        self.data = data;
        if (type == 1) {
            self.candecide = true;
        } else {
            self.candecide = false;
        }
    }
    
    func performJump() {
        if (self.notificationtype == 1) {
            if let decision = self.decided {
                //Group Decision Notification
            }
        }
    }
}