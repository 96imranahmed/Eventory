//
//  NotificationStandardCell.swift
//  Eventory
//
//  Created by Imran Ahmed on 24/09/2015.
//  Copyright © 2015 Imran Ahmed. All rights reserved.
//

import UIKit

class NotificationStandardCell: SWTableViewCell {
    var notification: Notification = Notification(type: 0, sourceID: nil, decided: nil, text: "", read: false, notifdata: nil, date: NSDate(timeIntervalSinceNow: 0));
    var unseen: Bool = false;
    @IBOutlet weak var title: UITextView!
    @IBOutlet weak var picture: UIImageView!
    @IBOutlet weak var newimage: UIImageView!
    override func awakeFromNib() {
        super.awakeFromNib()
        picture.image = UIImage(named: "unknownprofile.png");
        picture.layer.masksToBounds = true;
        picture.layer.cornerRadius = 25;
        // Initialization code
    }
    
    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        // Configure the view for the selected state
    }
    func setDecisionLayout(notificationtype: Int?) {
        if unseen {
            newimage.hidden = false;
        } else {
            newimage.hidden = true;
        }
        let right:NSMutableArray = NSMutableArray();
        right.sw_addUtilityButtonWithColor(Schemes.returnColor("Alizarin", alpha: 1.0), title: "< Dismiss");
        self.setRightUtilityButtons(right as [AnyObject], withButtonWidth: 100);
    }
}
