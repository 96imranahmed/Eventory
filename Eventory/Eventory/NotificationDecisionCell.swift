//
//  NotificationDecisionCell.swift
//  Eventory
//
//  Created by Imran Ahmed on 31/07/2015.
//  Copyright (c) 2015 Imran Ahmed. All rights reserved.
//

import UIKit

class NotificationDecisionCell: SWTableViewCell {
    var notification: Notification = Notification(type: 0, sourceID: nil, decided: nil, text: "", read: false, notifdata: nil, date: NSDate(timeIntervalSinceNow: 0));
    var unseen: Bool = false;
    @IBOutlet weak var title: MarqueeLabel!
    @IBOutlet weak var picture: UIImageView!
    @IBOutlet weak var yeslabel: UILabel!
    @IBOutlet weak var nolabel: UILabel!
    @IBOutlet weak var newimage: UIImageView!
    override func awakeFromNib() {
        super.awakeFromNib()
        picture.image = UIImage(named: "unknownprofile.png");
        picture.layer.masksToBounds = true;
        picture.layer.cornerRadius = 25;
        title.scrollDuration = 2;
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
        if let check = notificationtype {
            let right:NSMutableArray = NSMutableArray();
            let left:NSMutableArray = NSMutableArray();
            if check == 1 {
                left.sw_addUtilityButtonWithColor(Schemes.returnColor("Nephritis", alpha: 1.0), title: "Accept >");
                right.sw_addUtilityButtonWithColor(Schemes.returnColor("Alizarin", alpha: 1.0), title: "< Decline");
                yeslabel.text = "Accept >";
                yeslabel.textColor = Schemes.returnColor("Nephritis", alpha: 1.0)
                nolabel.text = "< Decline";
                nolabel.textColor = Schemes.returnColor("Alizarin", alpha: 1.0);
            } else if check == 0 {
                left.sw_addUtilityButtonWithColor(Schemes.returnColor("Nephritis", alpha: 1.0), title: "Follow >");
                right.sw_addUtilityButtonWithColor(Schemes.returnColor("Carrot", alpha: 1.0), title: "< Dismiss");
                yeslabel.text = "Follow >";
                yeslabel.textColor = Schemes.returnColor("Nephritis", alpha: 1.0);
                nolabel.text = "< Dismiss";
                nolabel.textColor = Schemes.returnColor("Carrot", alpha: 1.0);
            }
            self.setLeftUtilityButtons(left as [AnyObject], withButtonWidth: 100);
            self.setRightUtilityButtons(right as [AnyObject], withButtonWidth: 100);
        } else {
            yeslabel.text = "";
            nolabel.text = "";
        }
    }
}
