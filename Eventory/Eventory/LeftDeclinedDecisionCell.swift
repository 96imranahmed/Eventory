//
//  LeftDeclinedDecisionCell.swift
//  Eventory
//
//  Created by Imran Ahmed on 18/09/2015.
//  Copyright (c) 2015 Imran Ahmed. All rights reserved.
//

import UIKit

class LeftDeclinedDecisionCell: SWTableViewCell {
    var group: Group = Group(name: nil, groupid: nil, memberstring: nil, invitedstring: nil, isadmin: false, save: false);
    var type: Int = 0;
    @IBOutlet weak var detail: UILabel!
    @IBOutlet weak var title: UILabel!
    @IBOutlet weak var picture: UIImageView!
    @IBOutlet weak var yeslabel: UILabel!
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
        var left:NSMutableArray = NSMutableArray();
        var imagesize:CGSize = CGSizeMake(20,20);
        if type == 1 {
            left.sw_addUtilityButtonWithColor(Schemes.returnColor("Nephritis", alpha: 1.0), title: "Re-Join >");
            yeslabel.text = "Re-Join >";
            yeslabel.textColor = Schemes.returnColor("Nephritis", alpha: 1.0)
        } else if type == 2 {
            left.sw_addUtilityButtonWithColor(Schemes.returnColor("Nephritis", alpha: 1.0), title: "Accept >");
            yeslabel.text = "Accept >";
            yeslabel.textColor = Schemes.returnColor("Nephritis", alpha: 1.0);
        }
        self.setLeftUtilityButtons(left as [AnyObject], withButtonWidth: 100);
    }
}
