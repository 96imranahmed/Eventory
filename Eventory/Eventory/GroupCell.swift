//
//  GroupCell.swift
//  Eventory
//
//  Created by Imran Ahmed on 18/07/2015.
//  Copyright (c) 2015 Imran Ahmed. All rights reserved.
//

import UIKit

class GroupCell: SWTableViewCell {
    @IBOutlet weak var memberlabel: UILabel!
    @IBOutlet weak var adminlabel: UILabel!
    @IBOutlet weak var groupimage: UIImageView!
    @IBOutlet weak var grouptextfield: UITextField!
    var memberlist:String!
    override func awakeFromNib() {
        super.awakeFromNib()
        groupimage.layer.masksToBounds = true;
        groupimage.layer.cornerRadius = 25;
        adminlabel.textColor = Schemes.returnColor("Nephritis", alpha: 1.0);
    }
    
    
}
